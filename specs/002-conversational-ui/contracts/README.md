# Contracts: Conversational UI (Phase 2)

Phase 2 **extends** the UI↔backend boundary owned by `ai-assistant-contracts` (`@hazemgharib/ai-agent-contracts`).

| Artifact | Purpose |
|----------|---------|
| [ui-backend-chat.openapi.yaml](./ui-backend-chat.openapi.yaml) | Phase 2 OpenAPI: conversations CRUD + SSE stream + retained Phase 1 `/v1/chat` |
| [stream-events.md](./stream-events.md) | SSE event vocabulary and client handling rules |
| [versioning.md](./versioning.md) | Semver expectations for `0.2.0` bump |
| [README.md](./README.md) | How this folder relates to the contracts package |

**Non-goals**: Backend↔RAG and Backend↔MCP contracts are unchanged in this feature folder (still Phase 1 artifacts under `specs/001-platform-foundation/contracts/`).

**Consumer rule**: `ai-assistant-ui` depends only on the versioned contracts package + documented backend base URL. No RAG/MCP/LLM client libraries in the UI repo.
