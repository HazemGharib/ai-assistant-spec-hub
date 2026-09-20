<!--
Sync Impact Report
- Version change: (template placeholders) → 1.0.0
- Modified principles: N/A (initial ratification from constitution-context.md)
  - Template PRINCIPLE_1..5 → I–IX concrete principles below
- Added sections:
  - Mission
  - Core Principles I–IX
  - Technology Standards
  - Definition of Done
  - Governance (amendment, versioning, compliance)
- Removed sections: template placeholder comments/examples
- Templates requiring updates:
  - .specify/templates/plan-template.md ✅ updated (Constitution Check gates)
  - .specify/templates/spec-template.md ✅ updated (platform constraints + DoD hints)
  - .specify/templates/tasks-template.md ✅ updated (packages paths, local/zero-cost, test boundaries)
  - .specify/templates/commands/*.md ⚠ pending (no commands directory present)
  - README.md / docs/quickstart.md ⚠ pending (not present yet)
- Follow-up TODOs: none deferred; ratification date set to adoption day
-->

# TypeScript RAG AI Agent Platform Constitution

## Mission

Build a production-oriented AI agent platform in TypeScript that combines a
minimalist conversational UI, an LLM-powered agent/orchestration layer, RAG for
document retrieval, and MCP for capabilities/tools. Development MUST be
local-first, AWS-portable, and target **$0/month** for development and MVP
operation, using paid services only when technically necessary. Infrastructure
choices MUST be able to evolve without rewriting core application logic.

## Core Principles

### I. TypeScript Platform Standard

TypeScript MUST be the primary language for frontend and backend/agent services.
Node.js MUST be used for backend/agent runtime. Prefer well-maintained open-source
packages over building infrastructure from scratch. Dependencies that introduce
significant complexity, cost, or vendor lock-in MUST be justified in writing.
Environment-specific configuration MUST be externalized. Secrets MUST NEVER be
committed to source control.

**Rationale**: A single-language stack reduces cognitive load and keeps the MVP
coherent while remaining portable across local and cloud runtimes.

### II. Layered Architecture (UI → Agent → RAG / MCP)

The architecture MUST maintain clear separation:

```text
UI → Agent Application → (RAG Retrieval | MCP Capabilities) → External systems
```

- **RAG** retrieves contextual knowledge (docs, PDFs, knowledge bases). The agent
  MUST NOT use vector search when an authoritative structured query/API is more
  appropriate (e.g., balances, live prices).
- **MCP** exposes capabilities and contextual resources (HTTP, DB, files, actions).
  MCP tools MUST have explicit schemas, predictable I/O, validation, and clear
  error handling. Business logic MUST NOT couple tightly to a specific MCP
  implementation when an abstraction is practical.

The UI MUST remain independent from agent implementation so the backend can be
replaced without redesigning the frontend. Prefer evaluating **assistant-ui**
(<https://www.assistant-ui.com/>) before building chat infrastructure from scratch.

**Rationale**: Separation keeps RAG, tools, and orchestration independently
replaceable and testable.

### III. Local-First Development

The entire MVP MUST be executable locally (e.g. `npm install && npm run dev`)
without provisioning AWS. Local development SHOULD use local document/vector
storage where practical, mock/fake MCP tools where appropriate, configurable LLM
providers, and deterministic fixtures. Cloud services MUST have local alternatives
wherever reasonably possible. AWS MUST NOT be a prerequisite for development.

**Rationale**: Fast iteration and reproducible onboarding depend on a fully local
path.

### IV. Zero-Cost by Default

The default implementation MUST target **$0 infrastructure cost** during
development and early MVP usage. Prefer, in order: local execution, open-source,
free tiers, existing infrastructure, then pay-per-use only when necessary.

Before introducing a paid AWS or third-party service, the implementation MUST
document: why it is required, why a local/free alternative is insufficient,
expected cost, and whether the dependency can be removed later. Recurring
infrastructure cost MUST NOT be introduced merely for convenience. The system
MUST remain functional locally when all paid/cloud integrations are disabled.

**Rationale**: Cost discipline prevents accidental lock-in and keeps the MVP
accessible.

### V. AWS Portability & Vendor Independence

AWS compatibility MUST be a deployment target, not a hard dependency. Core domain
and agent logic MUST NOT contain unnecessary AWS-specific code. Provider-specific
implementations (LLM, embeddings, vector store, object storage, auth, external
APIs) MUST be isolated behind interfaces/adapters when practical.

The architecture SHOULD allow swapping providers (e.g. OpenAI ↔ Bedrock ↔ local;
local vector store ↔ pgvector ↔ OpenSearch) without rewriting agent core behavior.
No single LLM, embedding provider, vector database, or cloud provider MUST be
deeply embedded in business logic.

**Rationale**: Portability preserves optionality as requirements and budgets change.

### VI. RAG as a Replaceable Subsystem

RAG MUST be implemented as a replaceable subsystem. Ingestion MUST be separated
from query-time retrieval. The pipeline SHOULD follow: Document → Parse →
Normalize → Chunk → Embed → Store → Retrieve → Optional rerank → LLM context.

Retrieved chunks SHOULD retain metadata (`documentId`, `source`, `title`,
`page/section`, `chunkId`, `createdAt/version`). The agent SHOULD provide
citations or source references when retrieved information supports a user-facing
factual answer. RAG retrieval MUST be testable independently from the LLM.

**Rationale**: Independent RAG quality evaluation and provider swap require a
clear subsystem boundary.

### VII. Agent Orchestration Discipline

The agent MUST separate: user input → reasoning/orchestration → retrieval/tool
selection → execution → response. The agent MUST NOT blindly call every available
tool. Tools MUST be explicitly registered, schema-validated, permission-aware
where relevant, observable, and independently testable.

The agent MUST gracefully handle missing information, retrieval/tool/LLM
failures, invalid arguments, timeouts, and external API failures. Prefer
deterministic application logic over LLM reasoning when deterministic logic is
sufficient. Do not use MCP merely for the sake of using MCP.

**Rationale**: Controlled tool use and failure handling keep the agent reliable
and auditable.

### VIII. Security by Design

Security MUST be part of the architecture, not a later enhancement.

MUST:

- Never expose secrets to the browser
- Validate all tool inputs and, where practical, external API responses
- Apply least privilege
- Prevent arbitrary code execution unless explicitly implemented as a controlled
  capability
- Treat retrieved documents and tool output as untrusted
- Protect against prompt injection from documents or external sources
- Never allow retrieved content to override system/developer instructions

Dangerous capabilities (shell execution, filesystem modification, database writes,
external side effects) MUST require explicit authorization boundaries.

**Rationale**: Agents that read untrusted content and invoke tools are high-risk
by default; boundaries must be designed in.

### IX. Simplicity, Testability & Observability

Prefer a modular monolith and simple architecture over premature infrastructure.
Do NOT introduce Kubernetes, microservices, complex event buses, managed vector
databases, complex agent frameworks, or multiple cloud services unless a real need
is demonstrated. Prefer clear module boundaries (e.g. `packages/agent`, `rag`,
`mcp`, `llm`, `storage`, `ui`). Avoid unnecessary abstractions until justified.

Every major subsystem MUST be independently testable (parsing, chunking,
embedding, retrieval, RAG context construction, MCP tools, orchestration, API,
UI). Tests MUST NOT require paid cloud services. RAG quality and tool-selection
quality MUST be evaluated separately from general LLM quality.

Observability MUST make it possible to follow: user question → retrieved docs →
selected tools → tool I/O → LLM request/response metadata → final response.
Sensitive data MUST NOT be logged unnecessarily. Logging SHOULD support local
debugging first and AWS-compatible observability later.

Implementation priority MUST be: Correctness → Simplicity → Testability →
Security → Portability → Performance optimization. Do not optimize prematurely.

**Rationale**: Complexity compounds fastest in agent systems; simplicity and
visibility keep the platform maintainable.

## Technology Standards

- Frontend and backend MUST be TypeScript; backend/agent services run on Node.js.
- UI SHOULD prefer an existing AI/chat framework (evaluate assistant-ui first).
- Significant architectural decisions MUST be documented (ADRs or equivalent).
- The repository MUST contain concise docs covering: local setup, environment
  variables, architecture, RAG pipeline, MCP tools, testing, AWS deployment, cost
  implications, and security considerations. Architecture diagrams SHOULD be kept
  current alongside documentation.

## Definition of Done

A feature is complete only when all of the following hold:

- It works locally and is implemented in TypeScript
- It has appropriate automated tests that do not require paid infrastructure
- Dependencies are documented; errors are handled
- Security implications have been considered
- AWS portability has not been unnecessarily compromised
- No unnecessary infrastructure complexity was introduced

The MVP MUST ultimately demonstrate three independently understandable, testable,
and replaceable capabilities:

1. **RAG** — answer from documents ("What does this document say?")
2. **MCP** — perform an external operation
3. **Agent orchestration** — decide whether to retrieve, invoke a tool, or both

## Governance

This constitution supersedes conflicting informal practices. All specs, plans,
tasks, and PRs MUST be reviewed for compliance with these principles.

**Amendments**: Propose changes with rationale, impact on existing features, and
migration notes if principles are tightened or removed. Record amendments in this
file's Sync Impact Report comment and bump `CONSTITUTION_VERSION` per semantic
versioning:

- **MAJOR**: Backward-incompatible removals or redefinitions of principles
- **MINOR**: New principle/section or materially expanded guidance
- **PATCH**: Clarifications, wording, non-semantic refinements

**Compliance review**: At plan time (Constitution Check gate), before task
generation, and at PR review. Complexity Tracking in plans MUST justify any
principle violation. Use this file as the authoritative runtime governance
reference for Speckit workflows.

**Version**: 1.0.0 | **Ratified**: 2026-09-20 | **Last Amended**: 2026-09-20
