# Tasks: Conversational UI Repository

**Input**: Design documents from `/specs/002-conversational-ui/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Included — FR-012 / SC-* require Vitest coverage for send, stream, loading/error, history, citations, list/create/switch, queue, Stop, and reload restore without paid cloud.

**Organization**: Tasks grouped by user story. Story labels map to spec.md:

- **US1** = Live conversation with streaming, queue, Stop (P1) 🎯 MVP
- **US2** = Conversation history + multi-conversation list/create/switch + reload (P1)
- **US3** = Display-only citations (P2)
- **US4** = Generic tool/retrieval activity indicators (P2)
- **US5** = Independent UI run/test + integrated smoke docs (P1)

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: User story label (US1–US5) for story-phase tasks only
- Include exact file paths in descriptions

## Path Conventions

Sibling repos under `/Users/zuka/coding/ai-assistant/`:

```text
ai-assistant-ui/
ai-assistant-contracts/
ai-assistant-backend/
ai-assistant-spec-hub/   # design docs only
```

Paths below are relative to that workspace root (e.g. `ai-assistant-ui/src/App.tsx`).

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Align package pins and env scaffolding for Phase 2 work without changing product behavior yet

- [X] T001 Bump `ai-assistant-contracts/package.json` version to `0.2.0` and note Phase 2 additive chat APIs in `ai-assistant-contracts/README.md` (link to `ai-assistant-spec-hub/specs/002-conversational-ui/contracts/`)
- [X] T002 [P] Pin `"@hazemgharib/ai-agent-contracts": "0.2.0"` (or documented `file:../ai-assistant-contracts`) in `ai-assistant-ui/package.json` and `ai-assistant-backend/package.json`
- [X] T003 [P] Add UI env examples for `VITE_BACKEND_BASE_URL` and `VITE_USE_MOCK_BACKEND` in `ai-assistant-ui/.env.example` (no secrets)
- [X] T004 [P] Create directory placeholders `ai-assistant-ui/src/adapters/mockBackend/.gitkeep`, `ai-assistant-ui/src/conversation/.gitkeep` per plan structure

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Contracts 0.2.0 schemas + shared client types — MUST complete before ANY user story

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T005 Extend citation + stream/conversation Zod schemas in `ai-assistant-contracts/src/chat/index.ts` from `ai-assistant-spec-hub/specs/002-conversational-ui/contracts/ui-backend-chat.openapi.yaml` and `stream-events.md` (`Conversation`, list/create, `StoredMessage`, `StreamEvent` union, `Citation.snippet`/`url`, `ActivityEvent`)
- [X] T006 Export new chat symbols and bump `CONTRACT_PACKAGE_VERSION` to `0.2.0` in `ai-assistant-contracts/src/index.ts`
- [X] T007 [P] Add failing-then-passing schema tests for conversations + stream events in `ai-assistant-contracts/src/chat/chat.test.ts`
- [X] T008 Build contracts package (`pnpm build` in `ai-assistant-contracts/`) and reinstall so `ai-assistant-ui` / `ai-assistant-backend` resolve `0.2.0` types
- [X] T009 Define shared backend-client interface types (list/create/getMessages/stream) in `ai-assistant-ui/src/adapters/backendClient.ts` using contracts package types only
- [X] T010 [P] Document stream event handling rules for implementers in `ai-assistant-ui/src/adapters/README.md` (pointer to spec-hub `contracts/stream-events.md`)

**Checkpoint**: Contracts `0.2.0` builds/tests; UI has a typed backend client interface — story work can start

---

## Phase 3: User Story 1 - Live Streaming Conversation (Priority: P1) 🎯 MVP

**Goal**: User can send a message, see progressive assistant text, loading/error states, single-slot queue, and Stop

**Independent Test**: Against mock (or stub stream): send → stream deltas; submit while streaming → queue then auto-send; Stop → abort + discard queue; backend down → error without wiping prior turns

### Tests for User Story 1

> Write these tests FIRST; ensure they FAIL before implementation

- [X] T011 [P] [US1] Add Vitest tests for SSE/mock stream deltas + loading/error in `ai-assistant-ui/src/adapters/mockBackend/mockBackend.stream.test.ts`
- [X] T012 [P] [US1] Add Vitest tests for single-slot queue + Stop discard behavior in `ai-assistant-ui/src/conversation/sendQueue.test.ts`

### Implementation for User Story 1

- [X] T013 [US1] Implement in-memory streamable mock (`create`, `streamMessage` with deltas/abort) in `ai-assistant-ui/src/adapters/mockBackend/store.ts` and `ai-assistant-ui/src/adapters/mockBackend/client.ts`
- [X] T014 [US1] Implement SSE HTTP stream consumer for `POST .../messages:stream` in `ai-assistant-ui/src/adapters/httpBackendAdapter.ts` (replace one-shot `/v1/chat` as primary path; honor `abortSignal`)
- [X] T015 [US1] Implement send-queue + Stop orchestration in `ai-assistant-ui/src/conversation/sendQueue.ts` and wire AbortController in `ai-assistant-ui/src/conversation/runtimeController.ts`
- [X] T016 [US1] Wire RuntimeProvider to select mock vs HTTP via env in `ai-assistant-ui/src/components/RuntimeProvider.tsx`
- [X] T017 [US1] Ensure Thread/composer shows loading and error states without clearing history in `ai-assistant-ui/src/components/Thread.tsx`
- [X] T018 [US1] Add Stop control UI wired to abort in `ai-assistant-ui/src/components/Thread.tsx` (or dedicated `ai-assistant-ui/src/components/StopButton.tsx`)
- [X] T019 [US1] Reject empty submits (no network) in composer path used by `ai-assistant-ui/src/components/Thread.tsx` / runtime controller

**Checkpoint**: US1 demo works in mock mode with stream, queue, Stop, and errors — MVP

---

## Phase 4: User Story 2 - History & Multi-Conversation (Priority: P1)

**Goal**: List/create/switch backend-backed conversations; chronological history; reload restore via contract

**Independent Test**: Create two conversations, message each, switch with no bleed; simulated reload restores list + active thread from mock/backend

### Tests for User Story 2

- [X] T020 [P] [US2] Add Vitest tests for list/create/switch without message bleed in `ai-assistant-ui/src/adapters/mockBackend/mockBackend.conversations.test.ts`
- [X] T021 [P] [US2] Add Vitest test for reload restore (re-list + re-fetch messages) in `ai-assistant-ui/src/conversation/reloadRestore.test.ts`

### Implementation for User Story 2

- [X] T022 [US2] Extend mock store with persisted conversations + `list`/`create`/`getMessages` in `ai-assistant-ui/src/adapters/mockBackend/store.ts`
- [X] T023 [US2] Implement conversation state (active id, load messages, switch cancels stream + discards queue) in `ai-assistant-ui/src/conversation/conversationStore.ts`
- [X] T024 [US2] Build conversation list + create UI in `ai-assistant-ui/src/components/ConversationList.tsx`
- [X] T025 [US2] Integrate list + thread layout in `ai-assistant-ui/src/App.tsx` (minimalist: list secondary, thread primary)
- [X] T026 [US2] On switch/reload, hydrate assistant-ui thread from `getMessages` in `ai-assistant-ui/src/components/RuntimeProvider.tsx` / `conversationStore.ts`
- [X] T027 [US2] Implement backend in-memory conversation store in `ai-assistant-backend/src/store/conversations.ts`
- [X] T028 [P] [US2] Add `GET/POST /v1/conversations` and `GET /v1/conversations/:id/messages` in `ai-assistant-backend/src/routes/conversations.ts`
- [X] T029 [US2] Add stub SSE `POST /v1/conversations/:id/messages:stream` in `ai-assistant-backend/src/routes/stream.ts` and register routes in `ai-assistant-backend/src/server.ts`
- [X] T030 [US2] Extend HTTP client methods for list/create/getMessages in `ai-assistant-ui/src/adapters/httpBackendAdapter.ts` (or `backendClient.ts` HTTP impl)

**Checkpoint**: Multi-conversation + reload works against mock and stub backend

---

## Phase 5: User Story 5 - Independent Run & Verify (Priority: P1)

**Goal**: UI repo install/dev/test documented; isolated suite needs no RAG/MCP/LLM; integrated smoke uses backend URL only

**Independent Test**: Clean UI checkout + contracts install → `pnpm test` + mock `pnpm dev`; with backend up, point `VITE_BACKEND_BASE_URL` and complete quickstart smoke checklist

### Tests for User Story 5

- [X] T031 [P] [US5] Add dependency guard test/script asserting no RAG/MCP/LLM provider packages in `ai-assistant-ui/package.json` via `ai-assistant-ui/scripts/assert-ui-boundary.mjs` (or `ai-assistant-ui/src/boundary.assert.test.ts`)

### Implementation for User Story 5

- [X] T032 [US5] Update `ai-assistant-ui/README.md` with mock vs integrated env, non-goals (no RAG/MCP/LLM), and test/dev commands
- [X] T033 [P] [US5] Update `ai-assistant-backend/README.md` with conversation + stream stub endpoints and ports
- [X] T034 [US5] Align `ai-assistant-spec-hub/specs/002-conversational-ui/quickstart.md` smoke checklist with actual scripts/env names
- [X] T035 [US5] Ensure CI in `ai-assistant-ui/.github/workflows/ci.yml` runs `test`, `lint`, `typecheck` (and boundary assert if added)

**Checkpoint**: Contributor can follow README/quickstart for isolated + integrated verification

---

## Phase 6: User Story 3 - Display-Only Citations (Priority: P2)

**Goal**: Show citation title/snippet/source on assistant messages; no external navigation; no chrome when absent

**Independent Test**: Fixture stream with citations renders expand/inline details; uncited message has no citation UI; URL fields shown as plain text only

### Tests for User Story 3

- [X] T036 [P] [US3] Add Vitest tests for citation render / absent / plain-text URL in `ai-assistant-ui/src/components/CitationsPanel.test.tsx`

### Implementation for User Story 3

- [X] T037 [US3] Parse `citation` stream events and attach to assistant turn in `ai-assistant-ui/src/adapters/httpBackendAdapter.ts` and mock stream fixtures in `ai-assistant-ui/src/adapters/mockBackend/fixtures.ts`
- [X] T038 [US3] Implement display-only citations UI in `ai-assistant-ui/src/components/CitationsPanel.tsx` and mount from `ai-assistant-ui/src/components/Thread.tsx`
- [X] T039 [P] [US3] Optionally emit sample citation events from stub stream in `ai-assistant-backend/src/routes/stream.ts` for integrated demos

**Checkpoint**: Citations visible only when present; no navigation required

---

## Phase 7: User Story 4 - Activity Indicators (Priority: P2)

**Goal**: Show generic retrieval/tool activity from stream events only; degrade gracefully when absent

**Independent Test**: Mock stream with `activity` events shows status label; stream without activity still works; no RAG/MCP config in UI

### Tests for User Story 4

- [X] T040 [P] [US4] Add Vitest tests for activity started/completed and ignore-malformed in `ai-assistant-ui/src/components/ActivityStatus.test.tsx`

### Implementation for User Story 4

- [X] T041 [US4] Handle `activity` stream events in adapters (`ai-assistant-ui/src/adapters/httpBackendAdapter.ts`, `ai-assistant-ui/src/adapters/mockBackend/client.ts`)
- [X] T042 [US4] Implement generic activity status UI in `ai-assistant-ui/src/components/ActivityStatus.tsx` and show during in-flight turns in `ai-assistant-ui/src/components/Thread.tsx`
- [X] T043 [P] [US4] Optionally emit sample activity events from `ai-assistant-backend/src/routes/stream.ts`

**Checkpoint**: Activity is contract-driven only; core chat works without events

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Safety, docs consistency, and end-to-end validation across stories

- [X] T044 [P] Sanitize/render assistant, citation, and activity text safely (no raw HTML execution) in `ai-assistant-ui/src/components/CitationsPanel.tsx` and `ai-assistant-ui/src/components/ActivityStatus.tsx`
- [X] T045 [P] Retire or clearly demote legacy one-shot path messaging in `ai-assistant-ui/src/adapters/localAgentAdapter.ts` (point to mock/HTTP)
- [X] T046 Mark Phase 1 `POST /v1/chat` as compatibility-only in `ai-assistant-backend/src/routes/chat.ts` (keep working) and note deprecation in `ai-assistant-backend/README.md`
- [X] T047 Run full isolated gate: `pnpm test && pnpm lint && pnpm typecheck` in `ai-assistant-ui/` and `ai-assistant-contracts/`
- [X] T048 Run integrated smoke checklist from `ai-assistant-spec-hub/specs/002-conversational-ui/quickstart.md` (UI → backend only)
- [X] T049 [P] Sync OpenAPI copy if needed: ensure `ai-assistant-spec-hub/specs/002-conversational-ui/contracts/ui-backend-chat.openapi.yaml` matches shipped `0.2.0` schemas

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Start immediately
- **Foundational (Phase 2)**: Depends on Setup — **BLOCKS all user stories**
- **US1 (Phase 3)**: After Foundational — MVP
- **US2 (Phase 4)**: After US1 stream/runtime (needs message path + abort-on-switch)
- **US5 (Phase 5)**: After US1+US2 enough to document/verify (can draft README earlier, finish after)
- **US3 (Phase 6)** / **US4 (Phase 7)**: After US1 stream event plumbing; can run largely in parallel with each other
- **Polish (Phase 8)**: After desired stories complete

### User Story Dependencies

```text
Foundation
    └── US1 (stream/queue/Stop)  ← MVP
            └── US2 (multi-conversation + reload + backend stub)
                    └── US5 (docs/CI/boundary verify)
            └── US3 (citations)     ⎫ can proceed in parallel after stream events exist
            └── US4 (activity)      ⎭
```

### Parallel Opportunities

- T002–T004 (Setup) in parallel
- T007 and T010 after T005/T006
- T011 || T012 (US1 tests)
- T020 || T021 (US2 tests)
- T028 || other UI work once store exists
- T032 || T033 (READMEs)
- US3 and US4 implementation after shared stream parsing
- T044 || T045 || T049 in Polish

---

## Parallel Example: User Story 1

```bash
# Tests in parallel:
Task: "Vitest stream/loading/error in ai-assistant-ui/src/adapters/mockBackend/mockBackend.stream.test.ts"
Task: "Vitest queue/Stop in ai-assistant-ui/src/conversation/sendQueue.test.ts"

# Then sequential implementation: mock store → HTTP SSE → queue/Stop → RuntimeProvider → Thread UI
```

## Parallel Example: User Stories 3 & 4

```bash
# After stream plumbing exists:
Task: "CitationsPanel + tests in ai-assistant-ui/src/components/"
Task: "ActivityStatus + tests in ai-assistant-ui/src/components/"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 Setup + Phase 2 Foundational
2. Complete Phase 3 US1 (mock stream + queue + Stop + errors)
3. **STOP and VALIDATE** mock demo + US1 tests
4. Demo progressive chat without multi-conversation if needed

### Incremental Delivery

1. Setup + Foundation → contracts `0.2.0` ready
2. US1 → streaming MVP
3. US2 → multi-conversation + backend stub + reload
4. US5 → docs/CI/boundary proof
5. US3 → citations
6. US4 → activity
7. Polish → integrated smoke + safety

### Suggested MVP Scope

**US1 only** (T011–T019) after Foundation — proves Phase 2 core value (streaming conversational UI on contract boundary).

---

## Notes

- [P] = different files, no wait on incomplete sibling tasks
- All story-phase tasks include `[USn]` labels
- Every task includes at least one concrete file path
- Tests MUST NOT require paid cloud, live RAG, MCP, or LLM credentials
- UI MUST NOT add RAG/MCP/LLM client dependencies (enforced in US5)
- Commit after each task or logical group; validate at checkpoints
