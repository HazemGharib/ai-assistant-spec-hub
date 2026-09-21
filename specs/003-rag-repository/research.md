# Research: RAG Repository

**Feature**: `003-rag-repository`  
**Date**: 2026-09-21

All Technical Context unknowns are resolved below. No remaining NEEDS CLARIFICATION.

---

## 1. Embedding provider (local / CI)

**Decision**: Define an internal `EmbeddingProvider` interface (`embed(texts: string[]): Promise<number[][]>` + `dimensions`). Ship two implementations:

| Implementation | When used |
|----------------|-----------|
| `DeterministicEmbeddingProvider` | Default for Vitest/CI; optional `EMBEDDING_PROVIDER=deterministic` |
| `TransformersJsEmbeddingProvider` (`@xenova/transformers`, MiniLM-class model) | Optional local quality via `EMBEDDING_PROVIDER=transformers` |

Default for `pnpm dev` MAY be `deterministic` for zero download friction; document switching to `transformers` for better semantic recall (SC-001). Never call paid embedding APIs in this phase.

**Rationale**: Constitution IV/V require $0 local defaults and swappable providers. Deterministic vectors keep CI offline and reproducible; Transformers.js is free/local when quality matters. Same ingest/retrieve contracts regardless of provider.

**Alternatives considered**:

- OpenAI / Voyage / Bedrock embeddings now — paid or cloud; violates zero-cost default
- Single Transformers-only path — slows CI, flaky first-run downloads
- Skip embeddings / keyword-only BM25 — conflicts with FR-005 and provider-portability story (still implement BM25 later as optional hybrid, out of scope)

---

## 2. Vector store (local)

**Decision**: Internal `VectorStore` interface with:

- `upsert(chunks)`, `deleteByDocumentId(documentId)`, `similaritySearch(vector, limit)` returning scored chunks with metadata
- `MemoryVectorStore` for unit tests / CI isolation
- `SqliteVecVectorStore` (**sqlite-vec** on a SQLite file under `DATA_DIR`, e.g. `./data/rag.sqlite`) as the durable local default for `pnpm dev`

Embeddings remain caller-supplied via `EmbeddingProvider` (the store MUST NOT own embedding generation). Future adapters (OpenSearch, pgvector) implement the same interface without contract changes.

**Rationale**: Spec FR-012 and portability goals favor an explicit vector+metadata store that maps cleanly to OpenSearch/pgvector later. sqlite-vec keeps a single local file, $0 infra, and SQL-shaped filters/deletes without a separate database server. Constitution IX still satisfied (no managed vector DB / Docker OpenSearch for MVP).

**Alternatives considered**:

- Local JSON + in-process cosine — simplest; deferred as durable default in favor of sqlite-vec for stronger portability semantics (retained only if needed as an emergency fallback, not planned)
- Vectra / Chroma / LanceDB — viable; Chroma risks embedding-function coupling; LanceDB comparable but sqlite-vec preferred for SQL familiarity and OpenSearch/pgvector mental model
- Postgres + pgvector now — heavier local ops than needed for Phase 3
- OpenSearch locally via Docker — contradicts local-simple / zero-cost preference for MVP

---

## 3. Ingest HTTP shape

**Decision**: `POST /v1/ingest` accepts **`multipart/form-data`**:

| Part/field | Required | Notes |
|------------|----------|--------|
| `documentId` | yes | Caller-supplied; non-empty string; validated pattern (e.g. `^[a-zA-Z0-9._:/-]{1,128}$`) |
| `source` | yes | Citation metadata only |
| `content` | yes | File upload bytes (Markdown or PDF) |
| `contentType` or filename ext | yes | `text/markdown` / `application/pdf` or `.md` / `.pdf` |
| `title` | no | Optional display title stored on document |

Reject JSON bodies that include a `version` field. Also support a JSON alternative only if needed for tests: `{ documentId, source, contentBase64, mediaType, title? }` — prefer multipart as canonical for operators; Vitest may use base64 JSON helper matching the same Zod domain model.

**Response (200)**: `{ documentId, version, chunkCount, mediaType }` after index is searchable.  
**Errors**: `400 VALIDATION_ERROR`, `400 UNSUPPORTED_FORMAT`, `422 NO_CONTENT`, `409` optional for concurrent lock timeout, `500 PROVIDER_ERROR` / `INTERNAL_ERROR`.

**Rationale**: Clarifications require uploaded bytes + caller `documentId` + no caller version; multipart matches “upload” UX; sync completion matches clarification A.

**Alternatives considered**:

- Filesystem path ingest — rejected in clarification
- Async job + poll — rejected in clarification
- Raw body with only `Content-Type` header — harder to carry `documentId`/`source` without custom headers; multipart is clearer

---

## 4. Retrieve contract compatibility

**Decision**: Keep `POST /v1/retrieve` path and existing request fields. **Add required `version: number` (positive int)** on each `RetrievedChunk` (MINOR bump with coordinated consumer update). Preserve `chunkId`, `documentId`, `text`, `source`, `score`, optional `title`, `pageOrSection`.

**Empty results**: `200` with `chunks: []` **only when the index has zero chunks**. When the index is non-empty, always return up to `limit` results ordered by descending score — **no minimum similarity floor** in this phase (unrelated queries may return low-scoring chunks).

Bump package to **`0.3.0`**. Backend pins `0.3.0` and may ignore `version` in UI citation mapping until wired; field must be present on the wire.

**Rationale**: Spec FR-006/020 and clarifications need version on citations; top-k-without-floor matches clarification (retrieve ranking session) and keeps agent-side filtering flexible.

**Alternatives considered**:

- Put version only on ingest response — insufficient for citation display at retrieve time
- MAJOR break renaming retrieve — unnecessary
- Keep fixture-only retrieve — fails FR-020
- Minimum score cutoff → empty on unrelated queries — rejected in clarification (Option B)
---

## 5. Parsing, chunking, stable chunk IDs

**Decision**:

- **Markdown**: Decode UTF-8; split on ATX headings where present for `pageOrSection` (heading path); otherwise `pageOrSection` null; chunk ~500–800 tokens/chars with overlap (~10–15%).
- **PDF**: OSS text extract (e.g. `pdf-parse`); set `pageOrSection` to page number string when available; same chunker on extracted text. No OCR.
- **Chunk ID**: Deterministic `sha256(`${documentId}:${version}:${ordinal}`).slice(0, 32)` (or full hex). Same inputs → same IDs. Do **not** hash mutable embedding floats into the ID.
- **Empty extractable text**: Fail ingest with `NO_CONTENT` (resolve dual wording in spec edge case toward hard fail).

**Rationale**: Stable IDs per FR-007; page/section honesty per FR-019; NO_CONTENT is testable and avoids empty documents polluting the index.

**Alternatives considered**:

- Content-hash chunk IDs — break when chunker boundaries shift slightly across versions; ordinal-within-version is enough for stability under fixed chunker policy
- OCR — out of scope
- Semantic chunking LLM — paid/complex; rejected

---

## 6. Versioning & atomic replace

**Decision**: `DocumentRegistry` maps `documentId → { version, source, title?, mediaType, updatedAt }`. On ingest:

1. Acquire per-`documentId` in-process mutex (queue concurrent requests).
2. Compute `nextVersion = existing ? existing.version + 1 : 1`.
3. Parse→chunk→embed into a **staging** set keyed by `(documentId, nextVersion)`.
4. Upsert staging into vector store; on success, update registry to `nextVersion` and **delete** vectors for prior version / prior `documentId` active set.
5. On any failure before commit, leave registry and prior vectors unchanged; discard staging.

**Rationale**: Matches clarifications (server versions, drop superseded, sync, fail-safe).

**Alternatives considered**:

- Keep all versions queryable — rejected in clarification
- Caller-supplied version — rejected in clarification
- Soft-delete without physical removal — unnecessary for local MVP size

---

## 7. Operational limits

**Decision**: Document and enforce:

| Limit | Value |
|-------|--------|
| Max upload size | **5 MiB** (`MAX_UPLOAD_BYTES`) |
| Max retrieve `limit` | 20 (existing) |
| Concurrent ingest | Serialized per `documentId`; global optional concurrency soft-cap not required |

Oversize → `VALIDATION_ERROR`. Unsupported media → `UNSUPPORTED_FORMAT`.

**Rationale**: Spec FR-018 deferred numbers; 5 MiB fits local sync PDF/Markdown demos without unbounded memory risk.

---

## 8. Backend / UI impact

**Decision**: Backend pins contracts `0.3.0` and continues calling only retrieve. Ingest is exercised by RAG tests, quickstart curl/`pnpm` scripts, and operators—not by UI. UI unchanged in this phase.

**Rationale**: Ownership map UI → backend → RAG; ingest is knowledge-ops, not chat UX.

**Alternatives considered**:

- Backend proxy for ingest — nice later; not required for Phase 3 DoD
- UI upload UI — out of scope

---

## 9. Observability

**Decision**: Keep structured JSON logs on ingest/retrieve (`boundary`, `route`, `documentId`, `version`, `chunkCount`, `durationMs`, `contractPackageVersion`). Do not log full document bodies or secrets. Provider failures map to `PROVIDER_ERROR` without stack traces in responses.

**Rationale**: Constitution IX local-first observability; security VIII untrusted content.

---

## 10. Retrieve ranking (top-k, no score floor)

**Decision**: `similaritySearch` returns the top `limit` chunks by descending similarity/score. Do **not** apply a minimum score threshold in Phase 3. Normalize scores to 0..1 for the wire when practical. Empty `chunks` array iff the store has no indexed chunks.

**Rationale**: Clarification Option B; avoids brittle thresholds with deterministic embeddings; agent/orchestrator may ignore low scores later.

**Alternatives considered**:

- Hard minimum score → empty on unrelated queries — rejected
- Configurable threshold default-on — deferred; would be additive later via optional request field or config
