# Data Model: Conversational UI Repository

**Feature**: `002-conversational-ui`  
**Date**: 2026-09-20  
**Source of truth for wire shapes**: `@hazemgharib/ai-agent-contracts` ≥ `0.2.0` (see `contracts/`)

UI holds **view models** derived from contract DTOs. Persistence of conversations/messages is **backend or contract-faithful mock**, not browser-local source of truth (except ephemeral UX: active ID hint, composer draft, queue).

---

## Entities

### Conversation

| Field | Type | Rules |
|-------|------|--------|
| `conversationId` | UUID string | Required; opaque to UI beyond select/correlate |
| `title` | string \| null | Optional; UI may show truncated first message if null |
| `createdAt` | ISO-8601 datetime | Required on create/list |
| `updatedAt` | ISO-8601 datetime | Required on list; updates when messages append |

**Relationships**: Has many `Message`. Listed via `GET /v1/conversations`.

**Lifecycle**:

```text
[none] --create--> active (empty messages)
active --send/stream--> active (messages append)
active --switch away--> inactive (stream aborted; queue discarded)
any --reload--> re-fetched from backend/mock (list + selected messages)
```

---

### Message (Turn)

| Field | Type | Rules |
|-------|------|--------|
| `messageId` | UUID string | Required |
| `conversationId` | UUID string | Required; must match active conversation |
| `role` | `user` \| `assistant` | Required |
| `content` | string | User: minLength 1 on send; assistant may be partial while streaming |
| `createdAt` | ISO-8601 datetime | Required |
| `status` | `complete` \| `streaming` \| `stopped` \| `error` | UI view-state; wire may omit and UI derives from stream lifecycle |
| `citations` | Citation[] | Optional; only on assistant; absent ⇒ no citation chrome |
| `activities` | ActivityEvent[] | Optional progressive log for the turn (UI may show latest only) |

**Validation**: Empty user content MUST NOT create a message or network call. Malformed citation/activity MUST be ignored without dropping `content`.

---

### Citation (display-only)

| Field | Type | Rules |
|-------|------|--------|
| `documentId` | string | Required |
| `source` | string | Required (label / path / plain URL text) |
| `title` | string \| null | Optional |
| `snippet` | string \| null | Optional excerpt for expand panel |
| `chunkId` | string \| null | Optional |
| `url` | string \| null | Optional; **display as text only** in Phase 2 (no navigation requirement) |

**Relationships**: Belongs to an assistant `Message`. UI MUST NOT fetch corpora or open external links as acceptance criteria.

---

### ActivityEvent

| Field | Type | Rules |
|-------|------|--------|
| `activityId` | string | Required (uuid or opaque) |
| `kind` | `retrieval` \| `tool` \| `other` | Required; unknown → treat as `other` |
| `label` | string | Required; user-facing generic status (no internal hostnames) |
| `status` | `started` \| `completed` \| `failed` | Required |
| `at` | ISO-8601 datetime | Required |

**Relationships**: Emitted during streaming for the in-progress assistant turn; not a handle to RAG/MCP.

---

### StreamEvent (wire)

Discriminated union consumed by the UI adapter:

| `type` | Payload | UI effect |
|--------|---------|-----------|
| `message.delta` | `{ messageId, delta }` | Append text to streaming assistant turn |
| `citation` | `{ messageId, citation }` | Attach display-only citation |
| `activity` | `{ messageId, activity }` | Update activity indicator |
| `message.completed` | `{ messageId, message }` | Finalize turn; may flush send queue |
| `error` | `{ code, message }` | Error state; do not auto-send queue |

---

### ClientEphemeralState (UI-only, not persisted by contract)

| Field | Rules |
|-------|--------|
| `activeConversationId` | Current selection; may hint via `sessionStorage` |
| `queuedFollowUp` | At most one string; latest wins; cleared on Stop/switch/successful auto-send |
| `inFlightAbortController` | Aborted on Stop or conversation switch |
| `composerDraft` | Local text; may receive restored queue after Stop |

---

## State transitions (streaming turn)

```text
idle --user send--> streaming
streaming --delta/citation/activity--> streaming
streaming --completed--> idle  --> (if queue non-empty) auto-send --> streaming
streaming --error--> idle (queue NOT auto-sent; draft may restore)
streaming --Stop--> stopped (partial content kept; queue discarded → composer)
streaming --switch conversation--> abandoned (queue discarded)
```

---

## Identity & uniqueness

- `conversationId` / `messageId`: UUID; uniqueness enforced by backend/mock.
- UI MUST NOT invent parallel conversation stores that cannot round-trip list/create/get/stream.
- Reload restore: re-list conversations + re-fetch messages for selected id; ephemeral queue/stream need not survive.
