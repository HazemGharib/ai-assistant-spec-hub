# Contracts versioning (Phase 2 UI)

| Item | Value |
|------|--------|
| Package | `@hazemgharib/ai-agent-contracts` |
| Phase 1 baseline | `0.1.0` |
| Phase 2 target | **`0.2.0` (MINOR)** |

## Why MINOR

Additive APIs and schemas:

- Conversation list/create/get-messages types
- Stream event Zod schemas / TypeScript types
- Optional `snippet` / `url` on citations
- Activity event schema

Phase 1 `ChatRequest` / `ChatResponse` / `POST /v1/chat` remain valid for compatibility.

## Breaking changes (would require MAJOR)

- Renaming/removing required Phase 1 chat fields
- Changing conversationId format away from UUID without dual support
- Requiring auth headers on local chat (out of scope; do not add in 0.2.0)

## Consumer pin

`ai-assistant-ui`, `ai-assistant-backend`, `ai-assistant-rag`, and `ai-assistant-mcp` MUST pin `0.2.0` for Phase 2. Document upgrade in each README.
