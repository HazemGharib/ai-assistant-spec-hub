# Implementation Plan: RAG Repository

**Branch**: `003-rag-repository` | **Date**: 2026-09-21 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-rag-repository/spec.md`

## Summary

Replace the Phase 1 fixture-only RAG stub in `ai-assistant-rag` with a real local ingestion + retrieval pipeline: parse Markdown/PDF bytes, normalize, chunk, embed, index (sqlite-vec), and retrieve with citation metadata. Expose synchronous `POST /v1/ingest` alongside existing `POST /v1/retrieve`, keep embedding and vector-store behind internal provider interfaces (Memory for tests; sqlite-vec durable default; Bedrock/OpenSearch-class adapters later). Retrieve returns top-`limit` by score with **no minimum score floor** (empty only when the index is empty). Extend `@hazemgharib/ai-agent-contracts` to **0.3.0** with ingest schemas plus `RetrievedChunk.version`.

## Technical Context

**Language/Version**: TypeScript ~5.8 / Node.js 22+ (`ai-assistant-rag`); contracts package TypeScript on Node 22  
**Primary Dependencies**: Hono + `@hono/node-server` (existing); Zod via `@hazemgharib/ai-agent-contracts` **0.3.0**; Vitest; oxlint; Prettier; pnpm; PDF text extract (OSS, e.g. `pdf-parse`); Markdown normalize (lightweight OSS or minimal custom); **sqlite-vec** + SQLite driver (e.g. `better-sqlite3`); local embedding via `@xenova/transformers` (optional) + deterministic embedding for CI; no paid APIs  
**Storage**: `DATA_DIR` (default `./data`) with SQLite file (e.g. `rag.sqlite`) for registry + sqlite-vec vectors; `MemoryVectorStore` for unit tests; no AWS/OpenSearch required  
**Testing**: Vitest with deterministic embeddings + memory store; sqlite-vec smoke on temp DB; fixture MD/PDF ingest→retrieve; empty-index vs top-k unrelated-query cases; no paid cloud  
**Target Platform**: Local-first RAG on `http://127.0.0.1:3002`; AWS Bedrock/OpenSearch as portable adapter targets only  
**Project Type**: Multi-repository (Phase 1); primary work in `ai-assistant-rag` + contracts MINOR; backend pins 0.3.0 (retrieve consumer); ingest is operator → RAG  
**Performance Goals**: Retrieve &lt; 2s warm local for ≤100 chunks (SC-003); sync ingest of small docs for local demo  
**Constraints**: $0 default; secrets not in repo; provider adapters; untrusted chunk text; no inter-service auth; sync ingest; caller `documentId`; server version; drop superseded; top-k no score floor  
**Scale/Scope**: Single local knowledge base; Markdown + PDF only; no OCR, hybrid search, rerank, multi-tenant ACL, async jobs, or min-score filtering

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*
*Source: `.specify/memory/constitution.md` (TypeScript RAG AI Agent Platform)*

- [x] TypeScript/Node for frontend and agent services; secrets not in source control
- [x] Clear UI → Agent → (RAG | MCP) separation; UI not coupled to agent internals — RAG owns ingest/retrieve only
- [x] Feature runs locally without AWS; paid/cloud deps optional and documented
- [x] Zero-cost default: any paid service justified — none required; sqlite-vec + local embeddings
- [x] Provider-specific code behind interfaces (embeddings, vector store)
- [x] RAG used only for knowledge retrieval—not for authoritative structured queries
- [x] MCP tools schema-validated — N/A (MCP out of scope)
- [x] Security: untrusted docs/tool output; no secrets in browser; retrieved text treated as untrusted
- [x] Tests cover affected subsystems without paid cloud; observability = structured route logs + provider errors
- [x] No unjustified complexity — no managed vector DB, no K8s, no new repos beyond existing `ai-assistant-rag`
- [x] Docs/ADR impact noted — research.md decisions + quickstart + contracts 0.3.0

Violations MUST be listed in Complexity Tracking below with justification.

### Post-design Constitution Check (Phase 1)

Re-validated after `research.md`, `data-model.md`, `contracts/`, and `quickstart.md`: gates still pass. Contracts isolate consumers; sqlite-vec is local/$0 behind `VectorStore`; Memory for CI; top-k retrieve semantics documented; no auth or paid infra.

## Project Structure

### Documentation (this feature)

```text
specs/003-rag-repository/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── README.md
│   ├── backend-rag-retrieve.openapi.yaml
│   ├── backend-rag-ingest.openapi.yaml
│   └── versioning.md
├── checklists/
│   └── requirements.md
└── tasks.md             # /speckit.tasks — not created here
```

### Source Code (ai-assistant workspace — sibling repositories)

```text
ai-assistant/
├── ai-assistant-spec-hub/
├── ai-assistant-contracts/                # bump to 0.3.0
│   └── src/
│       ├── retrieve/                      # + version on RetrievedChunk
│       └── ingest/                        # NEW
├── ai-assistant-rag/                      # PRIMARY
│   ├── src/
│   │   ├── server.ts
│   │   ├── routes/
│   │   │   ├── retrieve.ts                # top-k; empty only if index empty
│   │   │   └── ingest.ts
│   │   ├── pipeline/
│   │   │   ├── parseMarkdown.ts
│   │   │   ├── parsePdf.ts
│   │   │   ├── normalize.ts
│   │   │   ├── chunk.ts
│   │   │   ├── ingestDocument.ts
│   │   │   └── retrieve.ts
│   │   ├── providers/
│   │   │   ├── embedding/
│   │   │   │   ├── types.ts
│   │   │   │   ├── deterministic.ts
│   │   │   │   └── transformers.ts        # optional
│   │   │   └── vector/
│   │   │       ├── types.ts
│   │   │       ├── memory.ts
│   │   │       └── sqliteVec.ts           # sqlite-vec
│   │   ├── store/
│   │   │   └── documentRegistry.ts
│   │   └── config.ts
│   ├── fixtures/
│   ├── data/                              # gitignored *.sqlite
│   ├── .env.example
│   └── README.md
└── ai-assistant-backend/                  # pin contracts 0.3.0
    └── src/clients/ragClient.ts
```

**Structure Decision**: Continue Phase 1 multi-repo layout. No new repositories. Center of gravity: `ai-assistant-rag`; contracts own wire schemas; backend remains retrieve consumer.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
| ----------- | ------------ | ------------------------------------- |
| Multi-repository (vs modular monolith) | Inherited Phase 1 topology; RAG independently replaceable | Collapsing into backend blurs FR-001 / constitution VI |
| Optional Transformers.js | Local semantic quality for SC-001 without paid APIs | Deterministic-only may fail probes; CI stays deterministic |
| Native sqlite-vec / better-sqlite3 | Durable vectors with OpenSearch/pgvector-shaped semantics | Pure JSON cosine weaker for portability practice; Memory remains for tests |

## Implementation Approach (for `/speckit.tasks`)

1. **Contracts 0.3.0**: Ingest Zod/OpenAPI; require `version` on `RetrievedChunk`; RAG error codes (`UNSUPPORTED_FORMAT`, `NO_CONTENT`, `PROVIDER_ERROR`).
2. **Providers**: `EmbeddingProvider` + `VectorStore`; Memory + Deterministic for tests; **SqliteVecVectorStore** for durable local.
3. **Pipeline**: MD/PDF parse, normalize, chunk (stable IDs), sync ingest with per-`documentId` lock and atomic version swap.
4. **HTTP**: `POST /v1/ingest`; `POST /v1/retrieve` queries real index — **top-`limit` always when non-empty; empty `chunks` iff index empty**.
5. **Fixtures & probes**: Sample MD/PDF + probes for SC-001; document 5 MiB limit.
6. **Backend pin**: Contracts 0.3.0; tolerate `version` on chunks.
7. **Docs**: README + quickstart; env for `DATA_DIR`, `SQLITE_PATH`, `VECTOR_STORE`, `EMBEDDING_PROVIDER`, `PORT`.
8. **Verify**: Isolated tests + optional backend→RAG smoke.
