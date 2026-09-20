# Quickstart: Platform Foundation (Phase 1)

Local-first guide for the multi-repo foundation. **$0** — no AWS, no API keys required for stubs.

## Ownership map

| Repository | Owns | Does not own |
| ------------ | ------ | -------------- |
| `ai-assistant-ui` | Chat presentation, client UX | Orchestration, RAG, MCP tools |
| `ai-assistant-backend` | Orchestration, UI chat API, RAG/MCP clients | Index storage, tool server impl |
| `ai-assistant-rag` | Retrieve stub / future ingestion+retrieval | Chat UX, MCP tools |
| `ai-assistant-mcp` | MCP tool/resource server | Chat UX, vector index |
| `ai-assistant-contracts` | Versioned boundary schemas/package | Runtime business behavior |
| `ai-assistant-spec-hub` | Specs, constitution, plans | Runtime services |

Boundaries: **UI → backend → (RAG | MCP)** via `@ai-assistant/contracts` only.

## Prerequisites

- Node.js 22+
- pnpm 10+ (`corepack enable` recommended)
- Sibling checkouts under `ai-assistant/`:

```text
ai-assistant/
  ai-assistant-spec-hub/
  ai-assistant-ui/
  ai-assistant-contracts/   # create in implementation
  ai-assistant-backend/
  ai-assistant-rag/
  ai-assistant-mcp/
```

## Install contracts package (all runtime repos)

From `ai-assistant-contracts`:

```bash
pnpm install
pnpm build
# consumers use file: dependency, e.g. in package.json:
# "@ai-assistant/contracts": "file:../ai-assistant-contracts"
```

Pin/respect the package `version` field (start at `0.1.0`). See [contracts/versioning.md](./contracts/versioning.md).

## Isolated mode (per repository)

Each runtime repo should support:

```bash
pnpm install
pnpm test
pnpm lint
pnpm typecheck
pnpm dev
```

| Repo | Health / smoke alone |
| ------ | ---------------------- |
| UI | Opens Vite app; uses local stub adapter if `VITE_BACKEND_BASE_URL` unset |
| Backend | `GET http://127.0.0.1:3001/health` (fakes RAG/MCP) |
| RAG | `GET http://127.0.0.1:3002/health` |
| MCP | Tool list / `smoke_ping` without backend |
| Contracts | `pnpm test` validates Zod/OpenAPI-aligned schemas |

## Integrated smoke path

Default ports: UI `5173`, backend `3001`, RAG `3002`, MCP `3003` (if HTTP).

### 1. Start providers

```bash
# terminals
cd ai-assistant-rag && pnpm dev
cd ai-assistant-mcp && pnpm dev
cd ai-assistant-backend && \
  RAG_BASE_URL=http://127.0.0.1:3002 \
  MCP_SERVER_URL=http://127.0.0.1:3003 \
  pnpm dev
cd ai-assistant-ui && \
  VITE_BACKEND_BASE_URL=http://127.0.0.1:3001 \
  pnpm dev
```

### 2. Execute smoke

Send a chat request that requires both boundaries (UI UI or curl):

```bash
curl -s http://127.0.0.1:3001/v1/chat \
  -H 'content-type: application/json' \
  -d '{
    "conversationId": "00000000-0000-4000-8000-000000000001",
    "smoke": { "requireRag": true, "requireMcp": true },
    "message": {
      "messageId": "00000000-0000-4000-8000-000000000002",
      "role": "user",
      "content": "Smoke: retrieve policy and ping MCP",
      "createdAt": "2026-09-20T00:00:00.000Z"
    }
  }'
```

### 3. Pass criteria

- HTTP 200
- `diagnostics.hitRag === true`
- `diagnostics.hitMcp === true`
- `diagnostics.contractPackageVersion` matches installed `@ai-assistant/contracts`
- No paid cloud credentials used

If a sibling is down, error `code` should be `UPSTREAM_UNAVAILABLE` with `boundary` set; isolated `pnpm test` in each repo must still pass.

## Environment cheat sheet

| Variable | Repo | Purpose |
| ---------- | ------ | --------- |
| `VITE_BACKEND_BASE_URL` | ui | Integrated chat; unset = local stub |
| `RAG_BASE_URL` | backend | RAG base URL |
| `MCP_SERVER_URL` | backend | MCP HTTP base (or use stdio config per MCP README) |
| `PORT` | backend/rag/mcp | Override listen port |

**Do not commit secrets.** Phase 1 needs none for inter-service calls.

## Engineering baseline (every runtime + contracts)

- TypeScript strict
- Scripts: `dev`, `test`, `lint`, `typecheck`, `format`, `format:check`
- CI: install → lint → typecheck → test
- README: purpose, setup, env, contracts link, smoke notes

## Security note

Local services trust localhost. Do not expose them publicly without auth (future phase).
