# Implementation Plan: RAG Repository

**Branch**: `003-rag-repository` | **Date**: 2026-09-21 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-rag-repository/spec.md`

## Summary

Replace the Phase 1 fixture-only RAG stub in `ai-assistant-rag` with a real local ingestion + retrieval pipeline: parse Markdown/PDF bytes, normalize, chunk, embed, index, and retrieve with citation metadata. Expose synchronous `POST /v1/ingest` alongside existing `POST /v1/retrieve`, keep embedding and vector-store behind internal provider interfaces (local defaults; Bedrock/OpenSearch-class adapters later), and extend `@hazemgharib/ai-agent-contracts` with ingest schemas plus additive retrieve citation fields (`version`) without breaking the backend client.

## Technical Context

**Language/Version**: TypeScript ~5.8 / Node.js 22+ (`ai-assistant-rag`); contracts package TypeScript on Node 22  
**Primary Dependencies**: Hono + `@hono/node-server` (existing); Zod via `@hazemgharib/ai-agent-contracts` **0.3.0**; Vitest; oxlint; Prettier; pnpm; PDF text extract (OSS, e.g. `pdf-parse` or equivalent); Markdown normalize (lightweight OSS or minimal custom); local embedding via `@xenova/transformers` (optional quality path) + deterministic embedding for CI; no paid APIs  
**Storage**: Local data directory (`DATA_DIR`, default `./data`) for document registry + vector index persistence; in-memory store for unit tests; no AWS/OpenSearch required  
**Testing**: Vitest unit/integration with fake embedding + memory vector store; fixture Markdown/PDF ingest→retrieve probes; no paid cloud; transformers model download not required in CI  
**Target Platform**: Local-first RAG service on `http://127.0.0.1:3002`; AWS Bedrock/OpenSearch as portable adapter targets only  
**Project Type**: Multi-repository (Phase 1 topology); primary work in `ai-assistant-rag` + contracts MINOR bump; backend pins new contracts and remains consumer-only of retrieve (ingest is operator/pipeline → RAG)  
**Performance Goals**: Retrieve &lt; 2s warm local for ≤100 chunks (SC-003); sync ingest of small docs suitable for local demo  
**Constraints**: $0 default; secrets not in repo; provider adapters; treat chunk text as untrusted; no inter-service auth (Phase 1); sync ingest only; caller-supplied `documentId`; server-assigned version; drop superseded versions  
**Scale/Scope**: Single local knowledge base; Markdown + PDF only; no OCR, hybrid search, rerank, multi-tenant ACL, or async jobs

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*
*Source: `.specify/memory/constitution.md` (TypeScript RAG AI Agent Platform)*

- [x] TypeScript/Node for frontend and agent services; secrets not in source control
- [x] Clear UI → Agent → (RAG | MCP) separation; UI not coupled to agent internals — RAG owns ingest/retrieve only
- [x] Feature runs locally without AWS; paid/cloud deps optional and documented
- [x] Zero-cost default: any paid service justified — none required; local embeddings + local index
- [x] Provider-specific code behind interfaces (embeddings, vector store)
- [x] RAG used only for knowledge retrieval—not for authoritative structured queries
- [x] MCP tools schema-validated — N/A (MCP out of scope)
- [x] Security: untrusted docs/tool output; no secrets in browser; retrieved text treated as untrusted
- [x] Tests cover affected subsystems without paid cloud; observability = structured route logs + provider errors
- [x] No unjustified complexity — no managed vector DB, no K8s, no new microservices beyond existing `ai-assistant-rag` repo
- [x] Docs/ADR impact noted — research.md decisions + quickstart + contracts 0.3.0

Violations MUST be listed in Complexity Tracking below with justification.

### Post-design Constitution Check (Phase 1)

Re-validated after `research.md`, `data-model.md`, `contracts/`, and `quickstart.md`: gates still pass. Ingest/retrieve remain behind shared contracts; embedding/vector adapters isolate future Bedrock/OpenSearch; local/CI path uses free providers; Phase 1 multi-repo ownership unchanged; no auth or paid infra introduced.

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
├── ai-assistant-spec-hub/                 # this plan/spec
├── ai-assistant-contracts/                # bump to 0.3.0
│   └── src/
│       ├── retrieve/                      # + version on RetrievedChunk; error codes
│       └── ingest/                        # NEW: ingest request/response Zod
├── ai-assistant-rag/                      # PRIMARY Phase 3 implementation
│   ├── src/
│   │   ├── server.ts                      # mount health, retrieve, ingest
│   │   ├── routes/
│   │   │   ├── retrieve.ts                # real index query (replace fixture-only)
│   │   │   └── ingest.ts                  # NEW sync multipart/JSON ingest
│   │   ├── pipeline/
│   │   │   ├── parseMarkdown.ts
│   │   │   ├── parsePdf.ts
│   │   │   ├── normalize.ts
│   │   │   ├── chunk.ts
│   │   │   └── ingestDocument.ts          # orchestrate parse→chunk→embed→index + versioning
│   │   ├── providers/
│   │   │   ├── embedding/
│   │   │   │   ├── types.ts               # EmbeddingProvider
│   │   │   │   ├── deterministic.ts       # CI/default-test
│   │   │   │   └── transformers.ts        # optional local quality (env-selected)
│   │   │   └── vector/
│   │   │       ├── types.ts               # VectorStore
│   │   │       ├── memory.ts
│   │   │       └── localJson.ts           # persist under DATA_DIR
│   │   ├── store/
│   │   │   └── documentRegistry.ts        # documentId → active version metadata
│   │   └── config.ts                      # DATA_DIR, MAX_UPLOAD_BYTES, provider selection
│   ├── fixtures/                          # sample .md / .pdf + probe queries
│   ├── data/                              # gitignored runtime index
│   ├── .env.example
│   └── README.md
└── ai-assistant-backend/                  # pin contracts 0.3.0; retrieve client unchanged aside from optional version field
    └── src/clients/ragClient.ts
```

**Structure Decision**: Continue sibling multi-repo layout from Phase 1. Phase 3 does **not** add repositories. Implementation center of gravity is `ai-assistant-rag`; contracts package owns wire schemas (`0.3.0`); backend remains a retrieve consumer (operators/scripts call ingest on RAG directly). UI/MCP unchanged.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
| ----------- | ------------ | ------------------------------------- |
| Multi-repository (vs modular monolith) | Inherited Phase 1 platform topology; RAG must stay independently replaceable | Collapsing into backend would blur FR-001 ownership and constitution VI |
| Optional Transformers.js dependency | Better local semantic quality for SC-001 without paid APIs | Deterministic-only embeddings may fail probe quality; keep optional + CI uses deterministic |

## Implementation Approach (for `/speckit.tasks`)

1. **Contracts 0.3.0**: Add ingest Zod/OpenAPI; add optional/required `version` on `RetrievedChunk`; extend RAG error codes (`UNSUPPORTED_FORMAT`, `NO_CONTENT`, `PROVIDER_ERROR`); document versioning bump.
2. **Provider interfaces**: `EmbeddingProvider` + `VectorStore` with memory/deterministic implementations for tests; local JSON persistence for `pnpm dev`.
3. **Pipeline**: Markdown + PDF parsers, normalize, chunk with stable chunk IDs, sync ingest orchestration with per-`documentId` lock and atomic version swap (commit new → drop old).
4. **HTTP**: `POST /v1/ingest` (bytes + metadata); upgrade `POST /v1/retrieve` to query real index; keep `/health`.
5. **Fixtures & probes**: Sample MD/PDF + 10 probe queries for SC-001; document MAX_UPLOAD_BYTES (5 MiB) and format notes.
6. **Backend pin**: Bump contracts dependency; map new error codes if surfaced through chat as UPSTREAM/VALIDATION as appropriate.
7. **Docs**: RAG README + this quickstart; `.env.example` for `DATA_DIR`, `EMBEDDING_PROVIDER`, `PORT`.
8. **Verify**: Isolated `pnpm test` / ingest→retrieve; optional integrated backend→RAG retrieve smoke with ingested corpus.
