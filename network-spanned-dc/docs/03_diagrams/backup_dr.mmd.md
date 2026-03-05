# Backup and DR Flow

```mermaid
graph LR
  subgraph SA[Site A]
    A1[Primary Data]
    AB[Local Backup Target]
  end

  subgraph SB[Site B]
    B1[Primary Data]
    BB[Local Backup Target]
  end

  subgraph SC[Site C]
    C1[Primary Data]
    CB[Local Backup Target]
  end

  subgraph SD[Site D]
    D1[Primary Data]
    DB[Local Backup Target]
  end

  IMM[(Optional Immutable Archive Tier)]

  A1 --> AB
  B1 --> BB
  C1 --> CB
  D1 --> DB

  AB --> BB
  BB --> CB
  CB --> DB
  DB --> AB

  AB --> IMM
  BB --> IMM
  CB --> IMM
  DB --> IMM
```
