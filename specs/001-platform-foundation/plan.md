# Implementation Plan: Platform Foundation & Repository Contracts

**Branch**: `001-platform-foundation` | **Date**: 2026-09-20 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-platform-foundation/spec.md`

## Summary

Establish the multi-repository foundation for the ai-assistant workspace: create `ai-assistant-backend`, `ai-assistant-rag`, `ai-assistant-mcp`, and `ai-assistant-contracts`; adapt existing `ai-assistant-ui`; document ownership and env conventions; ship a semver contracts package consumed by all runtime repos; prove each repo runs/tests in isolation; and deliver one local integrated smoke path UI → backend → RAG + MCP stub surfaces with no paid cloud and no inter-service auth.

## Technical Context

**Language/Version**: TypeScript 5.x+ / Node.js 22 LTS (align engines across repos); UI already on TypeScript ~6 + React 19  
**Primary Dependencies**: pnpm (matches `ai-assistant-ui`); Vitest; oxlint; Prettier; Hono (lightweight HTTP for backend/RAG stubs); `@modelcontextprotocol/sdk` (MCP stub server); Zod (schema validation shared via contracts where appropriate); `@assistant-ui/react` (existing UI) — all free/OSS, $0  
**Storage**: None required for Phase 1 beyond in-memory/fixture stubs (no vector DB, no S3)  
**Testing**: Vitest unit + contract schema tests; per-repo isolated suites; one documented integrated smoke (manual or scripted HTTP checks) without paid cloud  
**Target Platform**: Local-first developer machines (macOS/Linux); AWS not used in this phase  
**Project Type**: Multi-repository workspace (intentional deviation from modular monolith — see Complexity Tracking)  
**Performance Goals**: Per-repo local setup < 15 min; integrated smoke < 20 min after install (from spec SC-002/SC-009); no latency SLOs for stub surfaces  
**Constraints**: $0 infra; secrets never committed; no inter-service auth; contracts only via versioned package; no path imports of sibling `src`; TypeScript everywhere  
**Scale/Scope**: Skeleton/stub surfaces + contracts + standards + one smoke path; not full RAG quality, rich tools, or production LLM orchestration

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*
*Source: `.specify/memory/constitution.md` (TypeScript RAG AI Agent Platform)*

- [x] TypeScript/Node for frontend and agent services; secrets not in source control
- [x] Clear UI → Agent → (RAG | MCP) separation; UI not coupled to agent internals
- [x] Feature runs locally without AWS; paid/cloud deps optional and documented
- [x] Zero-cost default: any paid service justified (why, alternatives, cost, removable?) — none required
- [x] Provider-specific code behind interfaces (LLM, embeddings, vector, storage) — stubs only in Phase 1; adapters deferred
- [x] RAG used only for knowledge retrieval—not for authoritative structured queries — stub retrieve contract only
- [x] MCP tools schema-validated, independently testable; no blind tool-calling — minimal stub tools with schemas
- [x] Security: untrusted docs/tool output; no prompt-injection override — stub phase documents trust model; no public exposure
- [x] Tests cover affected subsystems without paid cloud; observability path considered — structured console logs for smoke hops
- [x] No unjustified complexity (K8s, microservices, managed vector DB, etc.) — **exception**: multi-repo (justified below)
- [x] Docs/ADR impact noted if architecture or cost posture changes — ownership map + research.md decisions

Violations MUST be listed in Complexity Tracking below with justification.

### Post-design Constitution Check (Phase 1)

Re-validated after `research.md`, `data-model.md`, `contracts/`, and `quickstart.md`: gates still pass; multi-repo exception unchanged; no paid services introduced; contract package enforces UI independence from backend internals.

## Project Structure

### Documentation (this feature)

```text
specs/001-platform-foundation/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── README.md
│   ├── ui-backend-chat.openapi.yaml
│   ├── backend-rag-retrieve.openapi.yaml
│   ├── backend-mcp-capabilities.md
│   └── versioning.md
└── tasks.md             # Phase 2 (/speckit.tasks — not created here)
```

### Source Code (ai-assistant workspace — sibling repositories)

```text
ai-assistant/                          # workspace root (not a monorepo)
├── ai-assistant.code-workspace
├── ai-assistant-spec-hub/             # specs, constitution, planning (this repo)
├── ai-assistant-ui/                   # existing React + assistant-ui
│   ├── src/adapters/                  # swap local stub → HTTP backend client
│   ├── package.json                   # depends on @hazemgharib/ai-agent-contracts
│   └── .github/workflows/ci.yml
├── ai-assistant-contracts/            # NEW — versioned contracts package
│   ├── src/
│   │   ├── chat/                      # UI↔backend types + zod
│   │   ├── retrieve/                  # backend↔RAG
│   │   ├── mcp/                       # backend↔MCP capability descriptors
│   │   └── index.ts
│   ├── package.json                   # name: @hazemgharib/ai-agent-contracts
│   └── .github/workflows/ci.yml
├── ai-assistant-backend/              # NEW — orchestration HTTP service
│   ├── src/
│   │   ├── server.ts
│   │   ├── routes/chat.ts
│   │   ├── clients/ragClient.ts
│   │   ├── clients/mcpClient.ts
│   │   └── orchestration/stubOrchestrator.ts
│   ├── package.json
│   └── .github/workflows/ci.yml
├── ai-assistant-rag/                  # NEW — retrieval stub HTTP service
│   ├── src/
│   │   ├── server.ts
│   │   └── routes/retrieve.ts
│   ├── package.json
│   └── .github/workflows/ci.yml
└── ai-assistant-mcp/                  # NEW — MCP stub server
    ├── src/
    │   ├── server.ts
    │   └── tools/                     # e.g. ping / echo for smoke
    ├── package.json
    └── .github/workflows/ci.yml
```

**Structure Decision**: Sibling git repositories under `ai-assistant/` (not a packages/ modular monolith). Spec clarifications require multi-repo ownership, independent run/test, and a dedicated contracts package. Each runtime repo is a minimal TypeScript Node (or Vite UI) project with identical script names (`dev`, `test`, `lint`, `typecheck`, `format`) and GitHub Actions CI baseline. Platform ownership map and integrated smoke instructions live primarily in `ai-assistant-spec-hub` docs (quickstart + optional `overall-context/ownership.md` during implementation) with per-repo READMEs linking back.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
| ----------- | ------------ | ------------------------------------- |
| Multi-repository layout instead of modular monolith (`packages/*`) | Spec Phase 1 explicitly requires separate repos with independent run/test, clear ownership, and contract-only integration; clarifications locked canonical repo names and contracts package | Single modular monolith would blur ownership demos and allow accidental internal imports across “packages”; multi-repo forces the contract boundary the platform is teaching |
| Separate process per capability (backend, RAG, MCP) | Needed to prove communication boundaries and integrated smoke across stubs | In-process modules would not exercise versioned contracts or failure attribution across services |

## Implementation Approach (for `/speckit.tasks`)

1. Bootstrap `ai-assistant-contracts` (`@hazemgharib/ai-agent-contracts` v0.1.0) from OpenAPI/MD contracts in this feature folder.
2. Scaffold backend, RAG, MCP repos with shared TS/lint/test/CI conventions; adapt UI to same conventions where missing (tests, format, CI).
3. Implement stub HTTP/MCP surfaces conforming to contracts; wire backend stub orchestrator to call RAG retrieve + MCP tool for smoke.
4. Point UI adapter at backend chat endpoint (env-configured); keep local-only stub adapter as fallback for isolated UI runs.
5. Document ownership map, env vars, ports, package install (`pnpm pack` / `file:`), and integrated smoke checklist in quickstart + READMEs.
6. Verify SC checklist: isolated tests green; integrated smoke completes; no sibling `src` path deps.
