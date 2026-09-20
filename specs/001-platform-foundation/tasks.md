# Tasks: Platform Foundation & Repository Contracts

**Input**: Design documents from `/specs/001-platform-foundation/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Included — spec requires isolated automated suites (FR-009, SC-003) and contract schema validation without paid cloud.

**Organization**: Tasks grouped by user story. Story labels map to spec.md:

- **US1** = Ownership map (P1)
- **US2** = Isolated run/test (P1)
- **US3** = Integrated smoke path (spec User Story 2b, P1)
- **US4** = Explicit contracts integration (spec User Story 3, P1)
- **US5** = Engineering standards (spec User Story 4, P2)
- **US6** = Environment configuration (spec User Story 5, P2)

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: User story label (US1–US6) for story-phase tasks only
- Include exact file paths in descriptions

## Path Conventions

All new/adapted repos are siblings under `/Users/zuka/coding/ai-assistant/`:

```text
ai-assistant-ui/
ai-assistant-contracts/
ai-assistant-backend/
ai-assistant-rag/
ai-assistant-mcp/
ai-assistant-spec-hub/   # this repo (docs only for most tasks)
```

Paths below are relative to that workspace root (e.g. `ai-assistant-contracts/src/index.ts`).

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create sibling repositories and workspace wiring so implementation has a place to land

- [ ] T001 Create sibling git repositories `ai-assistant-contracts`, `ai-assistant-backend`, `ai-assistant-rag`, and `ai-assistant-mcp` under `/Users/zuka/coding/ai-assistant/` (init git, default branch, empty README placeholders)
- [ ] T002 Update `/Users/zuka/coding/ai-assistant/ai-assistant.code-workspace` to include all six folders (`spec-hub`, `ui`, `contracts`, `backend`, `rag`, `mcp`)
- [ ] T003 [P] Add root-level `.gitignore` patterns for secrets (`.env`, `*.pem`, `*.tgz` optional) in each new repo: `ai-assistant-contracts/.gitignore`, `ai-assistant-backend/.gitignore`, `ai-assistant-rag/.gitignore`, `ai-assistant-mcp/.gitignore`
- [ ] T004 [P] Copy design contract sources note into `ai-assistant-contracts/README.md` linking to `ai-assistant-spec-hub/specs/001-platform-foundation/contracts/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Contracts package + TypeScript baselines for all runtime repos — MUST complete before story implementation

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T005 Initialize `ai-assistant-contracts/package.json` as `@ai-assistant/contracts@0.1.0` with pnpm, TypeScript, Vitest, oxlint, Prettier, Zod; scripts `build`, `test`, `lint`, `typecheck`, `format`, `format:check`
- [ ] T006 Implement chat Zod schemas/types from `ai-assistant-spec-hub/specs/001-platform-foundation/contracts/ui-backend-chat.openapi.yaml` in `ai-assistant-contracts/src/chat/index.ts`
- [ ] T007 [P] Implement retrieve Zod schemas/types from `ai-assistant-spec-hub/specs/001-platform-foundation/contracts/backend-rag-retrieve.openapi.yaml` in `ai-assistant-contracts/src/retrieve/index.ts`
- [ ] T008 [P] Implement MCP `smoke_ping` schemas/descriptors from `ai-assistant-spec-hub/specs/001-platform-foundation/contracts/backend-mcp-capabilities.md` in `ai-assistant-contracts/src/mcp/index.ts`
- [ ] T009 Export package barrel and `CONTRACT_PACKAGE_VERSION` constant in `ai-assistant-contracts/src/index.ts`; configure `ai-assistant-contracts/tsconfig.json` + package `exports`
- [ ] T010 Add failing-then-passing schema tests in `ai-assistant-contracts/src/chat/chat.test.ts`, `ai-assistant-contracts/src/retrieve/retrieve.test.ts`, `ai-assistant-contracts/src/mcp/mcp.test.ts`
- [ ] T011 Scaffold `ai-assistant-backend/package.json` (pnpm, TypeScript, Hono, Vitest, oxlint, Prettier, Zod) with scripts `dev`, `build`, `test`, `lint`, `typecheck`, `format`, `format:check` and dependency `"@ai-assistant/contracts": "file:../ai-assistant-contracts"`
- [ ] T012 [P] Scaffold `ai-assistant-rag/package.json` with same baseline scripts/tooling and `"@ai-assistant/contracts": "file:../ai-assistant-contracts"`
- [ ] T013 [P] Scaffold `ai-assistant-mcp/package.json` with same baseline scripts/tooling, `@modelcontextprotocol/sdk`, and `"@ai-assistant/contracts": "file:../ai-assistant-contracts"`
- [ ] T014 Align `ai-assistant-ui/package.json` scripts to add `test`, `typecheck`, `format`, `format:check`; add Vitest + Prettier; add `"@ai-assistant/contracts": "file:../ai-assistant-contracts"`
- [ ] T015 [P] Add shared tsconfig baselines: `ai-assistant-backend/tsconfig.json`, `ai-assistant-rag/tsconfig.json`, `ai-assistant-mcp/tsconfig.json`, `ai-assistant-contracts/tsconfig.json` (strict; NodeNext or bundler as appropriate)
- [ ] T016 Document contracts install/version pin steps in `ai-assistant-contracts/README.md` per `ai-assistant-spec-hub/specs/001-platform-foundation/contracts/versioning.md`

**Checkpoint**: `@ai-assistant/contracts` builds/tests; four runtime repos exist with tooling + file: dependency — story work can start

---

## Phase 3: User Story 1 - Establish Clear Repository Ownership Map (Priority: P1) 🎯 MVP

**Goal**: Contributors can see what each repo owns/does not own and how boundaries connect without reading implementation code

**Independent Test**: Using only ownership docs + READMEs, correctly assign 5 sample changes to owning repos (SC-001)

### Implementation for User Story 1

- [ ] T017 [US1] Write platform ownership map at `ai-assistant-spec-hub/overall-context/ownership.md` (table of repos, in/out of scope, inbound/outbound contracts, ports)
- [ ] T018 [P] [US1] Add ownership section to `ai-assistant-ui/README.md` linking to `ownership.md` and stating UI non-ownership of agent/RAG/MCP
- [ ] T019 [P] [US1] Add ownership section to `ai-assistant-backend/README.md` (orchestration owns; index/tool-server do not)
- [ ] T020 [P] [US1] Add ownership section to `ai-assistant-rag/README.md`
- [ ] T021 [P] [US1] Add ownership section to `ai-assistant-mcp/README.md`
- [ ] T022 [P] [US1] Add ownership section to `ai-assistant-contracts/README.md` (schemas only; no runtime behavior)
- [ ] T023 [US1] Add “Ownership” link from `ai-assistant-spec-hub/specs/001-platform-foundation/quickstart.md` to `overall-context/ownership.md`
- [ ] T024 [US1] Add 5 sample change-request quiz answers appendix in `ai-assistant-spec-hub/overall-context/ownership.md` for SC-001 validation

**Checkpoint**: Ownership map alone answers “which repo owns X?”

---

## Phase 4: User Story 4 - Integrate Only Through Explicit Contracts (Priority: P1)

**Goal**: Providers implement and consumers use `@ai-assistant/contracts` only — no sibling `src` path imports

**Independent Test**: Audit finds zero internal cross-repo `src` imports; both sides use same package version (SC-004)

### Tests for User Story 4

- [ ] T025 [P] [US4] Add contract validation unit tests for chat request/response parsing in `ai-assistant-backend/src/routes/chat.test.ts`
- [ ] T026 [P] [US4] Add retrieve request validation tests in `ai-assistant-rag/src/routes/retrieve.test.ts`
- [ ] T027 [P] [US4] Add `smoke_ping` input validation tests in `ai-assistant-mcp/src/tools/smokePing.test.ts`

### Implementation for User Story 4

- [ ] T028 [US4] Implement RAG `GET /health` and `POST /v1/retrieve` with Zod from contracts in `ai-assistant-rag/src/server.ts` and `ai-assistant-rag/src/routes/retrieve.ts` (fixture chunks OK)
- [ ] T029 [US4] Implement MCP server registering `smoke_ping` in `ai-assistant-mcp/src/server.ts` and `ai-assistant-mcp/src/tools/smokePing.ts` using contracts schemas
- [ ] T030 [US4] Implement backend `GET /health` echoing `contractPackageVersion` in `ai-assistant-backend/src/server.ts`
- [ ] T031 [US4] Implement `ai-assistant-backend/src/clients/ragClient.ts` calling RAG `/v1/retrieve` with contracts types; map failures to `UPSTREAM_UNAVAILABLE`
- [ ] T032 [US4] Implement `ai-assistant-backend/src/clients/mcpClient.ts` invoking `smoke_ping`; map transport failures to `UPSTREAM_UNAVAILABLE`
- [ ] T033 [US4] Implement `ai-assistant-backend/src/orchestration/stubOrchestrator.ts` deterministic routing to RAG and/or MCP for smoke flags/keywords
- [ ] T034 [US4] Implement `POST /v1/chat` in `ai-assistant-backend/src/routes/chat.ts` returning `ChatResponse` with `diagnostics.hitRag` / `hitMcp` / `contractPackageVersion`
- [ ] T035 [US4] Implement `ai-assistant-ui/src/adapters/httpBackendAdapter.ts` posting to `/v1/chat` using contracts types; select via `VITE_BACKEND_BASE_URL` in `ai-assistant-ui/src/components/RuntimeProvider.tsx`
- [ ] T036 [US4] Keep isolated UI path via `ai-assistant-ui/src/adapters/localAgentAdapter.ts` when `VITE_BACKEND_BASE_URL` unset
- [ ] T037 [US4] Add dependency audit note/script `ai-assistant-spec-hub/specs/001-platform-foundation/scripts/assert-no-src-path-deps.sh` (or doc checklist) verifying no `file:../**/src` consumer deps

**Checkpoint**: All boundaries speak contracts package; providers/consumers typecheck against `@ai-assistant/contracts`

---

## Phase 5: User Story 2 - Run and Test Any Repository in Isolation (Priority: P1)

**Goal**: Each runtime repo install → run → test without siblings or paid cloud

**Independent Test**: For each of ui/backend/rag/mcp, `pnpm test` passes with fakes; `pnpm dev` exposes documented smoke/health (SC-002, SC-003)

### Tests for User Story 2

- [ ] T038 [P] [US2] Ensure backend isolated suite uses MCP/RAG doubles (no live ports) in `ai-assistant-backend/src/orchestration/stubOrchestrator.test.ts`
- [ ] T039 [P] [US2] Add UI adapter unit test for local stub path in `ai-assistant-ui/src/adapters/localAgentAdapter.test.ts`
- [ ] T040 [P] [US2] Add RAG health/retrieve happy-path test without backend in `ai-assistant-rag/src/routes/retrieve.test.ts`
- [ ] T041 [P] [US2] Add MCP tool test without backend in `ai-assistant-mcp/src/tools/smokePing.test.ts`

### Implementation for User Story 2

- [ ] T042 [US2] Wire backend isolated defaults: when `RAG_BASE_URL` / `MCP_SERVER_URL` unset, use in-process fakes in `ai-assistant-backend/src/clients/ragClient.ts` and `ai-assistant-backend/src/clients/mcpClient.ts`
- [ ] T043 [P] [US2] Document isolated run steps in `ai-assistant-backend/README.md`, `ai-assistant-rag/README.md`, `ai-assistant-mcp/README.md`, `ai-assistant-ui/README.md`
- [ ] T044 [US2] Verify each repo `pnpm install && pnpm test && pnpm lint && pnpm typecheck` succeeds from a clean directory without starting siblings; record commands in each README

**Checkpoint**: Four runtime repos + contracts independently green

---

## Phase 6: User Story 3 - Prove One Integrated Local Smoke Path (Priority: P1)

**Goal**: One documented end-to-end path UI → backend → RAG + MCP using contracts

**Independent Test**: Follow quickstart integrated section; `diagnostics.hitRag` and `hitMcp` true within 20 minutes after install (SC-009)

### Tests for User Story 3

- [ ] T045 [US3] Add optional smoke script `ai-assistant-backend/scripts/integrated-smoke.mjs` (or `.ts`) that POSTs `/v1/chat` with `smoke.requireRag` + `requireMcp` and asserts diagnostics (skips if env `SKIP_INTEGRATED_SMOKE=1`)

### Implementation for User Story 3

- [ ] T046 [US3] Ensure stub orchestrator honors `smoke.requireRag` / `requireMcp` in `ai-assistant-backend/src/orchestration/stubOrchestrator.ts` and `ai-assistant-backend/src/routes/chat.ts`
- [ ] T047 [US3] Return clear `ErrorResponse` with `boundary` when RAG or MCP is down during integrated mode in `ai-assistant-backend/src/routes/chat.ts`
- [ ] T048 [US3] Update `ai-assistant-spec-hub/specs/001-platform-foundation/quickstart.md` start-order, curl example, and pass criteria to match implemented ports/transports
- [ ] T049 [US3] Add “Integrated smoke” section to `ai-assistant-backend/README.md` linking quickstart and listing required env vars
- [ ] T050 [US3] Manually (or via T045) run integrated smoke with all five repos; capture pass note in `ai-assistant-spec-hub/specs/001-platform-foundation/checklists/smoke-log.md`

**Checkpoint**: Integrated smoke green; isolated suites still pass when siblings are down

---

## Phase 7: User Story 5 - Apply Consistent Engineering Standards (Priority: P2)

**Goal**: Same quality gates and CI baseline across repositories

**Independent Test**: Every runtime + contracts repo exposes lint/typecheck/test and CI runs them (SC-005)

### Implementation for User Story 5

- [ ] T051 [P] [US5] Add GitHub Actions workflow `ai-assistant-contracts/.github/workflows/ci.yml` (install → lint → typecheck → test → build)
- [ ] T052 [P] [US5] Add `ai-assistant-backend/.github/workflows/ci.yml` with same baseline gates
- [ ] T053 [P] [US5] Add `ai-assistant-rag/.github/workflows/ci.yml` with same baseline gates
- [ ] T054 [P] [US5] Add `ai-assistant-mcp/.github/workflows/ci.yml` with same baseline gates
- [ ] T055 [P] [US5] Add `ai-assistant-ui/.github/workflows/ci.yml` with same baseline gates
- [ ] T056 [US5] Add platform conventions note `ai-assistant-spec-hub/overall-context/engineering-standards.md` (script names, oxlint, Prettier, Vitest, CI checklist)
- [ ] T057 [US5] Link engineering standards from each runtime/contracts README

**Checkpoint**: CI configs exist; local scripts match documented standard

---

## Phase 8: User Story 6 - Configure Environments Without Secrets (Priority: P2)

**Goal**: Documented env profiles for isolated vs integrated; no secrets committed

**Independent Test**: Fresh clone + example env files; secrets scan clean (SC-006)

### Implementation for User Story 6

- [ ] T058 [P] [US6] Create `ai-assistant-backend/.env.example` with `PORT`, `RAG_BASE_URL`, `MCP_SERVER_URL` (placeholders only)
- [ ] T059 [P] [US6] Create `ai-assistant-rag/.env.example` with `PORT`
- [ ] T060 [P] [US6] Create `ai-assistant-mcp/.env.example` with `PORT` / transport notes
- [ ] T061 [P] [US6] Create `ai-assistant-ui/.env.example` with `VITE_BACKEND_BASE_URL`
- [ ] T062 [US6] Document isolated vs integrated variable matrix in `ai-assistant-spec-hub/overall-context/ownership.md` or `engineering-standards.md` (match quickstart)
- [ ] T063 [US6] Confirm `.gitignore` ignores `.env` in all runtime repos; run a quick secrets grep and note result in `ai-assistant-spec-hub/specs/001-platform-foundation/checklists/smoke-log.md`

**Checkpoint**: Env docs complete; no live credentials in git

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Cross-repo consistency and quickstart validation

- [ ] T064 [P] Align structured request logging (`boundary`, `contractPackageVersion`, `durationMs`) in `ai-assistant-backend/src/server.ts` (and thin logs in rag/mcp servers)
- [ ] T065 [P] Ensure default ports 3001/3002/3003/5173 documented consistently across READMEs and `quickstart.md`
- [ ] T066 Verify `$0` / no AWS / no inter-service auth statements in each README security/local section
- [ ] T067 Run full `ai-assistant-spec-hub/specs/001-platform-foundation/quickstart.md` validation end-to-end and update any drift
- [ ] T068 [P] Update `ai-assistant-spec-hub/overall-context/context.md` with a short pointer to ownership map + Phase 1 repos
- [ ] T069 Final audit: consumers depend only on `@ai-assistant/contracts` package (not contracts `src` paths); fix any violations

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 Setup**: Start immediately
- **Phase 2 Foundational**: Depends on Setup — **BLOCKS all user stories**
- **Phase 3 US1**: After Foundational — docs-only; can parallel with later coding if staffed
- **Phase 4 US4**: After Foundational — implements contract surfaces (needed before meaningful isolation fakes/smoke)
- **Phase 5 US2**: After US4 stubs exist — isolation fakes + green suites
- **Phase 6 US3**: After US2 — integrated smoke
- **Phase 7 US5**: After Foundational (can parallel with US1); ideally after US2 so CI mirrors real tests
- **Phase 8 US6**: After Foundational; refine after US3 env usage known
- **Phase 9 Polish**: After desired stories complete

### User Story Dependencies

```text
US1 (ownership) ──────────────────────────────┐
                                              ├──→ Polish
US4 (contracts impl) → US2 (isolation) → US3 (smoke) ┘
US5 (standards) can parallel after Foundational
US6 (env) can parallel after Foundational; finalize after US3
```

- **US1**: No code dependency on US4–US6
- **US4**: Blocks US2/US3 practical completion
- **US2**: Should complete before claiming US3 done
- **US3**: Depends on US4 + US2
- **US5 / US6**: Independently testable docs/CI/env; soft dependency on US2 for realistic CI

### Parallel Opportunities

- T003, T004 in Setup
- T007, T008 after T006 started; T012, T013, T015 after T011 pattern exists
- US1 README tasks T018–T022 in parallel
- US4 tests T025–T027 in parallel; clients T031–T032 after server stubs
- US5 CI workflows T051–T055 in parallel
- US6 `.env.example` files T058–T061 in parallel

---

## Parallel Example: User Story 1

```bash
# After T017 ownership.md exists, launch README ownership sections together:
Task: "Add ownership section to ai-assistant-ui/README.md"
Task: "Add ownership section to ai-assistant-backend/README.md"
Task: "Add ownership section to ai-assistant-rag/README.md"
Task: "Add ownership section to ai-assistant-mcp/README.md"
Task: "Add ownership section to ai-assistant-contracts/README.md"
```

## Parallel Example: User Story 5

```bash
Task: "Add CI workflow ai-assistant-contracts/.github/workflows/ci.yml"
Task: "Add CI workflow ai-assistant-backend/.github/workflows/ci.yml"
Task: "Add CI workflow ai-assistant-rag/.github/workflows/ci.yml"
Task: "Add CI workflow ai-assistant-mcp/.github/workflows/ci.yml"
Task: "Add CI workflow ai-assistant-ui/.github/workflows/ci.yml"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 Setup + Phase 2 Foundational (contracts package + repo scaffolds)
2. Complete Phase 3 US1 ownership map
3. **STOP and VALIDATE**: SC-001 via ownership quiz
4. Demo value: clear multi-repo ownership without full stubs

### Incremental Delivery (recommended full Phase 1)

1. Setup + Foundational → package + scaffolds
2. US1 ownership → docs MVP
3. US4 contract stubs → providers/consumers speak contracts
4. US2 isolation → green per-repo tests
5. US3 integrated smoke → SC-009
6. US5 + US6 → CI and env hygiene
7. Polish → quickstart validation

### Parallel Team Strategy

1. Together: Phase 1–2
2. Then: Dev A → US1 docs; Dev B → US4 backend/RAG; Dev C → US4 MCP + UI adapter
3. Then: together US2 → US3
4. Split US5 CI files and US6 env examples

---

## Notes

- [P] = different files, no ordering dependency within the marked set
- Tests MUST NOT require paid cloud; use fakes/fixtures
- Prefer `$0` local stubs; no inter-service auth in Phase 1
- Commit after each task or logical group
- Stop at checkpoints to validate independently
- Suggested next command after tasks: `/speckit.implement`
