# Quickstart: Conversational UI (Phase 2)

Local-first guide for the Phase 2 conversational UI. **$0** — no AWS, no LLM/RAG/MCP keys required in the UI repo.

## What this phase delivers

- Minimalist multi-conversation chat in `ai-assistant-ui` (assistant-ui)
- Talks **only** to backend public API / SSE stream via `@hazemgharib/ai-agent-contracts` ≥ `0.2.0`
- Streaming, Stop, single-slot send queue, display-only citations, generic activity events
- Isolated mock mode + optional live backend URL

## Prerequisites

- Node.js 22+
- pnpm 10+
- Sibling checkouts:

```text
ai-assistant/
  ai-assistant-spec-hub/
  ai-assistant-ui/
  ai-assistant-contracts/   # bump to 0.2.0
  ai-assistant-backend/     # implement conversation + stream (stub OK)
```

## Contracts package

Pin **`@hazemgharib/ai-agent-contracts@0.2.0`** in UI and backend (see [contracts/versioning.md](./contracts/versioning.md)).

```bash
# From ai-assistant-contracts after implementing 0.2.0 schemas:
pnpm build
# publish or local link per Phase 1 docs, then in UI/backend:
pnpm install
```

## Isolated UI (mock — no siblings required at runtime)

```bash
cd ai-assistant-ui
pnpm install
# Prefer mock for isolated demo/tests:
export VITE_USE_MOCK_BACKEND=true
# Do NOT set VITE_BACKEND_BASE_URL when using mock
pnpm dev
pnpm test
pnpm lint
pnpm typecheck
```

Mock must support: list/create/switch conversations, stream deltas, Stop abort, citations/activity fixtures, and **reload restore** of list + messages within the mock store.

## Integrated mode (UI → backend only)

```bash
# Terminal A — backend (after 0.2.0 contract + stream routes)
cd ai-assistant-backend
pnpm install && pnpm dev   # default http://127.0.0.1:3001

# Terminal B — UI
cd ai-assistant-ui
export VITE_USE_MOCK_BACKEND=false
export VITE_BACKEND_BASE_URL=http://127.0.0.1:3001
pnpm dev
```

Smoke checklist:

1. Create two conversations; send messages in each; switch — no message bleed
2. Observe streaming tokens; submit a queued follow-up while streaming; confirm send-after-complete
3. Stop mid-stream; confirm queue discarded / draft restored; partial text kept
4. Reload browser; list + active thread restore from backend
5. Confirm UI `package.json` has no RAG/MCP/LLM provider dependencies

RAG/MCP may run behind the backend for deeper smoke, but the **UI never configures them**.

## Environment

| Variable | Required | Purpose |
|----------|----------|---------|
| `VITE_BACKEND_BASE_URL` | Integrated mode | Public backend origin only |
| `VITE_USE_MOCK_BACKEND` | Isolated mode | `true` to use in-repo persisting mock |

Never put LLM/RAG/MCP secrets in UI env files.

## Ownership reminder

| Layer | Owns |
|-------|------|
| `ai-assistant-ui` | Presentation, queue/Stop UX, contract client |
| `ai-assistant-backend` | Persistence, stream generation, orchestration |
| `ai-assistant-contracts` | Schemas / OpenAPI alignment |
| RAG / MCP | Not UI dependencies |

## Spec artifacts

- [spec.md](./spec.md)
- [plan.md](./plan.md)
- [research.md](./research.md)
- [data-model.md](./data-model.md)
- [contracts/](./contracts/)
