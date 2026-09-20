# Platform Ownership Map

**Feature**: Phase 1 Platform Foundation  
**Audience**: Contributors assigning change requests to repos without reading implementation code

## Repository table

| Repository | Kind | Default port | Owns (in scope) | Does not own (out of scope) | Inbound contracts | Outbound contracts |
| ------------ | ------ | -------------- | ----------------- | ----------------------------- | ------------------- | -------------------- |
| `ai-assistant-ui` | runtime | `5173` | Chat presentation, client UX, adapters | Orchestration, RAG index, MCP tools | — | `ui-backend-chat` |
| `ai-assistant-backend` | runtime | `3001` | Orchestration, UI chat API, RAG/MCP clients | Index storage, tool server impl, chat chrome | `ui-backend-chat` | `backend-rag-retrieve`, `backend-mcp-capabilities` |
| `ai-assistant-rag` | runtime | `3002` | Retrieve stub / future ingestion+retrieval | Chat UX, MCP tools, orchestration | `backend-rag-retrieve` | — |
| `ai-assistant-mcp` | runtime | `3003` | MCP tool/resource server (`smoke_ping`) | Chat UX, vector index, orchestration | `backend-mcp-capabilities` | — |
| `ai-assistant-contracts` | contracts | — | Versioned Zod schemas / types package | Runtime business behavior | — | — (consumed by all runtimes) |
| `ai-assistant-spec-hub` | governance | — | Specs, constitution, plans, ownership docs | Runtime services | — | — |

**Boundary rule**: UI → backend → (RAG | MCP) only via `@hazemgharib/ai-agent-contracts`. Never import sibling `src` trees.

## Environment matrix (isolated vs integrated)

| Variable | Repo | Isolated | Integrated |
| ---------- | ------ | ---------- | ------------ |
| `PORT` | backend / rag / mcp | optional (defaults 3001/3002/3003) | optional |
| `VITE_BACKEND_BASE_URL` | ui | unset → local stub adapter | `http://127.0.0.1:3001` |
| `RAG_BASE_URL` | backend | unset → in-process fake | `http://127.0.0.1:3002` |
| `MCP_SERVER_URL` | backend | unset → in-process fake | `http://127.0.0.1:3003` |

No inter-service auth secrets in Phase 1. Do not commit `.env` files with live credentials.

## Sample change-request quiz (SC-001)

Assign each request to the owning repo (answers below).

1. Change the chat bubble styling / thread layout.
2. Add a new field to the shared chat request schema used by UI and backend.
3. Fix stub orchestrator routing when both RAG and MCP are required.
4. Return a different fixture chunk text from retrieve.
5. Change `smoke_ping` output shape or validation.

### Answers

1. **`ai-assistant-ui`** — presentation only.
2. **`ai-assistant-contracts`** (then bump consumers) — shared schema, not a single runtime.
3. **`ai-assistant-backend`** — orchestration owns routing.
4. **`ai-assistant-rag`** — retrieve provider.
5. **`ai-assistant-contracts`** for the schema + **`ai-assistant-mcp`** for the tool implementation (schema change lands in contracts first).

## Related docs

- Quickstart: [`../specs/001-platform-foundation/quickstart.md`](../specs/001-platform-foundation/quickstart.md)
- Engineering standards: [`engineering-standards.md`](./engineering-standards.md)
- Context overview: [`context.md`](./context.md)
