# Quickstart: RAG Repository (Phase 3)

Local-first guide for real document ingest + retrieval in `ai-assistant-rag`. **$0** — no AWS, Bedrock, or OpenSearch required.

## What this phase delivers

- Sync ingest of **Markdown** and **PDF** bytes (`POST /v1/ingest`)
- Retrieve grounded chunks with citation metadata including **version** (`POST /v1/retrieve`)
- Embedding + vector store behind swappable providers (deterministic CI default; optional Transformers.js; **sqlite-vec** durable local index)
- Contracts package **`@hazemgharib/ai-agent-contracts@0.3.0`**

## Prerequisites

- Node.js 22+
- pnpm 10+
- Sibling checkouts:

```text
ai-assistant/
  ai-assistant-spec-hub/
  ai-assistant-contracts/   # bump to 0.3.0
  ai-assistant-rag/         # implement pipeline
  ai-assistant-backend/     # pin 0.3.0 (retrieve client)
```

## Contracts package

```bash
cd ai-assistant-contracts
# implement ingest + RetrievedChunk.version per specs/003-rag-repository/contracts/
pnpm build
# publish or local link per Phase 1 docs

cd ../ai-assistant-rag && pnpm install   # pin 0.3.0
cd ../ai-assistant-backend && pnpm install
```

## Isolated RAG (no UI/MCP required)

```bash
cd ai-assistant-rag
pnpm install
cp -n .env.example .env   # PORT=3002, DATA_DIR=./data, SQLITE_PATH=./data/rag.sqlite, VECTOR_STORE=sqlite, EMBEDDING_PROVIDER=deterministic
pnpm test                 # uses VECTOR_STORE=memory (or temp sqlite) — no paid cloud
pnpm dev                  # creates ./data/rag.sqlite on first ingest if missing
```

First ingest creates the SQLite database under `DATA_DIR` (gitignored). CI MUST prefer `VECTOR_STORE=memory` or an ephemeral temp path so native sqlite-vec still runs offline without AWS.

### Health

```bash
curl -s http://127.0.0.1:3002/health
```

### Ingest Markdown (multipart)

```bash
curl -s -X POST http://127.0.0.1:3002/v1/ingest \
  -F 'documentId=demo/refund-policy' \
  -F 'source=fixtures/refund.md' \
  -F 'title=Refund Policy' \
  -F 'content=@fixtures/refund.md;type=text/markdown'
```

### Ingest PDF

```bash
curl -s -X POST http://127.0.0.1:3002/v1/ingest \
  -F 'documentId=demo/handbook' \
  -F 'source=fixtures/handbook.pdf' \
  -F 'content=@fixtures/handbook.pdf;type=application/pdf'
```

### Retrieve

```bash
curl -s -X POST http://127.0.0.1:3002/v1/retrieve \
  -H 'content-type: application/json' \
  -d '{"query":"refund within 30 days","limit":5}'
```

Expect chunks with `documentId`, `source`, `version`, `chunkId`, and optional `pageOrSection`.
Against a non-empty index, unrelated queries still return up to `limit` chunks (scores may be low). Empty `chunks` only before any successful ingest (or after wiping the DB).

### Re-ingest (version bump)

Repeat ingest with the same `documentId` and updated bytes. Response `version` increments; retrieve cites the new version only.

## Optional better local embeddings

```bash
# .env
EMBEDDING_PROVIDER=transformers
```

First run may download a local model into the cache under `DATA_DIR` (gitignored). CI MUST keep `deterministic`.

## Limits (documented)

| Limit | Value |
|-------|--------|
| Max upload | 5 MiB |
| Formats | `text/markdown`, `application/pdf` |
| Vector store (local) | sqlite-vec SQLite file (`VECTOR_STORE=sqlite`); `memory` for tests |
| OCR | Not supported |
| Auth | None (localhost trust) |

## Integrated smoke (backend → RAG)

```bash
# Terminal A
cd ai-assistant-rag && pnpm dev

# Terminal B — ingest fixtures (above), then:
cd ai-assistant-backend
RAG_BASE_URL=http://127.0.0.1:3002 pnpm dev
# Exercise chat/orchestration path that calls retrieve
```

## Verify checklist

- [ ] `pnpm test` in `ai-assistant-rag` passes without paid credentials
- [ ] Ingest MD + PDF then retrieve returns citation metadata including `version`
- [ ] Failed ingest leaves prior version retrievable
- [ ] Re-ingest drops superseded chunks from results
- [ ] Backend pinned to contracts `0.3.0` typechecks against `RetrievedChunk.version`
