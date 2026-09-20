# Research: Conversational UI Repository

**Feature**: `002-conversational-ui`  
**Date**: 2026-09-20

All Technical Context unknowns are resolved below. No remaining NEEDS CLARIFICATION.

---

## 1. Chat UI library

**Decision**: Keep **`@assistant-ui/react`** (already in `ai-assistant-ui`) as the primary chat primitives library (message list, composer, streaming presentation via `ChatModelAdapter`).

**Rationale**: Constitution prefers evaluating assistant-ui first; Phase 1 already adopted it; adapters (`localAgentAdapter`, `httpBackendAdapter`) isolate the backend boundary so Thread/App stay library-driven rather than bespoke chat infrastructure.

**Alternatives considered**:

- AI SDK UI / Vercel AI chat components — viable but would replace existing investment without clear Phase 2 win
- Build chat primitives from scratch — rejected by FR-010 and constitution
- Switch to another library mid-phase — unjustified churn; only if assistant-ui blocks multi-conversation or streaming (not observed)

---

## 2. Streaming transport (UI ↔ backend)

**Decision**: Extend the UI↔backend contract with **SSE (Server-Sent Events)** over `POST /v1/conversations/{conversationId}/messages:stream` (or equivalent path documented in OpenAPI). Event types: `message.delta`, `citation`, `activity`, `message.completed`, `error`. Keep existing `POST /v1/chat` as a **non-streaming compatibility** path for Phase 1 smoke until backend migrates callers; UI Phase 2 primary path is streaming.

**Rationale**: Spec requires progressive replies, activity events, and Abort/Stop. SSE is browser-native, works with `fetch` + ReadableStream or `EventSource`-style readers, maps cleanly to assistant-ui async generator adapters, and stays $0/local. AbortSignal cancels the HTTP request for Stop.

**Alternatives considered**:

- WebSockets — richer duplex, more ops complexity for local MVP; not needed for one-way token stream
- NDJSON over plain HTTP — fine alternative; SSE chosen for event typing and tooling familiarity
- Simulate streaming only in UI after full JSON response — fails SC/FR for real progressive UX and activity mid-flight

---

## 3. Multi-conversation API surface

**Decision**: Add conversation resource endpoints to the contracts package / OpenAPI:

| Operation | Method / path (canonical) |
|-----------|---------------------------|
| List | `GET /v1/conversations` |
| Create | `POST /v1/conversations` |
| Get messages | `GET /v1/conversations/{conversationId}/messages` |
| Stream send | `POST /v1/conversations/{conversationId}/messages:stream` |

Conversation IDs remain UUID strings. UI stores only `activeConversationId` in client state (and optionally `sessionStorage` for last-selected ID UX); **persistence of list + messages is backend/mock-owned** (FR-019).

**Rationale**: Clarification locked multi-conversation list/create/switch with reload restore via public contract—not UI-only fake threads.

**Alternatives considered**:

- Derive conversation identity only from first message id (current HTTP adapter hack) — insufficient for list/switch/reload
- Client-side IndexedDB as source of truth — violates “backend-backed IDs” and reload-via-contract requirement
- GraphQL — unjustified complexity

---

## 4. Contracts package versioning for Phase 2

**Decision**: Bump `@hazemgharib/ai-agent-contracts` to **`0.2.0` (MINOR)** with additive schemas: conversation list/create, message history, stream event union, optional `snippet` on citations, activity event type. Retain `0.1.0` chat request/response schemas for compatibility; mark streaming + conversation CRUD as the Phase 2 UI target. Consumers (UI, backend) pin `0.2.0`.

**Rationale**: Additive surface for new endpoints/events is MINOR under existing versioning policy; UI and backend must upgrade together for integrated mode. Avoid MAJOR unless breaking `ChatRequest`/`ChatResponse` fields required by Phase 1 smoke.

**Alternatives considered**:

- MAJOR 1.0.0 immediately — unnecessary if additive
- UI-private types for stream/list — violates contract-only boundary and Phase 1 ownership

---

## 5. Queued follow-up + Stop behavior (client orchestration)

**Decision**: Implement queue and Stop in a **UI runtime controller** layer (above or wrapping the assistant-ui adapter), not in the backend:

- At most one pending user text; latest submit replaces queue
- On successful stream `message.completed`, auto-send queued text
- On stream error, Stop, or conversation switch: do not auto-send; Stop restores draft to composer; switch discards queue
- Stop calls `abortSignal` / aborts fetch; partial assistant text remains as incomplete turn

**Rationale**: Spec clarifications define client behavior; backend need only honor abort and persist completed turns. Keeps queue semantics testable with mocks without new backend “queue” APIs.

**Alternatives considered**:

- Backend-side queue API — couples product UX to server; harder to test in isolated UI
- Disable composer while streaming — rejected by clarification (Option C queue)

---

## 6. Citations & activity display

**Decision**:

- **Citations**: Render display-only from stream/`ChatResponse` citation objects (`title`, `source`, optional `snippet`, `documentId`). Show URLs as plain text if present; no navigation required. Prefer expand panel on the assistant message.
- **Activity**: Map stream `activity` events (`kind`: `retrieval` | `tool` | `other`, `label`: string) to a generic in-thread status line; ignore unknown kinds safely. If no events, show only ordinary loading/streaming state.

**Rationale**: Matches clarification A (display-only) and FR-009 (no RAG/MCP coupling). Extends existing `Citation` / `ToolInvocationSummary` concepts into progressive events without UI knowing upstream services.

**Alternatives considered**:

- Clickable citation links — deferred (out of scope)
- Hard-coded “searching documents…” without events — couples UI to imagined backend behavior

---

## 7. Isolated UI testing & persisting mock

**Decision**: Ship a **contract-faithful in-memory mock backend** inside `ai-assistant-ui` (test helper and optional `VITE_USE_MOCK_BACKEND=true` mode) that implements list/create/messages/stream with persistence for the browser session (and for Vitest, a module-scoped store). Integrated mode uses real `ai-assistant-backend` once it implements the same contract. Keep `localAgentAdapter` only as a minimal offline stub or fold it into the mock.

**Rationale**: FR-011/012/019 require isolated tests including reload restore without RAG/MCP/LLM; a persisting mock is the DoD path when backend streaming isn’t ready yet.

**Alternatives considered**:

- MSW only — good for tests; still need a clear mock module for local demo
- Always require live backend — breaks isolated UI DoD

---

## 8. Backend scope for Phase 2

**Decision**: Phase 2 **implementation focus is `ai-assistant-ui`**, with a **required contracts package bump** and **minimal backend support** so integrated smoke can stream + persist conversations. Backend may keep stub orchestration (no real LLM required); streaming can emit chunked stub text + optional fake citation/activity events. RAG/MCP remain behind backend only.

**Rationale**: Spec is UI-centric but FR-016/019 and integrated smoke need a provider of the public API. Contract-first keeps UI replaceable.

**Alternatives considered**:

- UI-only with mocks forever — fails integrated smoke and “backend-backed IDs” in real mode
- Full LLM streaming in backend this phase — out of scope depth; stubs suffice if contract-complete

---

## 9. Styling / layout

**Decision**: Minimalist shell: left conversation list + main thread + composer; citations/activity as secondary inline/expand UI. Reuse existing CSS variables/layout; no marketing redesign.

**Rationale**: FR-014; desktop-first baseline.

**Alternatives considered**: Heavy design system — unjustified for Phase 2.
