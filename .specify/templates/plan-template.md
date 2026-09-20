# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]
**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

[Extract from feature spec: primary requirement + technical approach from research]

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. The structure here is presented in advisory capacity to guide
  the iteration process.
-->

**Language/Version**: TypeScript / Node.js [or NEEDS CLARIFICATION]  
**Primary Dependencies**: [e.g., assistant-ui, MCP SDK, local vector store — justify paid/lock-in]  
**Storage**: [local docs/vectors by default; AWS S3/OpenSearch as portable adapters]  
**Testing**: [unit/integration/evaluation without paid cloud — or NEEDS CLARIFICATION]  
**Target Platform**: Local-first MVP; AWS as deployment target (not hard dependency)  
**Project Type**: Modular monolith (packages: agent, rag, mcp, llm, storage, ui)  
**Performance Goals**: [domain-specific or NEEDS CLARIFICATION; defer premature optimization]  
**Constraints**: $0 default infra; secrets never in repo; provider adapters; security for untrusted RAG/tool I/O  
**Scale/Scope**: [domain-specific, e.g., MVP RAG + MCP + orchestration demo or NEEDS CLARIFICATION]

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*
*Source: `.specify/memory/constitution.md` (TypeScript RAG AI Agent Platform)*

- [ ] TypeScript/Node for frontend and agent services; secrets not in source control
- [ ] Clear UI → Agent → (RAG | MCP) separation; UI not coupled to agent internals
- [ ] Feature runs locally without AWS; paid/cloud deps optional and documented
- [ ] Zero-cost default: any paid service justified (why, alternatives, cost, removable?)
- [ ] Provider-specific code behind interfaces (LLM, embeddings, vector, storage)
- [ ] RAG used only for knowledge retrieval—not for authoritative structured queries
- [ ] MCP tools schema-validated, independently testable; no blind tool-calling
- [ ] Security: untrusted docs/tool output; no prompt-injection override of system instructions
- [ ] Tests cover affected subsystems without paid cloud; observability path considered
- [ ] No unjustified complexity (K8s, microservices, managed vector DB, etc.)
- [ ] Docs/ADR impact noted if architecture or cost posture changes

Violations MUST be listed in Complexity Tracking below with justification.

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)
<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete layout
  for this feature. Delete unused options and expand the chosen structure with
  real paths (e.g., apps/admin, packages/something). The delivered plan must
  not include Option labels.
-->

```text
# Preferred (constitution): modular monolith with package boundaries
packages/
├── agent/          # orchestration
├── rag/            # ingest + retrieve
├── mcp/            # tools/capabilities
├── llm/            # provider adapters
├── storage/        # docs/vectors/objects
└── ui/             # conversational UI (e.g. assistant-ui)

# [REMOVE IF UNUSED] Alternative: apps + packages
apps/
├── web/
└── api/
packages/
├── agent/
├── rag/
├── mcp/
├── llm/
└── storage/

tests/              # or co-located per package
├── unit/
├── integration/
└── evaluation/     # RAG/tool-selection cases (no paid cloud required)
```

**Structure Decision**: [Document the selected structure and reference the real
directories captured above. Prefer modular monolith over microservices unless
Complexity Tracking justifies otherwise.]

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
| ----------- | ------------ | ------------------------------------- |
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
