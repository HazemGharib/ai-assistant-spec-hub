# Contracts: RAG Repository (Phase 3)

**Package target**: `@hazemgharib/ai-agent-contracts` **0.3.0**  
**Consumers**: `ai-assistant-rag` (provider), `ai-assistant-backend` (retrieve client), operators/tests (ingest)

## Files

| File | Purpose |
|------|---------|
| [backend-rag-retrieve.openapi.yaml](./backend-rag-retrieve.openapi.yaml) | Retrieve + health (evolved from Phase 1; adds `version` on chunks) |
| [backend-rag-ingest.openapi.yaml](./backend-rag-ingest.openapi.yaml) | Synchronous document ingest |
| [versioning.md](./versioning.md) | Semver notes for 0.3.0 |

## Boundaries

```text
Operator / script ──POST /v1/ingest──► ai-assistant-rag
ai-assistant-backend ──POST /v1/retrieve──► ai-assistant-rag
```

UI MUST NOT call these endpoints directly.

## Implementation mapping

| Spec contract | Contracts package path (planned) |
|---------------|----------------------------------|
| Retrieve schemas | `ai-assistant-contracts/src/retrieve/` |
| Ingest schemas | `ai-assistant-contracts/src/ingest/` (new) |
| Shared error codes | Prefer shared RAG error enum used by both routes |
