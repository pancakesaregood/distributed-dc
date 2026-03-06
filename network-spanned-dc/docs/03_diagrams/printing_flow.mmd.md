# Printing Service Flow

Reference flow for managed printing from user job submission to printer output.

```mermaid
flowchart LR
  USER["User Endpoint"] --> QUEUE["Print Queue (Client Policy)"]
  QUEUE --> PS["Print Server Cluster"]
  PS --> AUTH["Directory and Identity Services"]
  PS --> PRN["Network Printer or MFP"]
  PRN --> OUT["Printed Output"]

  SEC["Secure Release Station (optional)"] --> PRN
  LOG["Central Logging"] <-- PS

  style PS fill:#EAF4FF,stroke:#2E6DA4,stroke-width:2px,color:#111111
  style PRN fill:#FFF4DB,stroke:#A56A00,stroke-width:2px,color:#111111
  style AUTH fill:#EAF4FF,stroke:#2E6DA4,stroke-width:2px,color:#111111
  linkStyle default color:#CC5500
```
