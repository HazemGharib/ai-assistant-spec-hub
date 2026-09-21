# Contracts Versioning — Phase 3 (RAG)

**Package**: `@hazemgharib/ai-agent-contracts`  
**This feature ships**: **`0.3.0` (MINOR)**

## Why MINOR (not MAJOR)

| Change | Compatibility |
|--------|----------------|
| New `POST /v1/ingest` schemas + error codes | Additive |
| `RetrievedChunk.version` (positive int) required | Additive field; coordinated consumer upgrade |
| New error codes: `UNSUPPORTED_FORMAT`, `NO_CONTENT`, `PROVIDER_ERROR` | Additive enum members |

No removals or renames of Phase 1/2 retrieve request fields.

## Consumer pins

| Repo | Action |
|------|--------|
| `ai-assistant-rag` | Implement provider; depend on `0.3.0` |
| `ai-assistant-backend` | Pin `0.3.0`; tolerate/pass through `version` on chunks |
| `ai-assistant-ui` | No direct RAG dependency; no change required for ingest |
| `ai-assistant-mcp` | Unchanged |

## Upgrade rule

Integrated smoke (backend → RAG retrieve) is green only when backend and RAG both run `0.3.0`. Follow Phase 1 versioning policy in `specs/001-platform-foundation/contracts/versioning.md`.
