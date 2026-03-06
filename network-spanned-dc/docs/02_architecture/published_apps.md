# Published Applications

## What a Published App Is

A published application is any service intentionally exposed to internet clients through the DMZ stack at one or more sites. Published apps are not directly reachable from the internet - all inbound traffic passes through the firewall DMZ rule, the WAF, and the nginx load balancer before reaching any backend. Internal users reaching the same service from inside the network are served directly by the firewall zone policy without traversing the DMZ stack.

---

## Component Stack

Every published app uses the following per-site component chain:

```
Public DNS (FQDN)
  -> Edge router internet interface (public IP or anycast VIP)
    -> Firewall Outside -> DMZ rule (HTTPS 443 only)
      -> WAF (OWASP inspection + app-specific rules)
        -> nginx LB (TLS termination, upstream pool, health checks)
          -> Backend service (Servers/VMs zone, approved app port)
            -> Database if required (Servers/VMs zone, stateful, same or replicated site)
```

Each layer is required. There is no bypass path from the internet to a backend without traversing the WAF and LB.

---

## Application Types

| Type | Backend | State | Spanning Pattern |
|---|---|---|---|
| Web frontend | Stateless VM or container | None | Active-active, any number of sites |
| API service | Stateless VM or container | None | Active-active, any number of sites |
| Full-stack app | Stateless frontend + stateful DB | Write: single primary DB, reads: replicas | Frontend active-active; DB active-standby |
| Admin portal | Stateless app | None | Single site or VPN-only (not published externally) |

---

## TLS

- nginx LB terminates TLS for all published services. Backends receive plain HTTP on the internal app port unless the app requires end-to-end TLS (in which case nginx re-encrypts).
- Certificates are provisioned via Let's Encrypt (certbot with DNS-01 or HTTP-01 challenge) or an internal CA for non-public FQDNs.
- Certificate configuration is stored in GitOps. Renewal automation runs on the nginx LB VM and triggers a reload (not a restart) on success.
- Minimum TLS version: 1.2. Preferred: TLS 1.3 only. Cipher suite list is defined in the nginx GitOps template and reviewed quarterly.
- HSTS is enabled for all externally published HTTPS services.

---

## DNS Models

### Single-Site Publication

A public A/AAAA record points to the edge router's internet-facing IPv4 or IPv6 address at one site. Suitable for services that do not require geographic distribution or multi-site failover at the DNS layer.

- Simple to operate.
- If the site is unavailable, the service is unavailable until DNS is manually updated or TTL expires.
- Use low TTLs (60-300 seconds) if manual failover is a recovery option.

### Multi-Site with GeoDNS

Multiple A/AAAA records - one per publishing site - with a GeoDNS provider routing clients to the nearest site by geography or latency. Each site publishes the same FQDN with its own IP.

- No single IP dependency. Failure of one site causes GeoDNS to remove its record.
- Health checks at the GeoDNS provider gate record withdrawal on site-level health.
- Suitable for latency-sensitive apps where clients should hit the closest site.

### Multi-Site with BGP Anycast

An anycast `/128` loopback address is advertised from multiple sites via BGP. All sites advertise the same address; routing selects the nearest. The nginx LB VIP at each site is bound to this loopback.

- No DNS dependency for routing decisions - BGP handles path selection.
- Withdraw the advertisement from a site when the local service is unhealthy (health-gated route advertisement).
- Preferred for stateless services with consistent backend state or read-only workloads.
- Do not use anycast for stateful write paths unless write coordination is explicitly handled at the application layer.

---

## WAF Profile Per App

Each published app has a WAF profile applied at the WAF VM:

- **Base profile**: OWASP Top 10 ruleset applied to all apps. This is the default and cannot be disabled.
- **App-specific rules**: additional rules or exceptions layered on top. Exceptions must be documented and reviewed in GitOps with justification.
- **Rate limiting**: applied per IP or per session at the WAF layer. Default threshold defined in the base profile; app owners can request tighter limits.
- WAF operates in blocking mode. Rule exceptions require a GitOps PR with peer review.

---

## nginx Upstream Configuration

Each published app has a named upstream block in the nginx configuration:

```nginx
upstream app-<name> {
    server <backend-ipv6-1>:<port> max_fails=3 fail_timeout=10s;
    server <backend-ipv6-2>:<port> max_fails=3 fail_timeout=10s;
    keepalive 32;
}

server {
    listen 443 ssl;
    server_name app.example.com;

    ssl_certificate     /etc/nginx/certs/app.example.com.crt;
    ssl_certificate_key /etc/nginx/certs/app.example.com.key;
    ssl_protocols       TLSv1.3;

    add_header Strict-Transport-Security "max-age=63072000" always;

    location / {
        proxy_pass http://app-<name>;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

All nginx configuration is stored in GitOps. Changes are applied via the automation pipeline, not manual edits on the VM.

---

## Firewall Rules Required

Two firewall rules are created per published app:

| Rule | Source Zone | Destination Zone | Protocol / Port | Action |
|---|---|---|---|---|
| Inbound to WAF | Outside | DMZ | TCP 443 (HTTPS) | Permit |
| LB to backend | DMZ | Servers/VMs | TCP `<app port>` | Permit |

No other ports are opened. If the app requires HTTP-to-HTTPS redirect, an additional rule for TCP 80 -> DMZ is added with the redirect handled at nginx (302 to HTTPS). HTTP 80 never reaches the backend.

---

## Health Checks and Failover

- nginx performs active upstream health checks. A backend failing `max_fails` within `fail_timeout` is removed from the pool automatically and re-added when it recovers.
- WAF monitors its own traffic rate and error rate. Anomalies are logged and alerted.
- For anycast deployments: a site-level health daemon checks the nginx upstream health and withdraws the anycast BGP advertisement from the edge if all local backends are unhealthy. This prevents the site from attracting traffic it cannot serve.
- For GeoDNS deployments: an external health check (configured at the DNS provider) probes the site's published IP and removes the DNS record if the probe fails.

---

## Multi-Site State Considerations

| Component | Multi-site approach |
|---|---|
| Stateless frontends and APIs | Run at all publishing sites independently. No coordination required. |
| Session state | Store in a shared backend (Redis or DB) replicated across sites. Do not use sticky sessions at the LB layer unless the session store is unavailable. |
| Stateful DB (writes) | Single primary DB site. Read replicas at other sites for read traffic. Writes must route to the primary via internal routing - do not expose write endpoints externally. |
| Uploaded/stored files | Replicate to object storage accessible at all sites over IPsec-encrypted inter-site tunnels. |

---

## App Publish Workflow

See the [Published App Publish Workflow diagram](../03_diagrams/published_apps_flow.mmd.md) for the step-by-step flow.

### Steps

1. **Request and scope** - app owner submits publish request with FQDN, backend IPs/ports, TLS cert source, and WAF exception requirements (if any).
2. **Architecture review** - confirm backend tier (stateless or stateful), spanning model, and DNS strategy. Assign a site or set of sites.
3. **GitOps PRs** - open PRs for all configuration:
   - nginx upstream and server block
   - WAF profile (base + app-specific rules)
   - Firewall DMZ rule (inbound) and DMZ-to-backend rule
   - TLS certificate (stored in secrets manager, referenced by nginx)
4. **Peer review and merge** - all PRs reviewed and merged to main. Automation applies configuration to staging environment.
5. **Staging validation** - verify:
   - HTTPS reachable, correct cert, HSTS header present
   - WAF blocking a test injection payload (e.g., `?q=<script>alert(1)</script>`)
   - nginx upstream health check green
   - Firewall correctly denying non-HTTPS ports
6. **DNS cutover** - update public DNS to point FQDN at the edge IP or anycast VIP. Use a short TTL during cutover.
7. **Production smoke test** - verify reachability, cert, and basic app function from an external connection.
8. **Monitoring** - confirm traffic appears in nginx access logs, WAF event log, and observability dashboards. Set alert thresholds for error rate and latency.
