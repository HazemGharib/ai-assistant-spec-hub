# Feature Specification: Conversational UI Repository

**Feature Branch**: `002-conversational-ui`  
**Created**: 2026-09-20  
**Status**: Draft  
**Input**: User description: "Phase 2 — UI Repository. Build the dedicated React + TypeScript frontend repository as a minimalist conversational interface for the agent platform. Prefer assistant-ui or another established AI-chat UI library rather than implementing chat primitives from scratch. The UI MUST communicate exclusively through the backend's public API/streaming contract and MUST NOT directly depend on RAG, MCP, vector databases, or LLM providers. Support conversation history, streaming responses, loading/error states, citations, and eventually tool/retrieval activity without coupling the UI to backend implementation details."

## Clarifications

### Session 2026-09-20

- Q: Conversation multiplicity for Phase 2 — single thread only, multi-conversation list/switch, or stub shell? → A: Multi-conversation required: list, create, and switch between conversations via backend-backed IDs
- Q: What happens when the user submits while a reply is already streaming? → A: Queue the next user message and send it automatically when the current stream completes
- Q: Must users be able to stop/cancel in-progress generation? → A: Stop aborts the in-flight stream and discards any queued follow-up (draft may return to composer)
- Q: How deep should citation interaction be in Phase 2? → A: Display-only: show citation title/snippet/source labels inline or in an expand panel; no external navigation required
- Q: Must conversation history survive browser reload in Phase 2? → A: Reload persistence required against backend/mock: after reload, conversation list and selected thread messages are restorable via the public contract

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Hold a Live Conversation with Streaming Replies (Priority: P1)

An end user opens the chat interface, types a message, and sees the assistant reply appear progressively as it is generated. While waiting, they see a clear loading state; if something fails, they see an understandable error without losing the rest of the conversation.

**Why this priority**: Live send/receive with streaming and honest loading/error feedback is the minimum viable conversational product; without it, the UI repository does not deliver Phase 2 value.

**Independent Test**: Against a backend (or contract-faithful mock) that streams replies, a tester can send a message, observe progressive assistant text, and verify loading and failure paths without any RAG/MCP services running in the UI process.

**Acceptance Scenarios**:

1. **Given** the UI is connected to a reachable backend conversation endpoint, **When** the user submits a message, **Then** the message appears in the thread and an assistant reply streams in without requiring a full-page refresh.
2. **Given** a reply is in progress, **When** the user views the thread, **Then** a loading or in-progress indicator is visible until the stream completes or fails.
3. **Given** the backend is unreachable or returns a failure, **When** the user submits a message, **Then** the UI shows a clear error state, keeps prior messages visible, and allows the user to retry or continue.
4. **Given** an assistant reply is still streaming, **When** the user submits another message, **Then** that message is queued (single pending slot), the current stream continues uninterrupted, and when the stream completes successfully the queued message is sent automatically in order without corrupting thread order.
5. **Given** a message is already queued while a reply streams, **When** the user submits yet another message, **Then** the pending queue holds at most one message (the latest submission replaces the previous queued text) so ordering stays deterministic.
6. **Given** an assistant reply is streaming (with or without a queued follow-up), **When** the user activates Stop, **Then** the in-flight stream is aborted, any queued follow-up is discarded (draft may return to the composer), partial assistant text already received remains visible as a stopped/incomplete turn, and no auto-send occurs.

---

### User Story 2 - Review Conversation History in Context (Priority: P1)

A user continuing a conversation can scroll through prior user and assistant turns in order so they understand context and can follow up without starting over. They can also list conversations, create a new one, and switch between conversations using backend-backed conversation IDs—without losing the message history of conversations they leave and return to (when the backend persists them).

**Why this priority**: Conversation history is core to chat UX and is required for multi-turn agent use; multi-conversation list/create/switch is an explicit Phase 2 requirement so users can separate topics via the public backend contract.

**Independent Test**: Load or create multiple conversations with fixtures or a mock backend; confirm chronological display within a thread, role distinction, append-on-send, and that switching conversations loads the correct backend-backed thread.

**Acceptance Scenarios**:

1. **Given** an existing conversation with multiple turns, **When** the user opens it, **Then** all prior messages appear in chronological order with user and assistant roles distinguishable.
2. **Given** a conversation is already displayed, **When** the user sends another message and receives a reply, **Then** the new turns append to the history without clearing earlier messages.
3. **Given** the UI runs in isolated demo/mock mode, **When** conversation history is exercised with fixtures, **Then** history behavior is demonstrable without live sibling services.
4. **Given** at least two backend-backed conversations exist, **When** the user views the conversation list and selects one, **Then** the active thread switches to that conversation’s messages.
5. **Given** the user is in an existing conversation, **When** they create a new conversation, **Then** a new backend-backed conversation ID is established and the thread starts empty (or with only welcome/empty state), without deleting other conversations from the list.
6. **Given** the user has created conversations and exchanged messages against a persisting backend or contract-faithful mock, **When** they reload the browser and the UI reconnects via the public contract, **Then** the conversation list is restored and the previously selected (or last active) conversation’s messages are restorable without data loss attributable to the UI.

---

### User Story 3 - Trust Answers via Citations (Priority: P2)

When an assistant reply includes source citations supplied by the backend contract, the user can see those citations associated with the reply and inspect display-only details (title, snippet, and/or source label—inline or in an expand panel) enough to judge where the answer came from—without the UI knowing how retrieval was performed and without requiring external navigation.

**Why this priority**: Citations build trust for knowledge-grounded answers; they depend on contract payloads more than on chat primitives, so they follow the core conversation loop.

**Independent Test**: Feed a fixture or mock reply that includes citation metadata; verify citations render with the message as display-only details and that citation UI does not require direct RAG configuration or outbound link navigation in the UI.

**Acceptance Scenarios**:

1. **Given** an assistant message that includes citation data from the backend contract, **When** the user views that message, **Then** citations are visible and associated with that reply as display-only title/snippet/source labels (inline or expandable).
2. **Given** an assistant message with no citations, **When** the user views that message, **Then** the UI does not show empty or placeholder citation chrome that implies sources exist.
3. **Given** citation content is untrusted retrieval text, **When** it is displayed, **Then** it is treated as untrusted content (no automatic navigation; no execution of embedded scripts or unsafe markup).
4. **Given** a citation payload that includes a URL field, **When** the user interacts with the citation UI in Phase 2, **Then** the UI still does not require or perform external navigation as part of the Phase 2 acceptance path (URLs may be shown as plain text if present).

---

### User Story 4 - Observe Tool and Retrieval Activity Without Implementation Coupling (Priority: P2)

While the assistant is working, the user can see generic activity cues (for example, that the agent is retrieving knowledge or using a tool) when the backend exposes those events on the public conversation/streaming contract. The UI never configures or calls retrieval or tool systems itself.

**Why this priority**: Forward-compatible activity visibility is required by Phase 2 intent (“eventually”), but must not couple the UI to RAG/MCP internals; it can ship as contract-driven status display once the conversation stream provides events.

**Independent Test**: Drive the UI with a mock stream that emits activity events and one that does not; confirm activity UI appears only from contract events and that no UI config points at RAG/MCP/LLM providers.

**Acceptance Scenarios**:

1. **Given** the backend streams tool or retrieval activity events on the conversation contract, **When** a reply is in progress, **Then** the UI shows user-facing activity status derived only from those events.
2. **Given** the backend does not emit activity events, **When** a reply streams, **Then** the conversation still works with ordinary loading/streaming states and no broken activity panel.
3. **Given** a reviewer inspects UI dependencies and configuration, **When** they look for RAG, MCP, vector database, or LLM provider integrations, **Then** none are present; the only runtime integration is the backend public conversation/streaming boundary (plus shared contracts package as allowed).

---

### User Story 5 - Run and Verify the UI Repository Independently (Priority: P1)

A developer clones `ai-assistant-ui`, installs dependencies, starts the local UI, and runs automated tests using documented local configuration and mocks/fixtures for the backend contract—without starting RAG, MCP, or LLM providers in the UI repository.

**Why this priority**: Independent runnability is a platform non-negotiable and proves the UI boundary is real, not an accidental monolith client.

**Independent Test**: From a clean UI checkout, follow README setup; start the app against a mock or documented backend URL; run the test suite; confirm success without paid cloud or non-backend sibling services.

**Acceptance Scenarios**:

1. **Given** only `ai-assistant-ui` checked out (plus the versioned contracts package install path), **When** a developer follows local setup docs, **Then** they can start the conversational UI locally.
2. **Given** the UI test suite, **When** tests run, **Then** they pass using mocks/fixtures for the backend conversation/streaming contract without requiring live RAG, MCP, or paid LLM credentials inside the UI repo.
3. **Given** integrated local mode with the backend running, **When** the developer points the UI at the documented backend base URL, **Then** they can complete a live conversational smoke path through the public API/streaming contract only.

---

### Edge Cases

- What happens when the stream disconnects mid-reply? → UI shows a recoverable error or partial-reply state, preserves messages received so far, and allows retry without wiping history.
- What happens when the user activates Stop during streaming? → UI aborts the in-flight stream, discards any queued follow-up (optionally restoring that text to the composer), keeps partial assistant content already shown as a stopped/incomplete turn, and does not auto-send.
- What happens when the user submits while a reply is already streaming? → UI queues at most one next user message (latest submission replaces any existing queued text) and sends it automatically when the current stream completes successfully; message order in the thread is preserved.
- What happens when the in-flight stream fails while a message is queued? → Queued message is not auto-sent; user sees the stream error and may resubmit; the queued draft may remain editable or be restored to the composer.
- What happens when citation or activity payloads are malformed? → UI ignores or safely degrades that enrichment; core message text and history remain usable.
- What happens when the backend is slow but still connected? → Loading/in-progress state remains visible; user is not left with a blank or frozen composer without feedback.
- What happens if someone tries to add a direct RAG or LLM client to the UI? → Ownership and review rules reject it; Phase 2 DoD requires exclusive use of the backend public contract.
- What about empty input? → Submit is disabled or rejected with no network call; no empty user message appears in history.
- What about very long conversations? → History remains scrollable and usable; performance remains acceptable for typical local demo lengths (see success criteria).
- What happens when the user switches conversations while a reply is streaming? → Active stream for the left conversation is cancelled or abandoned; any queued message for that conversation is discarded; the newly selected conversation loads cleanly without mixing message threads.
- What happens when the conversation list fails to load? → UI shows a clear list-level error and still allows retry; the last known active thread (if any) is not silently corrupted.
- What happens after a full browser reload? → Against a persisting backend or contract-faithful mock, the UI re-fetches via the public contract and restores the conversation list and selected thread messages; ephemeral UI-only state (queued draft, in-flight stream) is not required to survive reload.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The platform MUST deliver a dedicated conversational frontend in `ai-assistant-ui` as a minimalist chat experience for the agent platform (evolve the existing repository; do not introduce a second UI repository).
- **FR-002**: The UI MUST communicate with the platform exclusively through the backend’s public conversation and streaming contract (via the versioned contracts package); it MUST NOT call RAG, MCP, vector databases, or LLM providers directly.
- **FR-003**: The UI MUST NOT embed provider secrets, API keys for models/retrieval/tools, or backend-private configuration beyond the documented public backend base URL (and related non-secret client settings).
- **FR-004**: Users MUST be able to compose and send messages and receive assistant replies in the active conversational thread.
- **FR-005**: The UI MUST render assistant replies progressively when the backend streams response content.
- **FR-006**: The UI MUST present clear loading/in-progress states while a reply is outstanding and clear error states when send or stream fails, without discarding prior conversation turns.
- **FR-007**: The UI MUST display conversation history for the active conversation in chronological order with distinguishable user and assistant roles.
- **FR-008**: When the backend contract includes citation data on a reply, the UI MUST present those citations with the associated message as display-only details (title, snippet, and/or source label—inline or in an expand panel); when citations are absent, the UI MUST NOT imply sources exist. Phase 2 MUST NOT require external navigation/open-in-new-tab as part of citation acceptance.
- **FR-009**: The UI MUST be able to present generic tool/retrieval (or similar) activity indicators when such events appear on the public streaming/conversation contract, without encoding RAG- or MCP-specific implementation details in the UI.
- **FR-010**: Chat interaction primitives (message list, composer, streaming presentation) SHOULD be built on an established AI-chat UI library rather than bespoke low-level chat infrastructure; prefer evaluating assistant-ui before inventing equivalents, consistent with the platform constitution.
- **FR-011**: `ai-assistant-ui` MUST remain independently installable, runnable, and testable locally using mocks/fixtures for the backend contract, without paid cloud services and without requiring RAG/MCP processes for the UI’s isolated suite.
- **FR-012**: UI automated tests MUST cover at least: sending a message, rendering streamed (or simulated streamed) assistant content, loading and error states, history append behavior, citation rendering from contract-shaped fixtures, list/create/switch across at least two backend-backed (or mock) conversations without message bleed, queued follow-up send-after-complete, Stop aborting stream without auto-sending a queued follow-up, and restore of list plus thread messages after simulated reload against a persisting mock.
- **FR-013**: The UI README MUST document local setup, how to point at a backend base URL, how to run tests, and the explicit non-goals (no direct RAG/MCP/LLM dependencies).
- **FR-014**: Visual design MUST stay minimalist: primary surface is the active conversation thread; the conversation list and secondary panels (citations, activity) MUST NOT overwhelm the chat thread.
- **FR-015**: Untrusted assistant, citation, and activity content MUST be rendered safely (no execution of untrusted scripts; no secrets displayed from client storage that should not exist).
- **FR-016**: The UI MUST support multiple conversations via the backend public contract: list existing conversations, create a new conversation, and switch the active conversation using backend-backed conversation IDs (no UI-only fake multi-conversation that cannot round-trip through the backend/mock contract).
- **FR-017**: While an assistant reply is streaming for the active conversation, if the user submits another message the UI MUST queue at most one pending user message (latest submission replaces any existing queued text) and MUST send that queued message automatically only after the current stream completes successfully; on stream failure, Stop, or conversation switch, the UI MUST NOT auto-send the queued message (restore to composer or discard per switch/Stop rules).
- **FR-018**: The UI MUST provide a Stop control while an assistant reply is in progress that aborts the in-flight stream and discards any queued follow-up (draft MAY be restored to the composer); partial assistant content already received MUST remain visible as a stopped/incomplete turn.
- **FR-019**: Against a backend or contract-faithful mock that persists conversations, after a browser reload the UI MUST restore the conversation list and the selected (or last active) conversation’s messages via the public contract; Phase 2 acceptance MUST NOT treat UI-only ephemeral multi-conversation state as sufficient for integrated/persistence demos.

### Key Entities

- **Conversation**: An ordered sequence of turns the user can view and continue; identified by a backend-backed conversation ID from the public contract. Users can list, create, and switch among conversations; the UI treats IDs as opaque except for display, selection, and request correlation.
- **Message / Turn**: A single user or assistant contribution, including text content and optional enrichment (citations, activity-related metadata) as defined by the public contract.
- **Citation**: A user-visible, display-only reference associated with an assistant message (title/snippet/source label), supplied by the backend; the UI does not resolve, fetch, or navigate to source corpora itself in Phase 2.
- **Activity Event**: A contract-level signal that the agent is performing work (e.g., retrieval or tool use) for display as generic status—not a direct handle to RAG/MCP systems.
- **Streaming Reply**: An in-progress assistant turn whose content arrives over time until completion or failure.
- **UI↔Backend Boundary**: The sole allowed integration edge for the frontend; all conversational I/O and enrichment flow through this public contract.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A new user can open the UI, send a first message, and see an assistant reply begin within 3 seconds of backend first-byte (or mock equivalent), with loading feedback visible before content arrives.
- **SC-002**: In a scripted demo of a 10-turn conversation, 100% of turns remain visible in order after the final reply, including after one forced stream failure and retry.
- **SC-010**: In a scripted test where the user submits a follow-up while a reply is still streaming, the follow-up is sent only after the first stream completes, both turns appear in correct order, and replacing a queued draft before send results in only the latest queued text being sent (100% agreement with fixture expectations).
- **SC-011**: In a scripted test, activating Stop during a streaming reply aborts further tokens, discards any queued follow-up (no auto-send), and leaves already-rendered partial assistant text visible in 100% of runs.
- **SC-009**: In a scripted demo with at least two backend-backed conversations, a user can create a conversation, send messages in each, and switch between them with 100% correct thread association (no cross-conversation message bleed) in automated or checklist verification.
- **SC-012**: After creating at least two conversations with messages against a persisting backend/mock, a full UI reload restores the conversation list and the active thread’s messages via the public contract with 100% agreement to pre-reload content in verification (excluding ephemeral in-flight/queue state).
- **SC-003**: 100% of UI integration points to platform services resolve only to the backend public conversation/streaming contract; dependency and config review finds zero direct RAG, MCP, vector DB, or LLM provider clients in `ai-assistant-ui`.
- **SC-004**: Citation fixture demos show display-only citations on cited replies and no false citation UI on uncited replies, with 100% agreement against the fixture expectations in automated tests; acceptance does not depend on opening external links.
- **SC-005**: Isolated UI setup reaches a runnable conversational demo (against mock or local backend URL) in under 15 minutes on a clean machine (excluding dependency download variability), at $0 mandatory cloud cost.
- **SC-006**: The isolated automated UI test suite passes with no live RAG/MCP processes and no paid LLM credentials required inside the UI repository.
- **SC-007**: At least 90% of first-time demo participants can complete “send a message and read the reply” without facilitator help beyond the README.
- **SC-008**: When activity events are present in a mock stream, users can identify that the assistant is “working on something” (retrieval/tool or equivalent generic label) without being shown internal service names or endpoints.

## Assumptions

- Phase 1 foundations exist: `ai-assistant-ui`, `ai-assistant-backend`, `ai-assistant-contracts`, and the UI↔backend conversation/streaming contract are available enough to build against (stubs/mocks allowed where backend behavior is incomplete).
- Phase 2 evolves the existing `ai-assistant-ui` repository rather than creating a replacement UI repo.
- End-user authentication/authorization remains out of scope; local demo trusts the configured backend URL (consistent with Phase 1 localhost trust model).
- Conversation persistence across browser reloads is a Phase 2 acceptance requirement when using a backend or contract-faithful mock that persists; isolated unit tests may still use in-memory mocks, but at least one automated or checklist path MUST prove list + thread restore after reload/simulated reload.
- Multi-conversation list, create, and switch is required for Phase 2 (not optional polish); conversation search/filtering remains out of scope unless already trivial.
- “Eventually” tool/retrieval activity means Phase 2 MUST support contract-driven activity display and MUST NOT hard-code RAG/MCP UI; rich activity timelines can deepen later when the backend emits richer events.
- Prefer an established chat UI library (assistant-ui first per constitution); adopting it is the default unless evaluation shows a blocking fit issue, in which case another established library is chosen rather than greenfield primitives.
- Styling stays minimal and functional; brand-heavy marketing pages are out of scope.
- Mobile-usable layout is desirable but desktop-first local demo is the acceptance baseline for Phase 2.

## Out of Scope

- Direct UI integration with RAG services, MCP servers, vector databases, or LLM provider SDKs
- Building custom low-level chat infrastructure when an established library can cover message list, composer, and streaming presentation
- End-user authentication, accounts, billing, or multi-tenant admin
- Production CDN/hosting hardening and cloud deployment as defaults
- Clickable/external citation navigation (open source URLs in a new tab) as a Phase 2 requirement
- Advanced markdown/canvas editors, plugin marketplaces, or non-conversational product surfaces
- Conversation search, folders, sharing, or rename/archive workflows beyond list/create/switch of backend-backed conversations
- Owning retrieval quality, tool execution semantics, or agent planning logic inside the UI repository
- Redesigning or replacing the UI↔backend contract ownership (contracts remain in `ai-assistant-contracts`)

## Platform Constraints *(align with constitution)*

- **Local-first**: Feature MUST be demonstrable locally without AWS provisioning
- **Zero-cost default**: MUST NOT require paid infrastructure for local/MVP verification
- **Capability type**: UI (conversational presentation); agent orchestration, RAG, and MCP remain behind the backend boundary
- **Authoritative data**: UI displays whatever the backend returns; it MUST NOT invent a parallel retrieval path for “better” answers
- **Security**: No secrets in browser or source control; treat assistant/citation/activity content as untrusted; UI depends only on public backend contract
- **Definition of Done**: Local TypeScript UI implementation, tests without paid cloud, error/loading handling, documented deps/env, portability/security considered; chat primitives prefer established OSS library (assistant-ui evaluation first)
- **Architecture check**: UI → backend only; never UI → RAG/MCP/LLM directly
