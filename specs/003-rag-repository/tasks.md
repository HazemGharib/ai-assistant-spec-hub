# Tasks: RAG Repository

**Input**: Design documents from `/specs/003-rag-repository/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Included — plan Testing section, SC-001–SC-007, and constitution DoD require Vitest coverage for ingest/retrieve/providers without paid cloud.

**Organization**: Tasks grouped by user story. Story labels map to spec.md:

- **US1** = Retrieve relevant chunks with citation metadata (P1) 🎯 MVP
- **US2** = Ingest Markdown and PDF (P1)
- **US3** = Re-ingest and version safely (P2)
- **US4** = Swap embedding/index backends without consumer changes (P2)
- **US5** = Operate RAG in isolation locally (P3)

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: User story label (US1–US5) for story-phase tasks only
- Include exact file paths in descriptions

## Path Conventions

Sibling repos under `/Users/zuka/coding/ai-assistant/`:

```text
ai-assistant-rag/          # PRIMARY
ai-assistant-contracts/    # 0.3.0
ai-assistant-backend/      # pin only
ai-assistant-spec-hub/     # design docs
```

Paths below are relative to that workspace root (e.g. `ai-assistant-rag/src/server.ts`).

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Align package pins, env, and directory scaffolding without changing retrieve behavior yet

- [ ] T001 Bump `ai-assistant-contracts/package.json` version to `0.3.0` and note Phase 3 RAG ingest/retrieve changes in `ai-assistant-contracts/README.md` (link to `ai-assistant-spec-hub/specs/003-rag-repository/contracts/`)
- [ ] T002 [P] Pin `"@hazemgharib/ai-agent-contracts": "0.3.0"` (or documented `file:../ai-assistant-contracts`) in `ai-assistant-rag/package.json` and `ai-assistant-backend/package.json`
- [ ] T003 [P] Extend `ai-assistant-rag/.env.example` with `PORT`, `DATA_DIR`, `SQLITE_PATH` (default `$DATA_DIR/rag.sqlite`), `VECTOR_STORE` (`sqlite` \| `memory`), `EMBEDDING_PROVIDER`, `MAX_UPLOAD_BYTES` (no secrets)
- [ ] T004 [P] Create directory placeholders `ai-assistant-rag/src/pipeline/.gitkeep`, `ai-assistant-rag/src/providers/embedding/.gitkeep`, `ai-assistant-rag/src/providers/vector/.gitkeep`, `ai-assistant-rag/src/store/.gitkeep`, `ai-assistant-rag/fixtures/.gitkeep` and add `data/` plus `*.sqlite` / `*.sqlite-*` to `ai-assistant-rag/.gitignore`
- [ ] T005 [P] Add OSS PDF dependency (e.g. `pdf-parse`) plus **sqlite-vec** and SQLite driver (e.g. `better-sqlite3` + `@types/better-sqlite3`) to `ai-assistant-rag/package.json` (do not wire routes yet)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Contracts 0.3.0 + provider interfaces + config/registry — MUST complete before ANY user story

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T006 Implement ingest Zod schemas (`IngestRequestJson`, `IngestResult`, ingest error codes) in `ai-assistant-contracts/src/ingest/index.ts` from `ai-assistant-spec-hub/specs/003-rag-repository/contracts/backend-rag-ingest.openapi.yaml`
- [ ] T007 Extend retrieve schemas: require `version` on `RetrievedChunk`; add `PROVIDER_ERROR` (and share ingest codes as needed) in `ai-assistant-contracts/src/retrieve/index.ts` per `ai-assistant-spec-hub/specs/003-rag-repository/contracts/backend-rag-retrieve.openapi.yaml`
- [ ] T008 Export ingest + updated retrieve symbols and bump `CONTRACT_PACKAGE_VERSION` to `0.3.0` in `ai-assistant-contracts/src/index.ts`
- [ ] T009 [P] Add schema tests for ingest + `RetrievedChunk.version` in `ai-assistant-contracts/src/ingest/ingest.test.ts` and `ai-assistant-contracts/src/retrieve/retrieve.test.ts` (or extend existing retrieve tests)
- [ ] T010 Build contracts (`pnpm build` in `ai-assistant-contracts/`) and reinstall so `ai-assistant-rag` / `ai-assistant-backend` resolve `0.3.0` types
- [ ] T011 Implement `ai-assistant-rag/src/config.ts` reading `PORT`, `DATA_DIR`, `SQLITE_PATH`, `VECTOR_STORE` (`sqlite` default for dev; `memory` for tests), `EMBEDDING_PROVIDER` (`deterministic` default), `MAX_UPLOAD_BYTES` (default 5242880)
- [ ] T012 [P] Define `EmbeddingProvider` interface in `ai-assistant-rag/src/providers/embedding/types.ts`
- [ ] T013 [P] Define `VectorStore` interface in `ai-assistant-rag/src/providers/vector/types.ts`
- [ ] T014 Implement `DeterministicEmbeddingProvider` in `ai-assistant-rag/src/providers/embedding/deterministic.ts`
- [ ] T015 [P] Implement `MemoryVectorStore` in `ai-assistant-rag/src/providers/vector/memory.ts`
- [ ] T016 [P] Implement `SqliteVecVectorStore` in `ai-assistant-rag/src/providers/vector/sqliteVec.ts` (sqlite-vec; DB path from `SQLITE_PATH` / `DATA_DIR`; store MUST NOT own embedding generation)
- [ ] T017 Implement `DocumentRegistry` in `ai-assistant-rag/src/store/documentRegistry.ts` (`documentId` → active version metadata; prefer same SQLite DB as vectors)
- [ ] T018 Wire provider factory (select embedding + vector store from config) in `ai-assistant-rag/src/providers/createProviders.ts`
- [ ] T019 [P] Add unit tests for deterministic embed + memory vector similarity in `ai-assistant-rag/src/providers/embedding/deterministic.test.ts` and `ai-assistant-rag/src/providers/vector/memory.test.ts`; add sqlite-vec smoke against a temp DB in `ai-assistant-rag/src/providers/vector/sqliteVec.test.ts`

**Checkpoint**: Contracts `0.3.0` builds; RAG has config + provider interfaces + registry — story work can start

---

## Phase 3: User Story 1 - Retrieve Relevant Chunks (Priority: P1) 🎯 MVP

**Goal**: Backend/agent can `POST /v1/retrieve` and get ranked chunks with `documentId`, `source`, `version`, `chunkId`, optional `pageOrSection` from a real index (not hard-coded fixture-only behavior). Top-`limit` by score with **no minimum score floor**; `chunks: []` only when the index is empty.

**Independent Test**: Seed a small corpus via test helper into `MemoryVectorStore` + registry; call retrieve; assert citation fields, limit ordering, empty-index → `chunks: []`, and non-empty index + unrelated query still returns top-`limit`

### Tests for User Story 1

> Write these tests FIRST; ensure they FAIL before implementation

- [ ] T020 [P] [US1] Add retrieve contract/route tests (seeded index, empty index → [], unrelated query still returns top-k, validation, limit) in `ai-assistant-rag/src/routes/retrieve.test.ts`
- [ ] T021 [P] [US1] Add retrieve service unit tests for score ordering + metadata mapping in `ai-assistant-rag/src/pipeline/retrieve.test.ts`

### Implementation for User Story 1

- [ ] T022 [US1] Implement retrieve orchestration (embed query → vector search top-`limit` with no score floor → map `RetrievedChunk` including `version`; empty only if index empty) in `ai-assistant-rag/src/pipeline/retrieve.ts`
- [ ] T023 [US1] Replace fixture-only handler with real retrieve in `ai-assistant-rag/src/routes/retrieve.ts` using providers from `createProviders.ts`
- [ ] T024 [US1] Ensure `/health` still works and structured logs include `boundary`, `route`, `chunkCount`, `durationMs`, `contractPackageVersion` in `ai-assistant-rag/src/routes/retrieve.ts` / `ai-assistant-rag/src/server.ts`
- [ ] T025 [US1] Add test-only seed helper for pre-indexed chunks in `ai-assistant-rag/src/test/seedIndex.ts` used by retrieve tests
- [ ] T026 [US1] Update backend pin usage: ensure `ai-assistant-backend/src/clients/ragClient.ts` typechecks against `RetrievedChunk.version` (map/ignore as needed; no behavior break)

**Checkpoint**: Retrieve returns real indexed chunks with full citation metadata — MVP when seeded

---

## Phase 4: User Story 2 - Ingest Markdown and PDF (Priority: P1)

**Goal**: Sync `POST /v1/ingest` accepts caller `documentId`, `source`, and MD/PDF bytes; indexes chunks available immediately for retrieve

**Independent Test**: Ingest fixture Markdown + PDF; retrieve with content-derived queries; reject unsupported format / missing documentId / oversize / NO_CONTENT

### Tests for User Story 2

- [ ] T027 [P] [US2] Add ingest route tests (MD success, validation, unsupported format, NO_CONTENT, forbidden `version` field) in `ai-assistant-rag/src/routes/ingest.test.ts`
- [ ] T028 [P] [US2] Add parse/normalize/chunk unit tests in `ai-assistant-rag/src/pipeline/parseMarkdown.test.ts`, `ai-assistant-rag/src/pipeline/parsePdf.test.ts`, `ai-assistant-rag/src/pipeline/chunk.test.ts`

### Implementation for User Story 2

- [ ] T029 [P] [US2] Implement Markdown parse + section locators in `ai-assistant-rag/src/pipeline/parseMarkdown.ts`
- [ ] T030 [P] [US2] Implement PDF text extract + page locators in `ai-assistant-rag/src/pipeline/parsePdf.ts`
- [ ] T031 [P] [US2] Implement normalize in `ai-assistant-rag/src/pipeline/normalize.ts`
- [ ] T032 [US2] Implement chunker with stable `chunkId` (`documentId:version:ordinal` hash) in `ai-assistant-rag/src/pipeline/chunk.ts`
- [ ] T033 [US2] Implement sync `ingestDocument` orchestration (parse→chunk→embed→upsert→registry) in `ai-assistant-rag/src/pipeline/ingestDocument.ts`
- [ ] T034 [US2] Implement `POST /v1/ingest` (multipart + JSON base64) in `ai-assistant-rag/src/routes/ingest.ts` with 5 MiB limit and forbidden `version` field
- [ ] T035 [US2] Register ingest route in `ai-assistant-rag/src/server.ts`
- [ ] T036 [US2] Add fixture files `ai-assistant-rag/fixtures/refund.md` and `ai-assistant-rag/fixtures/handbook.pdf` (small) plus probe list `ai-assistant-rag/fixtures/probes.json` for SC-001
- [ ] T037 [US2] Add ingest→retrieve integration test using fixtures in `ai-assistant-rag/src/pipeline/ingestRetrieve.integration.test.ts`

**Checkpoint**: Operator can ingest MD/PDF and retrieve citations without fixtures hard-coded in retrieve handler

---

## Phase 5: User Story 3 - Re-ingest and Version Safely (Priority: P2)

**Goal**: Re-ingest same `documentId` assigns `version+1`, drops superseded chunks, keeps prior version on failure; per-document lock

**Independent Test**: Ingest v1 → retrieve; ingest v2 → only v2 returned; force mid-pipeline failure → v1 still retrievable

### Tests for User Story 3

- [ ] T038 [P] [US3] Add versioning/re-ingest tests (bump, drop old, fail-safe) in `ai-assistant-rag/src/pipeline/ingestDocument.versioning.test.ts`
- [ ] T039 [P] [US3] Add concurrent same-`documentId` ingest serialization test in `ai-assistant-rag/src/pipeline/ingestDocument.concurrency.test.ts`

### Implementation for User Story 3

- [ ] T040 [US3] Add per-`documentId` mutex/queue in `ai-assistant-rag/src/store/documentLocks.ts` and use it from `ai-assistant-rag/src/pipeline/ingestDocument.ts`
- [ ] T041 [US3] Implement atomic commit: staging upsert → registry update → `deleteByDocumentId` for superseded vectors in `ai-assistant-rag/src/pipeline/ingestDocument.ts` / `ai-assistant-rag/src/providers/vector/*`
- [ ] T042 [US3] Ensure failed ingest before commit leaves registry + vectors unchanged; map errors to contract codes in `ai-assistant-rag/src/routes/ingest.ts`
- [ ] T043 [US3] Reject caller-supplied `version` on ingest with `VALIDATION_ERROR` in `ai-assistant-rag/src/routes/ingest.ts` (and Zod refine in contracts if not already)

**Checkpoint**: Safe re-ingest with server versions and no mixed active chunks

---

## Phase 6: User Story 4 - Swap Embedding/Index Backends (Priority: P2)

**Goal**: Alternate embedding or vector implementations selectable via config; same ingest/retrieve contracts

**Independent Test**: Run same ingest+retrieve suite with deterministic+memory vs deterministic+sqlite-vec (and/or alternate embedding stub); assert identical response shapes

### Tests for User Story 4

- [ ] T044 [P] [US4] Add provider-swap contract shape test (MemoryVectorStore vs SqliteVecVectorStore) in `ai-assistant-rag/src/providers/providerSwap.test.ts`
- [ ] T045 [P] [US4] Add provider failure mapping test (`PROVIDER_ERROR`, no secrets/stacks in body) in `ai-assistant-rag/src/routes/providerErrors.test.ts`

### Implementation for User Story 4

- [ ] T046 [US4] Implement optional `TransformersJsEmbeddingProvider` in `ai-assistant-rag/src/providers/embedding/transformers.ts` behind `EMBEDDING_PROVIDER=transformers` (lazy import; document as optional)
- [ ] T047 [US4] Ensure `createProviders.ts` selects embedding/vector by env without changing route handlers in `ai-assistant-rag/src/routes/ingest.ts` / `retrieve.ts`
- [ ] T048 [US4] Add a second lightweight embedding stub (e.g. alternate hash seed) `ai-assistant-rag/src/providers/embedding/deterministicAlt.ts` for swap tests only if transformers too heavy for CI
- [ ] T049 [US4] Document provider swap and portability targets (sqlite-vec local → Bedrock/OpenSearch later) in `ai-assistant-rag/README.md`

**Checkpoint**: Consumers unchanged when providers swap; CI remains deterministic/offline

---

## Phase 7: User Story 5 - Operate RAG in Isolation (Priority: P3)

**Goal**: Developer runs only `ai-assistant-rag` locally: install, ingest fixtures, retrieve, tests pass without siblings/paid cloud

**Independent Test**: Follow quickstart against running RAG alone; `pnpm test` green without AWS credentials

### Tests for User Story 5

- [ ] T050 [P] [US5] Add smoke script or documented curl checklist helper `ai-assistant-rag/scripts/smoke-ingest-retrieve.mjs` (optional; or Vitest smoke using app fetch)

### Implementation for User Story 5

- [ ] T051 [US5] Update `ai-assistant-rag/README.md` with isolated setup, limits (5 MiB), formats, OCR out of scope, sqlite-vec path, top-k retrieve notes, and link to `ai-assistant-spec-hub/specs/003-rag-repository/quickstart.md`
- [ ] T052 [US5] Align `ai-assistant-spec-hub/specs/003-rag-repository/quickstart.md` with final env var names and example commands
- [ ] T053 [US5] Verify CI workflow `ai-assistant-rag/.github/workflows/ci.yml` runs `pnpm test` / lint / typecheck with `EMBEDDING_PROVIDER=deterministic` and `VECTOR_STORE=memory` (or temp sqlite), no paid secrets
- [ ] T054 [US5] Confirm backend still fakes RAG when `RAG_BASE_URL` unset in `ai-assistant-backend/src/clients/ragClient.ts` (isolated backend suite green)

**Checkpoint**: RAG-only local demo + CI satisfy SC-004/SC-006

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Quality bar across stories

- [ ] T055 [P] Add SC-001 probe evaluation test (≥90% of `fixtures/probes.json` hit expected passages) in `ai-assistant-rag/src/evaluation/probes.test.ts`
- [ ] T056 [P] Review structured logging for ingest (no full bodies/secrets) in `ai-assistant-rag/src/routes/ingest.ts`
- [ ] T057 Security pass: confirm retrieved text treated as untrusted at boundary; error responses omit stacks in `ai-assistant-rag/src/routes/*.ts`
- [ ] T058 Run full quickstart validation (ingest MD+PDF, re-ingest, retrieve top-k / empty-index) against `pnpm dev` and record any doc fixes in `ai-assistant-rag/README.md`
- [ ] T059 [P] Copy/sync final OpenAPI from implementation notes back to `ai-assistant-spec-hub/specs/003-rag-repository/contracts/` if wire details drifted
- [ ] T060 Ensure `ai-assistant-backend/package.json` remains on contracts `0.3.0` and `pnpm typecheck` passes after `RetrievedChunk.version`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup — **BLOCKS** all user stories
- **US1 (Phase 3)**: After Foundational — MVP retrieve from seeded index
- **US2 (Phase 4)**: After Foundational; practically after US1 retrieve wiring (ingest feeds the same index) — parsers can start in parallel with US1 once providers exist
- **US3 (Phase 5)**: Depends on US2 ingest orchestration
- **US4 (Phase 6)**: Depends on Foundational providers; best after US2 so swap tests cover ingest+retrieve
- **US5 (Phase 7)**: After US2 (docs/smoke); can overlap polish
- **Polish (Phase 8)**: After desired stories complete

### User Story Dependencies

```text
Phase 2 Foundational
        ├── US1 Retrieve (seeded) ──┐
        ├── US2 Ingest ─────────────┼── US3 Versioning
        │                           └── US4 Provider swap (also needs US2 for full suite)
        └── US5 Isolation docs/CI (after US2)
```

- **US1**: No dependency on ingest HTTP — uses seed helper; top-k / empty-index rules apply
- **US2**: Uses same VectorStore/registry as US1
- **US3**: Extends US2 `ingestDocument`
- **US4**: Config/provider factory; Memory vs sqlite-vec
- **US5**: Documentation + CI verification

### Parallel Opportunities

- T002–T005 (setup) in parallel
- T012–T013, T015–T016, T019 (provider interfaces/impls) in parallel after types
- T020–T021 (US1 tests) in parallel
- T027–T031 (US2 tests + parsers) in parallel
- T038–T039 (US3 tests) in parallel
- T044–T045 (US4 tests) in parallel
- After Foundational: Dev A → US1, Dev B → US2 parsers (T029–T032), then merge for ingest route

---

## Parallel Example: User Story 1

```bash
Task: "Add retrieve route tests in ai-assistant-rag/src/routes/retrieve.test.ts"
Task: "Add retrieve pipeline tests in ai-assistant-rag/src/pipeline/retrieve.test.ts"
```

---

## Parallel Example: User Story 2

```bash
Task: "Add ingest route tests in ai-assistant-rag/src/routes/ingest.test.ts"
Task: "Implement parseMarkdown.ts"
Task: "Implement parsePdf.ts"
Task: "Implement normalize.ts"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL)
3. Complete Phase 3: US1 Retrieve (seeded index, top-k semantics)
4. **STOP and VALIDATE**: Retrieve citations from seeded corpus
5. Demo MVP retrieve path

### Incremental Delivery

1. Setup + Foundational → providers + contracts ready
2. US1 → retrieve MVP
3. US2 → real ingest MD/PDF into sqlite-vec
4. US3 → safe versioning
5. US4 → provider portability proof (memory ↔ sqlite-vec)
6. US5 + Polish → isolated DoD / probes / docs

### Parallel Team Strategy

1. Team completes Setup + Foundational together
2. Then:
   - Dev A: US1 retrieve
   - Dev B: US2 parsers + chunker
   - Dev C: contracts tests / backend pin (T026/T060)
3. Merge for ingest route + US3/US4

---

## Notes

- [P] = different files, no unmet dependencies
- [Story] labels US1–US5 only on story-phase tasks
- Durable local vector store: **sqlite-vec** (`SqliteVecVectorStore`); tests/CI prefer `VECTOR_STORE=memory`
- Retrieve: top-`limit` by score, **no min score floor**; empty `chunks` only if index empty
- CI MUST use `EMBEDDING_PROVIDER=deterministic` (no model download)
- Do not commit `ai-assistant-rag/data/` or `*.sqlite` or secrets
- Prefer failing tests before implementation for story test tasks
- Suggested MVP scope: **US1** (seeded retrieve); product-useful MVP: **US1 + US2**
