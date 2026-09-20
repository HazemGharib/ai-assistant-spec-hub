# Research: Platform Foundation & Repository Contracts

**Feature**: `001-platform-foundation`  
**Date**: 2026-09-20

All Technical Context unknowns are resolved below. No remaining NEEDS CLARIFICATION.

---

## 1. Multi-repo vs modular monolith

**Decision**: Sibling repositories under `ai-assistant/` workspace (`ai-assistant-ui`, `ai-assistant-backend`, `ai-assistant-rag`, `ai-assistant-mcp`, `ai-assistant-contracts`, plus `ai-assistant-spec-hub`).

**Rationale**: Spec clarifications mandate independent run/test, dedicated contracts home, and canonical multi-repo names. Constitution prefers modular monolith for simplicity, but Phase 1’s teaching/ownership goal requires hard boundaries; Complexity Tracking records the exception.

**Alternatives considered**:

- Single modular monolith with `packages/*` — simpler ops, but weakens contract enforcement and contradicts clarified topology
- Monorepo with npm/pnpm workspaces — still one git history; rejected for same ownership reasons as monolith

---

## 2. Package manager

**Decision**: **pnpm** across all new repositories (match existing `ai-assistant-ui` `packageManager: pnpm@10.9.0`).

**Rationale**: Consistency for contributors; workspace already uses pnpm; strong support for `file:` and packed tarball installs.

**Alternatives considered**:

- npm — works, but diverges from UI
- yarn — unnecessary second toolchain

---

## 3. Contracts package distribution (local / $0)

**Decision**: Publish `@hazemgharib/ai-agent-contracts` as a normal package with semver in `package.json`. For Phase 1 local/offline consumption:

1. In contracts repo: `pnpm pack` → produces `ai-assistant-contracts-0.1.0.tgz` (or equivalent name)
2. Consumers depend on `"@hazemgharib/ai-agent-contracts": "0.1.0"` resolved via `"@hazemgharib/ai-agent-contracts": "file:../ai-assistant-contracts"` **or** `file:../path/to/ai-assistant-contracts-0.1.0.tgz`
3. Prefer **`file:../ai-assistant-contracts`** during active development with a CI/script check that consumer’s required version range is satisfied by the contracts package version
4. Document that a private registry is optional later; not required for Phase 1

**Rationale**: Satisfies FR-018 (versioned package, no `src` path imports) without a paid registry. Semver lives on the package; consumers pin an explicit version.

**Alternatives considered**:

- Public npm publish — not needed for private learning MVP; adds account/token friction
- Git submodule / raw `src` path — violates FR-015/018
- Vendoring copies of types into each repo — drifts; rejected by clarification Option A

---

## 4. HTTP framework for backend & RAG stubs

**Decision**: **Hono** on Node.js for `ai-assistant-backend` and `ai-assistant-rag` HTTP surfaces.

**Rationale**: Tiny, TypeScript-first, easy route typing, $0, sufficient for stubs; avoids Express legacy baggage for greenfield services.

**Alternatives considered**:

- Native `node:http` — fewer deps, more boilerplate
- Express/Fastify — fine but heavier than needed for Phase 1 stubs
- NestJS — unjustified complexity

---

## 5. MCP stub approach

**Decision**: Use official **`@modelcontextprotocol/sdk`** with a stdio **or** Streamable HTTP transport suitable for local smoke. Prefer **Streamable HTTP / SSE-style local endpoint** if the SDK version supports easy HTTP for backend client; otherwise stdio launched as a child process from backend for smoke. Document the chosen transport in the MCP repo README.

**Rationale**: Aligns with constitution MCP ownership; schema-validated tools; independent testability.

**Alternatives considered**:

- Fake HTTP “MCP-like” API without SDK — simpler but diverges from real MCP and hurts later phases
- Full MCP feature set — out of scope; stub with `ping`/`echo` (or one smoke tool) only

---

## 6. Schema / validation library

**Decision**: **Zod** schemas colocated in `@hazemgharib/ai-agent-contracts`, with TypeScript types inferred/exported. OpenAPI YAML in `specs/.../contracts/` remains the human/design source; package implements equivalent runtime schemas.

**Rationale**: Runtime validation at service boundaries; shared between consumers/providers; TypeScript ergonomics.

**Alternatives considered**:

- TypeBox / JSON Schema only — workable; Zod is more common in TS Node ecosystems
- Types-only (no runtime) — weaker for stub servers and smoke error attribution

---

## 7. Testing & quality toolchain

**Decision**:

- **Vitest** — unit/contract tests in every runtime + contracts repo
- **oxlint** — lint (already on UI)
- **Prettier** — format (UI lacks it today; add for consistency)
- Scripts (canonical names): `dev`, `build`, `test`, `lint`, `typecheck`, `format`, `format:check`
- **GitHub Actions** CI per repo: install → lint → typecheck → test (and build where applicable)

**Rationale**: Match UI lint choice; Vitest is fast and TS-native; identical script names satisfy FR-013.

**Alternatives considered**:

- Jest — heavier
- ESLint — UI already chose oxlint
- Skipping format tooling — leads to drift across five repos

---

## 8. Default local ports & env keys

**Decision**:

| Service | Default port | Env (consumer) | Env (provider listen) |
| --------- | ------------- | ---------------- | ------------------------ |
| UI (Vite) | 5173 | `VITE_BACKEND_BASE_URL` | — |
| Backend | 3001 | `RAG_BASE_URL`, `MCP_SERVER_URL` / transport config | `PORT` |
| RAG | 3002 | — | `PORT` |
| MCP | 3003 (if HTTP) | — | `PORT` |

Isolated mode: each service runs with fixtures/fakes; missing siblings do not fail unit tests. Integrated mode: document starting order contracts → RAG → MCP → backend → UI.

**Rationale**: Stable defaults for smoke docs; env-based wiring satisfies FR-010.

---

## 9. UI integration path

**Decision**: Keep `localAgentAdapter` for isolated UI runs (no backend). Add `httpBackendAdapter` (or extend adapter selection via `VITE_BACKEND_BASE_URL`) that calls the UI↔backend chat contract. Integrated smoke uses HTTP adapter.

**Rationale**: Preserves UI independent testability (FR-009) while enabling SC-009 smoke.

**Alternatives considered**:

- Always require backend — breaks isolated UI story
- Embedding orchestration in UI — violates ownership

---

## 10. Backend orchestration depth (Phase 1)

**Decision**: **Deterministic stub orchestrator** — for smoke prompts, call RAG retrieve and/or MCP tool by simple keyword/rule routing (no real LLM required). Optionally accept a later `LLM_PROVIDER=none|stub` env.

**Rationale**: Phase 1 proves contracts and wiring, not model quality; $0 and deterministic tests.

**Alternatives considered**:

- Real LLM (OpenAI/Bedrock) — costs and keys; deferred
- No orchestration (echo only) — fails requirement to hit both RAG and MCP in one smoke path

---

## 11. Observability (minimal)

**Decision**: Structured stdout logs with correlation id per request: `boundary`, `contractVersion`, `durationMs`, `outcome`. No APM/SaaS.

**Rationale**: Constitution observability path “considered”; enough to debug smoke failures.

---

## 12. CI & documentation home

**Decision**: Per-repo `.github/workflows/ci.yml`. Platform ownership map and integrated smoke live in `ai-assistant-spec-hub/specs/001-platform-foundation/quickstart.md` (and linked from each README). Optional copy to workspace README during implementation.

**Rationale**: Spec-hub already owns governance docs; avoids inventing a seventh runtime repo.
