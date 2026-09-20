# Stream events (UI ↔ Backend)

Transport: **SSE** (`Content-Type: text/event-stream`) on  
`POST /v1/conversations/{conversationId}/messages:stream`.

Each SSE `data:` line is a JSON object with required `type` discriminant.

## Event types

### `message.delta`

```json
{
  "type": "message.delta",
  "messageId": "uuid",
  "delta": "partial text"
}
```

UI appends `delta` to the in-progress assistant message body.

### `citation`

```json
{
  "type": "citation",
  "messageId": "uuid",
  "citation": {
    "documentId": "doc-1",
    "source": "handbook.pdf",
    "title": "Handbook",
    "snippet": "…excerpt…",
    "chunkId": null,
    "url": null
  }
}
```

UI attaches display-only citation; never auto-navigates.

### `activity`

```json
{
  "type": "activity",
  "messageId": "uuid",
  "activity": {
    "activityId": "uuid-or-opaque",
    "kind": "retrieval",
    "label": "Searching knowledge",
    "status": "started",
    "at": "2026-09-20T12:00:00.000Z"
  }
}
```

`kind`: `retrieval` | `tool` | `other`. Unknown kinds → treat as `other`.  
UI shows generic status; MUST NOT display internal service URLs.

### `message.completed`

```json
{
  "type": "message.completed",
  "messageId": "uuid",
  "message": {
    "messageId": "uuid",
    "role": "assistant",
    "content": "full text",
    "createdAt": "2026-09-20T12:00:01.000Z"
  },
  "citations": []
}
```

Finalizes the turn. Client MAY flush a single queued follow-up send afterward.

### `error`

```json
{
  "type": "error",
  "code": "UPSTREAM_UNAVAILABLE",
  "message": "human readable",
  "boundary": "backend"
}
```

Ends the stream unsuccessfully. Client MUST NOT auto-send queued follow-up.

## Abort / Stop

Client aborts the HTTP request (AbortSignal). Server SHOULD stop generating.  
Partial deltas already sent remain valid UI content with status `stopped`.

## Malformed events

Skip invalid events; keep stream open until `message.completed`, `error`, or connection close.
