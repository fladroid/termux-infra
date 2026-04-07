# termux-infra

Infrastrukturni repozitorij za Termux čvorove u Balsam ekosistemu.

## Čvorovi

| Čvor | Tip | PG port | MCP port |
|------|-----|---------|----------|
| s7plus | Samsung Tab S7+ | 5433 | 8001 |
| sa55 | Samsung A55 | 5434 | 8002 |
| sa9plus | Samsung A9+ | 5435 | 8003 |

## Struktura

```
mcp/        — MCP server kod (zajednički)
runit/      — runit servisni skriptovi
scripts/    — pomoćne skripte (james.sh i sl.)
sql/        — katalog DDL za Termux čvorove
nodes/      — konfiguracija specifična po čvoru
  s7plus/
  sa55/
  sa9plus/
```

## Stack

- PostgreSQL 18.x (aarch64 Android)
- llama.cpp (llama-server)
- MCP server (SSE transport)
- autossh tunel prema Balsam VPS-u
- runit za upravljanje servisima
