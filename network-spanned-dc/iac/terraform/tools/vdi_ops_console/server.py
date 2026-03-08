#!/usr/bin/env python3
from __future__ import annotations

import argparse
import base64
import json
import os
import re
import subprocess
import sys
import time
from datetime import datetime, timezone
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

APP_ROOT = Path(__file__).resolve().parent
STATIC_ROOT = APP_ROOT / "static"
DEFAULT_TERRAFORM_DIR = APP_ROOT.parents[1]

SITES = {
    "site-a": {
        "label": "Site A",
        "cloud": "aws",
        "region": "us-east-1",
        "context": "ddc-site-a",
        "guacamole_url": os.getenv("VDI_SITE_A_URL", "https://app-a.slothkko.com/guacamole/"),
    },
    "site-b": {
        "label": "Site B",
        "cloud": "aws",
        "region": "us-west-2",
        "context": "ddc-site-b",
        "guacamole_url": os.getenv("VDI_SITE_B_URL", "https://app-b.slothkko.com/guacamole/"),
    },
    "site-c": {"label": "Site C", "cloud": "gcp", "region": "us-east4", "context": None, "guacamole_url": None},
    "site-d": {"label": "Site D", "cloud": "gcp", "region": "us-west1", "context": None, "guacamole_url": None},
}


def _find_tool(name: str) -> str | None:
    try:
        out = subprocess.run(["where", name], capture_output=True, text=True, timeout=5, check=False)
    except OSError:
        return None
    if out.returncode != 0:
        return None
    return next((line.strip() for line in out.stdout.splitlines() if line.strip()), None)


class Ops:
    def __init__(self, terraform_dir: Path, timeout: int) -> None:
        self.terraform_dir = terraform_dir
        self.timeout = timeout
        self.kubectl = _find_tool("kubectl")
        self.terraform = _find_tool("terraform")
        self.gcloud = _find_tool("gcloud")
        self.contexts = self._contexts()

    def _run(self, cmd: list[str], timeout: int | None = None) -> dict:
        started = time.time()
        t = timeout or self.timeout
        try:
            p = subprocess.run(cmd, capture_output=True, text=True, timeout=t, check=False)
        except subprocess.TimeoutExpired as exc:
            return {"ok": False, "stdout": (exc.stdout or "").strip(), "stderr": f"timeout after {t}s", "exit": -1, "ms": int((time.time() - started) * 1000)}
        except OSError as exc:
            return {"ok": False, "stdout": "", "stderr": str(exc), "exit": -1, "ms": int((time.time() - started) * 1000)}
        return {"ok": p.returncode == 0, "stdout": p.stdout.strip(), "stderr": p.stderr.strip(), "exit": p.returncode, "ms": int((time.time() - started) * 1000)}

    def _contexts(self) -> set[str]:
        if not self.kubectl:
            return set()
        r = self._run([self.kubectl, "config", "get-contexts", "-o", "name"], timeout=8)
        if not r["ok"]:
            return set()
        return {line.strip() for line in r["stdout"].splitlines() if line.strip()}

    def _k(self, context: str, args: list[str], timeout: int | None = None) -> dict:
        if not self.kubectl:
            return {"ok": False, "stdout": "", "stderr": "kubectl not found", "exit": -1, "ms": 0}
        return self._run([self.kubectl, "--context", context] + args, timeout=timeout)

    def _tf_outputs(self) -> tuple[dict, str]:
        if not self.terraform:
            return {}, "terraform not found"
        if not self.terraform_dir.exists():
            return {}, f"terraform dir missing: {self.terraform_dir}"
        r = self._run([self.terraform, f"-chdir={self.terraform_dir}", "output", "-json"], timeout=20)
        if not r["ok"]:
            return {}, r["stderr"] or r["stdout"] or "terraform output failed"
        try:
            raw = json.loads(r["stdout"] or "{}")
        except json.JSONDecodeError as exc:
            return {}, f"terraform JSON parse failed: {exc}"
        out = {}
        for k, v in raw.items():
            out[k] = v.get("value") if isinstance(v, dict) and "value" in v else v
        return out, ""

    def _decode_b64(self, value: str) -> str:
        try:
            return base64.b64decode(value).decode("utf-8")
        except Exception:
            return ""

    def _db_identity(self, context: str) -> tuple[str, str]:
        fallback_user = os.getenv("VDI_GUAC_DB_USER", "guacamole_user")
        fallback_db = os.getenv("VDI_GUAC_DB_NAME", "guacamole_db")
        s = self._k(context, ["-n", "vdi", "get", "secret", "guacamole-db-auth", "-o", "json"], timeout=8)
        if not s["ok"]:
            return fallback_user, fallback_db
        try:
            blob = json.loads(s["stdout"])
        except json.JSONDecodeError:
            return fallback_user, fallback_db
        data = blob.get("data", {})
        return self._decode_b64(data.get("username", "")) or fallback_user, self._decode_b64(data.get("database", "")) or fallback_db

    def _session_count(self, context: str) -> tuple[int | None, str]:
        user, db = self._db_identity(context)
        sql = "SELECT count(*) FROM guacamole_connection_history WHERE end_date IS NULL;"
        r = self._k(context, ["-n", "vdi", "exec", "deployment/guacamole-db", "--", "psql", "-U", user, "-d", db, "-At", "-c", sql], timeout=12)
        if not r["ok"]:
            return None, r["stderr"] or r["stdout"] or "session query failed"
        line = (r["stdout"] or "").strip().splitlines()
        if not line:
            return None, "no output"
        try:
            return int(line[-1].strip()), ""
        except ValueError:
            return None, f"unexpected session output: {line[-1]}"

    def _site_health(self, site_key: str) -> dict:
        meta = SITES[site_key]
        status = {
            "site": site_key,
            "label": meta["label"],
            "cloud": meta["cloud"],
            "region": meta["region"],
            "context": meta["context"],
            "guacamole_url": meta["guacamole_url"],
            "overall_ok": False,
            "active_sessions": None,
            "errors": [],
            "lights": {
                "cluster_reachable": None,
                "vdi_nodes_ready": None,
                "guacamole_db_ready": None,
                "guacamole_ready": None,
                "desktop_ready": None,
            },
            "details": {},
        }

        context = meta["context"]
        if not context:
            status["errors"].append("no kubernetes context configured")
            return status
        if context not in self.contexts:
            status["errors"].append(f"context not found: {context}")
            return status

        ns = self._k(context, ["get", "namespace", "vdi", "-o", "json"], timeout=8)
        if not ns["ok"]:
            status["lights"]["cluster_reachable"] = False
            status["errors"].append(ns["stderr"] or ns["stdout"] or "namespace vdi not reachable")
            return status
        status["lights"]["cluster_reachable"] = True

        nodes = self._k(context, ["get", "nodes", "-l", "workload=vdi", "-o", "json"], timeout=12)
        if nodes["ok"]:
            try:
                items = json.loads(nodes["stdout"]).get("items", [])
                ready = 0
                for n in items:
                    conds = n.get("status", {}).get("conditions", [])
                    if any(c.get("type") == "Ready" and c.get("status") == "True" for c in conds):
                        ready += 1
                status["details"]["vdi_node_count"] = len(items)
                status["details"]["vdi_node_ready_count"] = ready
                status["lights"]["vdi_nodes_ready"] = len(items) > 0 and ready == len(items)
                if len(items) == 0:
                    status["errors"].append("no workload=vdi nodes")
            except Exception:
                status["lights"]["vdi_nodes_ready"] = False
                status["errors"].append("failed to parse node status")
        else:
            status["lights"]["vdi_nodes_ready"] = False
            status["errors"].append(nodes["stderr"] or nodes["stdout"] or "node check failed")

        for dep, key in (("guacamole-db", "guacamole_db_ready"), ("guacamole", "guacamole_ready"), ("vdi-desktop", "desktop_ready")):
            d = self._k(context, ["-n", "vdi", "get", "deployment", dep, "-o", "json"], timeout=12)
            if not d["ok"]:
                status["lights"][key] = False
                status["errors"].append(f"{dep}: {d['stderr'] or d['stdout'] or 'check failed'}")
                continue
            try:
                blob = json.loads(d["stdout"])
                desired = int(blob.get("spec", {}).get("replicas", 0) or 0)
                ready = int(blob.get("status", {}).get("readyReplicas", 0) or 0)
                avail = int(blob.get("status", {}).get("availableReplicas", 0) or 0)
                status["lights"][key] = desired > 0 and ready >= desired and avail >= desired
                status["details"][f"{dep}_desired"] = desired
                status["details"][f"{dep}_ready"] = ready
            except Exception:
                status["lights"][key] = False
                status["errors"].append(f"{dep}: parse failed")

        count, err = self._session_count(context)
        status["active_sessions"] = count
        if err:
            status["details"]["session_detail"] = err
        else:
            status["details"]["session_detail"] = f"active_sessions={count}"

        status["overall_ok"] = all(v is True for v in status["lights"].values() if v is not None)
        return status

    def _gcp_worker_light(self, key: str, outputs: dict) -> dict:
        base = {
            "site": key,
            "label": SITES[key]["label"],
            "cloud": "gcp",
            "region": SITES[key]["region"],
            "context": None,
            "guacamole_url": None,
            "overall_ok": False,
            "active_sessions": None,
            "errors": [],
            "details": {},
            "lights": {"cluster_reachable": None, "vdi_nodes_ready": None, "guacamole_db_ready": None, "guacamole_ready": None, "desktop_ready": None},
        }
        gcp = ((outputs.get("phase4_vdi_reference_stacks") or {}).get("gcp") or {})
        worker = ((gcp.get(key.replace("-", "_")) or {}).get("worker") or {})
        if not worker:
            base["details"]["worker_detail"] = "worker not enabled"
            return base
        if not self.gcloud:
            base["errors"].append("gcloud not found in PATH")
            base["details"]["worker_detail"] = "gcloud missing"
            base["lights"]["cluster_reachable"] = False
            base["lights"]["vdi_nodes_ready"] = False
            return base

        self_link = ((outputs.get("gcp_site_c_network") or {}).get("network_self_link") or "")
        m = re.search(r"/projects/([^/]+)/", self_link)
        project = m.group(1) if m else ""
        if not project:
            base["errors"].append("GCP project id unresolved")
            base["lights"]["cluster_reachable"] = False
            base["lights"]["vdi_nodes_ready"] = False
            return base

        r = self._run([self.gcloud, "container", "node-pools", "describe", worker.get("node_pool", ""), "--cluster", worker.get("cluster_name", ""), "--location", worker.get("location", ""), "--project", project, "--format", "value(status)"], timeout=20)
        base["lights"]["cluster_reachable"] = r["ok"]
        if not r["ok"]:
            base["errors"].append(r["stderr"] or r["stdout"] or "gcloud node-pool describe failed")
            base["lights"]["vdi_nodes_ready"] = False
            return base
        status = (r["stdout"] or "").strip().upper()
        base["details"]["worker_detail"] = f"nodepool status={status or 'UNKNOWN'}"
        base["lights"]["vdi_nodes_ready"] = status == "RUNNING"
        base["overall_ok"] = base["lights"]["vdi_nodes_ready"] is True
        return base

    def health(self) -> dict:
        outputs, tf_error = self._tf_outputs()
        sites = {k: self._site_health(k) for k in ("site-a", "site-b")}
        sites["site-c"] = self._gcp_worker_light("site-c", outputs)
        sites["site-d"] = self._gcp_worker_light("site-d", outputs)

        known = [v for s in sites.values() for v in s["lights"].values() if v is not None]
        state = "green" if known and all(known) else ("red" if any(v is False for v in known) else "amber")
        return {
            "generated_at": datetime.now(tz=timezone.utc).isoformat(),
            "overall": {"state": state, "ok": state == "green", "known_light_count": len(known), "green_light_count": sum(1 for x in known if x)},
            "terraform": {
                "ok": tf_error == "",
                "error": tf_error,
                "deliverables": outputs.get("phase4_deliverable_flags", {}),
                "cloudflare_records": outputs.get("phase4_cloudflare_edge_records", {}),
            },
            "sites": sites,
            "topology": self.topology(sites, outputs),
        }

    def topology(self, sites: dict, outputs: dict) -> dict:
        nodes = []
        for k in ("site-a", "site-b", "site-c", "site-d"):
            nodes.append({"id": k, "label": sites[k]["label"], "state": "green" if sites[k]["overall_ok"] else "red"})
        cf = outputs.get("phase4_cloudflare_edge_records") or {}
        nodes.append({"id": "cloudflare", "label": "Cloudflare Edge", "state": "green" if (cf.get("site_a") or cf.get("site_b")) else "amber"})

        links = []
        inter = outputs.get("phase2_intercloud_links") or {}
        for key, a, b, label in (("ac", "site-a", "site-c", "A-C VPN/BGP"), ("ad", "site-a", "site-d", "A-D VPN/BGP"), ("bc", "site-b", "site-c", "B-C VPN/BGP"), ("bd", "site-b", "site-d", "B-D VPN/BGP")):
            state = "green" if inter.get(key) else "red"
            links.append({"id": key, "from": a, "to": b, "label": label, "state": state})
        links.append({"id": "cf-site-a", "from": "cloudflare", "to": "site-a", "label": "DNS A", "state": "green" if cf.get("site_a") else "amber"})
        links.append({"id": "cf-site-b", "from": "cloudflare", "to": "site-b", "label": "DNS B", "state": "green" if cf.get("site_b") else "amber"})
        return {"nodes": nodes, "links": links}

    def restart(self, site: str, target: str) -> dict:
        if site not in ("site-a", "site-b"):
            return {"ok": False, "message": f"invalid site: {site}"}
        ctx = SITES[site]["context"]
        if not ctx or ctx not in self.contexts:
            return {"ok": False, "message": f"context unavailable: {ctx}"}
        dep = {"desktop": "vdi-desktop", "guacamole": "guacamole", "db": "guacamole-db"}.get(target)
        if not dep:
            return {"ok": False, "message": f"invalid target: {target}"}
        rr = self._k(ctx, ["-n", "vdi", "rollout", "restart", f"deployment/{dep}"], timeout=20)
        if not rr["ok"]:
            return {"ok": False, "message": rr["stderr"] or rr["stdout"] or "restart failed"}
        rs = self._k(ctx, ["-n", "vdi", "rollout", "status", f"deployment/{dep}", "--timeout", "90s"], timeout=95)
        return {"ok": rs["ok"], "message": rs["stdout"] or rs["stderr"] or "restart submitted", "site": site, "target": target}

    def reset_desktop(self, site: str) -> dict:
        if site not in ("site-a", "site-b"):
            return {"ok": False, "message": f"invalid site: {site}"}
        ctx = SITES[site]["context"]
        if not ctx or ctx not in self.contexts:
            return {"ok": False, "message": f"context unavailable: {ctx}"}
        r = self._k(ctx, ["-n", "vdi", "delete", "pod", "-l", "app.kubernetes.io/name=vdi-desktop", "--wait=false"], timeout=20)
        return {"ok": r["ok"], "message": r["stdout"] or r["stderr"] or "", "site": site}

    def sessions(self, site: str) -> dict:
        if site not in ("site-a", "site-b"):
            return {"ok": False, "message": f"invalid site: {site}", "rows": []}
        ctx = SITES[site]["context"]
        if not ctx or ctx not in self.contexts:
            return {"ok": False, "message": f"context unavailable: {ctx}", "rows": []}
        user, db = self._db_identity(ctx)
        sql = (
            "SELECT e.name, COALESCE(c.connection_name, sp.sharing_profile_name, 'unknown'), "
            "to_char(h.start_date AT TIME ZONE 'UTC', 'YYYY-MM-DD HH24:MI:SS') "
            "FROM guacamole_connection_history h "
            "JOIN guacamole_user u ON h.user_id = u.user_id "
            "JOIN guacamole_entity e ON u.entity_id = e.entity_id "
            "LEFT JOIN guacamole_connection c ON h.connection_id = c.connection_id "
            "LEFT JOIN guacamole_sharing_profile sp ON h.sharing_profile_id = sp.sharing_profile_id "
            "WHERE h.end_date IS NULL ORDER BY h.start_date DESC LIMIT 50;"
        )
        r = self._k(ctx, ["-n", "vdi", "exec", "deployment/guacamole-db", "--", "psql", "-U", user, "-d", db, "-At", "-F", "\t", "-c", sql], timeout=20)
        if not r["ok"]:
            return {"ok": False, "message": r["stderr"] or r["stdout"] or "session query failed", "rows": []}
        rows = []
        for line in r["stdout"].splitlines():
            if not line.strip():
                continue
            p = (line.split("\t") + ["", "", ""])[:3]
            rows.append({"username": p[0], "connection": p[1], "start_utc": p[2]})
        return {"ok": True, "message": f"{len(rows)} active session(s)", "rows": rows}

    def processes(self, site: str) -> dict:
        if site not in ("site-a", "site-b"):
            return {"ok": False, "message": f"invalid site: {site}", "output": ""}
        ctx = SITES[site]["context"]
        if not ctx or ctx not in self.contexts:
            return {"ok": False, "message": f"context unavailable: {ctx}", "output": ""}
        r = self._k(ctx, ["-n", "vdi", "exec", "deployment/vdi-desktop", "--", "sh", "-lc", "ps -eo pid,ppid,%cpu,%mem,stat,etime,comm,args --sort=-%cpu | head -n 40"], timeout=20)
        return {"ok": r["ok"], "message": (r["stderr"] if not r["ok"] else "process snapshot collected"), "output": r["stdout"] if r["ok"] else (r["stdout"] or r["stderr"])}


class OpsServer(ThreadingHTTPServer):
    def __init__(self, address, handler_cls, ops: Ops, auth_header: str):
        super().__init__(address, handler_cls)
        self.ops = ops
        self.auth_header = auth_header


class Handler(BaseHTTPRequestHandler):
    server_version = "VDI-Ops/1.0"

    def _auth(self) -> bool:
        if self.headers.get("Authorization", "") == self.server.auth_header:
            return True
        self.send_response(HTTPStatus.UNAUTHORIZED)
        self.send_header("WWW-Authenticate", 'Basic realm="VDI Ops Console"')
        self.end_headers()
        return False

    def _json(self, code: HTTPStatus, payload: dict):
        data = json.dumps(payload, indent=2).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def _text(self, code: HTTPStatus, body: str, ctype: str = "text/plain; charset=utf-8"):
        data = body.encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def _read_json(self) -> dict:
        n = int(self.headers.get("Content-Length", "0"))
        if n <= 0:
            return {}
        return json.loads(self.rfile.read(n).decode("utf-8"))

    def _static(self, name: str):
        path = (STATIC_ROOT / name).resolve()
        if not path.exists():
            self._text(HTTPStatus.NOT_FOUND, "not found")
            return
        ctype = "text/plain; charset=utf-8"
        if path.suffix == ".html":
            ctype = "text/html; charset=utf-8"
        elif path.suffix == ".css":
            ctype = "text/css; charset=utf-8"
        elif path.suffix == ".js":
            ctype = "application/javascript; charset=utf-8"
        self._text(HTTPStatus.OK, path.read_text(encoding="utf-8"), ctype)

    def do_GET(self):
        if not self._auth():
            return
        parsed = urlparse(self.path)
        if parsed.path in ("/", "/index.html"):
            self._static("index.html")
            return
        if parsed.path == "/styles.css":
            self._static("styles.css")
            return
        if parsed.path == "/app.js":
            self._static("app.js")
            return
        if parsed.path == "/api/health":
            self._json(HTTPStatus.OK, self.server.ops.health())
            return
        if parsed.path == "/api/admin/sessions":
            site = parse_qs(parsed.query).get("site", [""])[0]
            self._json(HTTPStatus.OK, self.server.ops.sessions(site))
            return
        if parsed.path == "/api/admin/processes":
            site = parse_qs(parsed.query).get("site", [""])[0]
            self._json(HTTPStatus.OK, self.server.ops.processes(site))
            return
        self._text(HTTPStatus.NOT_FOUND, "not found")

    def do_POST(self):
        if not self._auth():
            return
        try:
            body = self._read_json()
        except json.JSONDecodeError:
            self._json(HTTPStatus.BAD_REQUEST, {"ok": False, "message": "invalid JSON body"})
            return
        if self.path == "/api/admin/restart-workload":
            out = self.server.ops.restart(str(body.get("site", "")), str(body.get("target", "")))
            self._json(HTTPStatus.OK if out.get("ok") else HTTPStatus.BAD_REQUEST, out)
            return
        if self.path == "/api/admin/reset-desktop":
            out = self.server.ops.reset_desktop(str(body.get("site", "")))
            self._json(HTTPStatus.OK if out.get("ok") else HTTPStatus.BAD_REQUEST, out)
            return
        self._text(HTTPStatus.NOT_FOUND, "not found")

    def log_message(self, fmt: str, *args):
        ts = datetime.now(tz=timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        sys.stdout.write(f"[{ts}] {self.address_string()} {fmt % args}\n")


def _auth_header() -> str:
    user = os.getenv("VDI_ADMIN_USERNAME", "").strip()
    pwd = os.getenv("VDI_ADMIN_PASSWORD", "").strip()
    if not user or not pwd:
        raise RuntimeError("set VDI_ADMIN_USERNAME and VDI_ADMIN_PASSWORD before starting")
    return "Basic " + base64.b64encode(f"{user}:{pwd}".encode("utf-8")).decode("ascii")


def main() -> int:
    p = argparse.ArgumentParser(description="VDI Operations Console")
    p.add_argument("--host", default=os.getenv("VDI_OPS_HOST", "127.0.0.1"))
    p.add_argument("--port", type=int, default=int(os.getenv("VDI_OPS_PORT", "8099")))
    p.add_argument("--terraform-dir", default=os.getenv("VDI_TERRAFORM_DIR", str(DEFAULT_TERRAFORM_DIR)))
    p.add_argument("--command-timeout-seconds", type=int, default=int(os.getenv("VDI_OPS_COMMAND_TIMEOUT_SECONDS", "25")))
    args = p.parse_args()

    try:
        auth = _auth_header()
    except RuntimeError as exc:
        print(f"FATAL: {exc}", file=sys.stderr)
        return 2

    if not STATIC_ROOT.exists():
        print(f"FATAL: static root missing: {STATIC_ROOT}", file=sys.stderr)
        return 2

    ops = Ops(terraform_dir=Path(args.terraform_dir).expanduser().resolve(), timeout=args.command_timeout_seconds)
    srv = OpsServer((args.host, args.port), Handler, ops, auth)
    print(f"VDI Ops Console listening on http://{args.host}:{args.port}")
    print("Auth: HTTP Basic from VDI_ADMIN_USERNAME/VDI_ADMIN_PASSWORD")
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        srv.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
