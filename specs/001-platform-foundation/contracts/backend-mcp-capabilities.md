# Backend ↔ MCP Capabilities Contract

**Contract ID**: `backend-mcp-capabilities`  
**Package module**: `@hazemgharib/ai-agent-contracts/mcp`  
**Version**: follows `@hazemgharib/ai-agent-contracts` semver (initial `0.1.0`)  
**Provider**: `ai-assistant-mcp`  
**Consumer**: `ai-assistant-backend`  
**Auth**: none (Phase 1 localhost trust)

## Purpose

Expose a minimal, schema-validated tool surface so the backend can invoke at least one tool during the integrated smoke path. Full MCP tool packs are out of scope.

## Required Phase 1 tool

### `smoke_ping`

| Field | Value |
| ------- | -------- |
| name | `smoke_ping` |
| description | Returns a fixed acknowledgment for integrated smoke verification |
| input | `{ "nonce": string }` (required, minLength 1) |
| output (ok) | `{ "ok": true, "echo": string, "server": "ai-assistant-mcp" }` |
| output (error) | `{ "ok": false, "error": { "code": "VALIDATION_ERROR" \| "INTERNAL_ERROR", "message": string } }` |

## Transport

Phase 1 implementation MAY use either:

1. **MCP SDK stdio** — backend spawns `ai-assistant-mcp` as a child process, or
2. **MCP over HTTP** on `http://127.0.0.1:3003` — if chosen, document exact endpoint paths in the MCP repo README

The contracts package MUST export:

- `SmokePingInput` / `SmokePingOutput` Zod schemas (or equivalent)
- `listSmokeTools()` descriptor list used by backend registration
- Shared error codes aligned with other boundaries: `VALIDATION_ERROR`, `UPSTREAM_UNAVAILABLE`, `INTERNAL_ERROR`

## Backend obligations

- Validate tool name and arguments before invoke
- Map transport failures to `UPSTREAM_UNAVAILABLE`
- Include a `ToolInvocationSummary` in chat diagnostics when MCP is used

## Independent test expectations

- MCP repo tests register `smoke_ping` and reject invalid input without starting backend/UI
- Backend tests call MCP via fake/double in isolated mode; live transport only in integrated smoke
