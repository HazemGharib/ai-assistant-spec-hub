# Smoke / secrets validation log

**Feature**: `001-platform-foundation`  
**Date**: 2026-09-20

## Integrated smoke (T050 / T067)

Run after starting rag → mcp → backend (ports 3002 / 3003 / 3001):

```bash
cd ai-assistant-backend && pnpm smoke:integrated
```

**Pass criteria**: HTTP 200; `diagnostics.hitRag === true`; `diagnostics.hitMcp === true`; `contractPackageVersion` matches `0.1.0`.

| Check | Result | Notes |
| ------- | -------- | ------- |
| Integrated smoke (curl POST `/v1/chat` with requireRag+requireMcp) | **PASS** | `hitRag: true`, `hitMcp: true`, `contractPackageVersion: "0.1.0"` |
| Isolated `pnpm test` (contracts/backend/rag/mcp/ui) | **PASS** | Fakes; no live sibling ports |
| Default ports documented | 3001 / 3002 / 3003 / 5173 | quickstart + READMEs |

## Secrets grep (T063)

Command (workspace root):

```bash
rg -n --hidden -g '!.git' -g '!node_modules' -g '!.pnpm-store' \
  -e 'AKIA[0-9A-Z]{16}' -e 'BEGIN (RSA |OPENSSH )?PRIVATE KEY' \
  -e 'aws_secret_access_key' -e 'api[_-]?key\s*[:=]\s*['\''\"][^'\''\"]+' \
  ai-assistant-ui ai-assistant-backend ai-assistant-rag ai-assistant-mcp ai-assistant-contracts \
  || true
```

| Check | Result |
| ------- | -------- |
| `.env` gitignored in runtime repos | YES (`.env`, `.env.*`, `!.env.example`) |
| Live credentials committed | NONE found (placeholders only in `.env.example`) |

## Contracts path audit (T069)

```bash
bash ai-assistant-spec-hub/specs/001-platform-foundation/scripts/assert-no-src-path-deps.sh
```

Expected: `OK: no file:.../src contract path dependencies.`
