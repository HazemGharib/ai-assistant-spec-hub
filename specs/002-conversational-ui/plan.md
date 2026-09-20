# Implementation Plan: Conversational UI Repository

**Branch**: `002-conversational-ui` | **Date**: 2026-09-20 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-conversational-ui/spec.md`

## Summary

Evolve `ai-assistant-ui` into a minimalist multi-conversation chat client on `@assistant-ui/react` that speaks **only** to the backend public conversation/SSE contract (`@hazemgharib/ai-agent-contracts` **0.2.0**). Deliver streaming replies, Stop + single-slot send queue, display-only citations, generic activity indicators, conversation list/create/switch with reload restore, and a contract-faithful persisting mock for isolated tests—without any UI dependency on RAG, MCP, vector DBs, or LLM providers. Backend gains minimal conversation + stream stub support for integrated smoke.

## Technical Context

**Language/Version**: TypeScript ~6 / React 19 / Node.js 22+ (UI Vite app); contracts & backend remain TypeScript on Node 22  
**Primary Dependencies**: `@assistant-ui/react` (existing); `@hazemgharib/ai-agent-contracts` 0.2.0; Vite; Vitest; oxlint; Prettier; pnpm — all free/OSS, $0  
**Storage**: None in UI (ephemeral client state only). Conversation/message persistence owned by backend or in-memory mock implementing the same contract  
**Testing**: Vitest unit/component tests with persisting mock; no paid cloud; no live RAG/MCP/LLM required for UI suite  
**Target Platform**: Local-first browser + local backend; AWS not required  
**Project Type**: Multi-repository (continue Phase 1 topology); primary code in `ai-assistant-ui` + contract bump + thin backend stream/persistence  
**Performance Goals**: First assistant bytes within 3s of backend first-byte (SC-001); usable 10-turn threads; setup &lt; 15 min  
**Constraints**: $0 infra; no secrets in browser; UI → backend only; untrusted citation/activity/assistant text; desktop-first minimalist layout  
**Scale/Scope**: Phase 2 conversational UX + contract extension; stub streaming OK; no auth; no citation deep-links; no conversation search/folders

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*
*Source: `.specify/memory/constitution.md` (TypeScript RAG AI Agent Platform)*

- [x] TypeScript/Node for frontend and agent services; secrets not in source control
- [x] Clear UI → Agent → (RAG | MCP) separation; UI not coupled to agent internals
- [x] Feature runs locally without AWS; paid/cloud deps optional and documented
- [x] Zero-cost default: any paid service justified — none required
- [x] Provider-specific code behind interfaces — N/A in UI; backend stubs only
- [x] RAG used only for knowledge retrieval — UI never calls RAG
- [x] MCP tools schema-validated — UI never calls MCP; activity labels are generic contract events
- [x] Security: untrusted docs/tool output; no secrets in browser; display-only citations
- [x] Tests cover affected subsystems without paid cloud; observability = visible stream/error states locally
- [x] No unjustified complexity — keep multi-repo from Phase 1 (already justified); no new services
- [x] Docs/ADR impact noted — research.md decisions + quickstart + contract OpenAPI 0.2.0

Violations MUST be listed in Complexity Tracking below with justification.

### Post-design Constitution Check (Phase 1)

Re-validated after `research.md`, `data-model.md`, `contracts/`, and `quickstart.md`: gates still pass. UI remains independent via contracts package; streaming/multi-conversation are additive contract MINOR (`0.2.0`); assistant-ui retained per constitution; zero paid deps; mock enables local DoD without cloud.

## Project Structure

### Documentation (this feature)

```text
specs/002-conversational-ui/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── README.md
│   ├── ui-backend-chat.openapi.yaml
│   ├── stream-events.md
│   └── versioning.md
├── checklists/
│   └── requirements.md
└── tasks.md             # /speckit.tasks — not created here
```

### Source Code (ai-assistant workspace — sibling repositories)

```text
ai-assistant/
├── ai-assistant-spec-hub/                 # this plan/spec
├── ai-assistant-contracts/                # bump to 0.2.0
│   └── src/chat/                          # + conversations, stream events, citation.snippet
├── ai-assistant-ui/                       # PRIMARY Phase 2 implementation
│   ├── src/
│   │   ├── adapters/
│   │   │   ├── httpBackendAdapter.ts      # SSE stream + list/create/get
│   │   │   ├── localAgentAdapter.ts       # optional legacy stub
│   │   │   └── mockBackend/               # persisting contract-faithful mock
│   │   ├── conversation/                  # list/create/switch controller + queue/Stop
│   │   ├── components/
│   │   │   ├── ConversationList.tsx
│   │   │   ├── Thread.tsx
│   │   │   ├── CitationsPanel.tsx         # display-only
│   │   │   ├── ActivityStatus.tsx
│   │   │   └── RuntimeProvider.tsx
│   │   ├── App.tsx
│   │   └── main.tsx
│   ├── package.json                       # pin contracts 0.2.0; no RAG/MCP/LLM deps
│   └── README.md
└── ai-assistant-backend/                  # minimal Phase 2 support
    └── src/
        ├── routes/conversations.ts        # list/create/messages
        ├── routes/stream.ts               # SSE stub stream
        └── store/                         # in-memory conversation persistence for local demo
```

**Structure Decision**: Continue sibling multi-repo layout from Phase 1. Phase 2 does **not** introduce new repositories. Implementation center of gravity is `ai-assistant-ui`; contracts package owns wire schemas; backend adds the minimum surface for integrated streaming + persistence. RAG/MCP repos are out of scope for direct UI work.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
| ----------- | ------------ | ------------------------------------- |
| Multi-repository (vs modular monolith) | Inherited Phase 1 platform topology; UI/contracts/backend remain separate ownership units | Collapsing into monolith would undo Phase 1 contract enforcement goals |
| Backend work inside a “UI phase” | Spec requires backend-backed IDs, reload restore, and integrated smoke through public API | Mock-only forever cannot satisfy FR-016/019 integrated path |

## Implementation Approach (for `/speckit.tasks`)

1. **Contracts 0.2.0**: Add Zod/OpenAPI types for conversations, messages list, stream events, citation `snippet`/`url`; publish/link; pin in UI + backend.
2. **Persisting mock** in UI: Implement list/create/get/stream + abort; power Vitest (queue, Stop, citations, activity, reload) and `VITE_USE_MOCK_BACKEND=true`.
3. **UI shell**: Conversation list + active thread; wire assistant-ui runtime to stream adapter; loading/error/empty states.
4. **Client orchestration**: Single-slot queue, Stop/abort, switch-cancels-stream, draft restore rules per clarifications.
5. **Enrichment UI**: Display-only citations; generic activity status from stream events only.
6. **Backend stub**: In-memory store + SSE route emitting deltas (optional fake citation/activity) so integrated mode works without real LLM.
7. **Docs**: Update UI README + this quickstart; assert no forbidden deps in CI if practical.
8. **Verify**: Isolated `pnpm test` + mock demo; integrated UI→backend smoke against checklist in quickstart.
