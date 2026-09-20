# Data Model: RAG Repository

**Feature**: `003-rag-repository`  
**Date**: 2026-09-21  
**Source of truth for wire shapes**: `@hazemgharib/ai-agent-contracts` ≥ `0.3.0` (see `contracts/`)

Internal persistence lives only in `ai-assistant-rag` (`DocumentRegistry` + `VectorStore`). Consumers see ingest/retrieve DTOs only.

---

## Entities

### Document (registry)

| Field | Type | Rules |
|-------|------|--------|
| `documentId` | string | Required; caller-supplied; unique; pattern `^[a-zA-Z0-9._:/-]{1,128}$` |
| `source` | string | Required; opaque citation label (path/URI/name); not used to read files |
| `title` | string \| null | Optional |
| `mediaType` | `text/markdown` \| `application/pdf` | Required after successful ingest |
| `version` | positive integer | Server-assigned; active version only |
| `updatedAt` | ISO-8601 datetime | Updated on each successful ingest |
| `chunkCount` | non-negative integer | Chunks in active version |

**Relationships**: Has exactly one **active** `DocumentVersion` in the index after success.

**Lifecycle**:

```text
[none] --ingest(documentId)--> active(v1)
active(vN) --ingest same id--> staging(vN+1) --commit--> active(vN+1); drop vN
active(vN) --ingest fail--> active(vN) unchanged
```

---

### DocumentVersion (logical; only active retained)

| Field | Type | Rules |
|-------|------|--------|
| `documentId` | string | Required |
| `version` | positive integer | 1 on first success; +1 each successful re-ingest |
| `chunks` | Chunk[] | Required; length ≥ 1 (empty → ingest `NO_CONTENT`) |

**Validation**: Callers MUST NOT supply `version` on ingest. Historical versions are not queryable after commit.

---

### Chunk (indexed)

| Field | Type | Rules |
|-------|------|--------|
| `chunkId` | string | Required; deterministic from `documentId`, `version`, ordinal |
| `documentId` | string | Required |
| `version` | positive integer | Required; matches active document version |
| `text` | string | Required; normalized plain text; minLength 1 |
| `source` | string | Required; copied from document |
| `title` | string \| null | Optional; from document |
| `pageOrSection` | string \| null | Page number or Markdown heading path; null if unknown — never fabricated |
| `ordinal` | non-negative integer | Chunk order within version |
| `embedding` | number[] | Required at index time; dimension fixed per embedding provider |

**Relationships**: Belongs to one DocumentVersion; returned by retrieve as `RetrievedChunk` (without raw embedding).

---

### RetrievedChunk (wire DTO)

| Field | Type | Rules |
|-------|------|--------|
| `chunkId` | string | Required |
| `documentId` | string | Required |
| `version` | positive integer | Required (new in 0.3.0) |
| `text` | string | Required; treat as untrusted |
| `source` | string | Required |
| `score` | number | Required; 0..1 relevance (normalized cosine or rank score) |
| `title` | string \| null | Optional |
| `pageOrSection` | string \| null | Optional |

---

### RetrieveQuery (wire)

| Field | Type | Rules |
|-------|------|--------|
| `query` | string | Required; minLength 1 after trim |
| `limit` | integer | Optional; default 5; min 1; max 20 |
| `conversationId` | UUID \| null | Optional; unused by RAG ranking in this phase (pass-through / ignored) |

---

### IngestRequest (domain / wire)

| Field | Type | Rules |
|-------|------|--------|
| `documentId` | string | Required |
| `source` | string | Required; minLength 1 |
| `content` | bytes | Required; max 5 MiB |
| `mediaType` | enum | Required; markdown or pdf |
| `title` | string \| null | Optional |
| `version` | — | **Forbidden**; reject if present |

---

### IngestResult (wire)

| Field | Type | Rules |
|-------|------|--------|
| `documentId` | string | Echo |
| `version` | positive integer | Server-assigned |
| `chunkCount` | positive integer | ≥ 1 |
| `mediaType` | enum | As ingested |

---

## Provider boundaries (not wire entities)

### EmbeddingProvider

- `dimensions: number`
- `embed(texts: string[]): Promise<number[][]>`
- Failures → ingest/retrieve `PROVIDER_ERROR`

### VectorStore

- `upsert(chunks: Chunk[]): Promise<void>`
- `deleteByDocumentId(documentId: string): Promise<void>`
- `similaritySearch(queryEmbedding: number[], limit: number): Promise<Array<Chunk & { score: number }>>`
- Implementations MUST NOT leak into contracts package

---

## Validation summary

| Rule | Outcome |
|------|---------|
| Missing/invalid `documentId` | `VALIDATION_ERROR` |
| Missing `source` / empty query | `VALIDATION_ERROR` |
| Upload &gt; 5 MiB | `VALIDATION_ERROR` |
| Unsupported media type | `UNSUPPORTED_FORMAT` |
| No extractable text | `NO_CONTENT` |
| `version` field on ingest | `VALIDATION_ERROR` |
| Embedding/index failure | `PROVIDER_ERROR` or `INTERNAL_ERROR` |
| Corrupt PDF | `NO_CONTENT` or `VALIDATION_ERROR` with clear message; prior version kept |

---

## State transitions (ingest)

```text
                    ┌──────────────┐
                    │ lock(docId)  │
                    └──────┬───────┘
                           ▼
                    parse + normalize
                           ▼
                      chunk (stable IDs)
                           ▼
                         embed
                           ▼
                    upsert staging vectors
                           ▼
              update registry (commit version)
                           ▼
                 delete superseded vectors
                           ▼
                    unlock; return 200
```

Any step failure before registry commit → unlock; prior active state unchanged.
