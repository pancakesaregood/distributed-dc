const REFRESH_MS = 15000;
let latestHealth = null;

function lightClass(state) {
  if (state === true || state === "green") return "green";
  if (state === false || state === "red") return "red";
  return "amber";
}

function setText(id, text) {
  const el = document.getElementById(id);
  if (el) el.textContent = text;
}

function appendLog(message, ok = true) {
  const pane = document.getElementById("action-log");
  const stamp = new Date().toISOString();
  pane.textContent = `[${stamp}] ${ok ? "OK" : "ERR"} ${message}\n` + pane.textContent;
}

function renderSiteCards(health) {
  const grid = document.getElementById("site-grid");
  grid.innerHTML = "";
  for (const key of ["site-a", "site-b", "site-c", "site-d"]) {
    const site = health.sites[key];
    if (!site) continue;
    const card = document.createElement("article");
    card.className = "site-card";

    const lights = site.lights || {};
    const lightRows = [
      ["Cluster", lights.cluster_reachable],
      ["VDI Nodes", lights.vdi_nodes_ready],
      ["Guac DB", lights.guacamole_db_ready],
      ["Guacamole", lights.guacamole_ready],
      ["Desktop", lights.desktop_ready],
    ]
      .map(([label, value]) => `<span><i class="light ${lightClass(value)}"></i>${label}</span>`)
      .join("");

    const errors = (site.errors || []).slice(0, 2);
    const errText = errors.length > 0 ? errors.join(" | ") : "No alarms.";
    const sessions = site.active_sessions === null ? "n/a" : String(site.active_sessions);

    card.innerHTML = `
      <div class="site-head">
        <strong>${site.label}</strong>
        <i class="light ${lightClass(site.overall_ok)}"></i>
      </div>
      <div class="site-meta">${site.cloud.toUpperCase()} ${site.region} | active sessions: ${sessions}</div>
      <div class="lights">${lightRows}</div>
      <div class="site-errors">${errText}</div>
    `;
    grid.appendChild(card);
  }
}

function renderTopology(health) {
  const topo = health.topology || { nodes: [], links: [] };
  const nodeMap = {};
  for (const n of topo.nodes) nodeMap[n.id] = n;
  const linkMap = {};
  for (const l of topo.links) linkMap[l.id] = l;

  for (const id of ["site-a", "site-b", "site-c", "site-d", "cloudflare"]) {
    const nodeEl = document.getElementById(`node-${id}`);
    if (!nodeEl) continue;
    nodeEl.classList.remove("green", "amber", "red");
    nodeEl.classList.add(lightClass(nodeMap[id]?.state || "amber"));
  }
  for (const id of ["ac", "ad", "bc", "bd", "cf-site-a", "cf-site-b"]) {
    const linkEl = document.getElementById(`link-${id}`);
    if (!linkEl) continue;
    linkEl.classList.remove("green", "amber", "red");
    linkEl.classList.add(lightClass(linkMap[id]?.state || "amber"));
  }
}

function syncAssistLink() {
  const site = document.getElementById("site-select").value;
  const link = document.getElementById("assist-link");
  const target = latestHealth?.sites?.[site]?.guacamole_url || "#";
  link.href = target;
}

function renderOverall(health) {
  const state = health?.overall?.state || "amber";
  const light = document.getElementById("overall-light");
  light.classList.remove("green", "amber", "red");
  light.classList.add(lightClass(state));
  setText("overall-text", `Reactor state: ${state.toUpperCase()} | Green lights: ${health?.overall?.green_light_count ?? 0}/${health?.overall?.known_light_count ?? 0}`);
  setText("last-updated", `Last update: ${new Date(health.generated_at).toLocaleString()}`);
}

async function getJson(url, options = {}) {
  const res = await fetch(url, { ...options, headers: { "Content-Type": "application/json", ...(options.headers || {}) } });
  const data = await res.json();
  if (!res.ok) throw new Error(data.message || `HTTP ${res.status}`);
  return data;
}

async function refresh() {
  try {
    const health = await getJson("/api/health");
    latestHealth = health;
    renderOverall(health);
    renderSiteCards(health);
    renderTopology(health);
    syncAssistLink();
  } catch (err) {
    appendLog(`telemetry refresh failed: ${err.message}`, false);
  }
}

function selectedSite() {
  return document.getElementById("site-select").value;
}

async function restart(target) {
  const site = selectedSite();
  try {
    const out = await getJson("/api/admin/restart-workload", {
      method: "POST",
      body: JSON.stringify({ site, target }),
    });
    appendLog(`${site} ${target}: ${out.message}`, out.ok);
  } catch (err) {
    appendLog(`${site} ${target}: ${err.message}`, false);
  }
  await refresh();
}

async function resetDesktop() {
  const site = selectedSite();
  try {
    const out = await getJson("/api/admin/reset-desktop", {
      method: "POST",
      body: JSON.stringify({ site }),
    });
    appendLog(`${site} reset desktop: ${out.message}`, out.ok);
  } catch (err) {
    appendLog(`${site} reset desktop: ${err.message}`, false);
  }
  await refresh();
}

async function loadSessions() {
  const site = selectedSite();
  const tbody = document.querySelector("#session-table tbody");
  tbody.innerHTML = "";
  try {
    const out = await getJson(`/api/admin/sessions?site=${encodeURIComponent(site)}`);
    appendLog(`${site} sessions: ${out.message}`, out.ok);
    for (const row of out.rows || []) {
      const tr = document.createElement("tr");
      tr.innerHTML = `<td>${row.username}</td><td>${row.connection}</td><td>${row.start_utc}</td>`;
      tbody.appendChild(tr);
    }
  } catch (err) {
    appendLog(`${site} sessions: ${err.message}`, false);
  }
}

async function loadProcesses() {
  const site = selectedSite();
  try {
    const out = await getJson(`/api/admin/processes?site=${encodeURIComponent(site)}`);
    appendLog(`${site} processes: ${out.message}`, out.ok);
    document.getElementById("process-output").textContent = out.output || "(no output)";
  } catch (err) {
    appendLog(`${site} processes: ${err.message}`, false);
  }
}

function wireControls() {
  document.getElementById("site-select").addEventListener("change", syncAssistLink);
  document.querySelectorAll("button").forEach((btn) => {
    const action = btn.dataset.action;
    const target = btn.dataset.target;
    btn.addEventListener("click", async () => {
      if (action === "restart") return restart(target);
      if (action === "reset") return resetDesktop();
      if (action === "sessions") return loadSessions();
      if (action === "processes") return loadProcesses();
    });
  });
}

wireControls();
refresh();
setInterval(refresh, REFRESH_MS);
