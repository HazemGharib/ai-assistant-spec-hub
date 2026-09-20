# Feature Specification: Platform Foundation & Repository Contracts

**Feature Branch**: `001-platform-foundation`  
**Created**: 2026-09-20  
**Status**: Draft  
**Input**: User description: "Phase 1 — Platform Foundation & Repository Contracts. Establish the multi-repository architecture with separate repositories in the current ai-assistant workspace for UI (already existing), backend/agent, RAG, MCP, and shared contracts where justified. Define clear ownership and responsibilities for each repository, including API boundaries, environment configuration, versioning, and communication protocols. Each repository MUST be independently runnable and testable locally, while integration MUST rely on explicit contracts rather than shared implementation details. Establish common TypeScript standards, testing, linting, formatting, CI conventions, and documentation across repositories."

## Clarifications

### Session 2026-09-20

- Q: Should Phase 1 create a dedicated shared-contracts repository now, or only when 2+ consumers share a schema? → A: Create contracts repo in Phase 1 as the canonical home for all cross-repo boundary contracts (UI↔agent, agent↔RAG, agent↔MCP)
- Q: Must Phase 1 prove multi-repo integration, or only per-repo isolation? → A: Isolation plus one integrated local smoke path across UI → agent → RAG and MCP stub surfaces using contracts
- Q: How do runtime repositories obtain contract definitions from the contracts repository? → A: Versioned package: runtime repos depend on a semver-versioned contracts package produced by the contracts repository
- Q: What local inter-service trust model applies in Phase 1? → A: No inter-service auth in Phase 1: local services trust localhost/private URLs; production auth is out of scope
- Q: What are the canonical repository names? → A: `ai-assistant-ui`, `ai-assistant-backend`, `ai-assistant-rag`, `ai-assistant-mcp`, `ai-assistant-contracts`

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Establish Clear Repository Ownership Map (Priority: P1)

A platform contributor opens the workspace and can immediately see which repositories exist, what each owns, what it must never own, and how it talks to others—without reading implementation code.

**Why this priority**: Without explicit ownership and boundaries, later features will blur RAG, MCP, agent, and UI responsibilities and recreate the coupling this phase exists to prevent.

**Independent Test**: Review the ownership map and repository READMEs alone; a new contributor can correctly assign a sample change (e.g., “add a retrieval endpoint”) to exactly one owning repository.

**Acceptance Scenarios**:

1. **Given** the ai-assistant workspace, **When** a contributor reads the platform ownership documentation, **Then** they can list every runtime repository, its primary responsibility, and its non-responsibilities.
2. **Given** a proposed change that spans concerns (e.g., “expose document search to the chat UI”), **When** the contributor consults ownership rules, **Then** they can identify the owning repository for each part and the contract(s) that must change—not a shared private implementation.
3. **Given** the existing UI repository, **When** ownership is documented, **Then** the UI is explicitly limited to presentation and client-side conversation UX and is not the owner of agent, RAG, or MCP logic.

---

### User Story 2 - Run and Test Any Repository in Isolation (Priority: P1)

A developer clones a single repository (`ai-assistant-ui`, `ai-assistant-backend`, `ai-assistant-rag`, or `ai-assistant-mcp`), installs dependencies, runs the local entrypoint and the automated test suite, and verifies that repository’s behavior without starting the rest of the platform—or without paid cloud services.

**Why this priority**: Independent local runnability and testability is the Definition of Done baseline for every subsystem and the primary guardrail against accidental monolith coupling.

**Independent Test**: For each runtime repository, perform install → run → test using only that repository’s documented steps and local configuration; success does not require sibling repositories to be running unless a documented optional integration mode is opted into.

**Acceptance Scenarios**:

1. **Given** only one runtime repository checked out, **When** a developer follows that repository’s local setup documentation, **Then** they can start its local process and exercise a documented health or smoke path.
2. **Given** only one runtime repository checked out, **When** they run its automated tests, **Then** the suite completes without requiring paid cloud credentials or live sibling services (stubs/fixtures allowed).
3. **Given** a repository that normally calls another service, **When** that dependency is unavailable, **Then** unit/contract tests still pass using documented doubles; failure mode for live integration is explicit and non-blocking for the isolated suite.

---

### User Story 2b - Prove One Integrated Local Smoke Path (Priority: P1)

A developer starts the documented integrated local profile (`ai-assistant-ui`, `ai-assistant-backend`, `ai-assistant-rag` stub/surface, `ai-assistant-mcp` stub/surface, and `ai-assistant-contracts`) and completes one end-to-end smoke path that crosses UI → backend → RAG and MCP using only published contracts—without requiring paid cloud services or full product behavior.

**Why this priority**: Isolation alone can hide contract mismatches; one integrated smoke path validates that ownership boundaries actually compose before later phases deepen RAG/MCP/backend behavior.

**Independent Test**: Follow the workspace integrated-mode documentation; complete the smoke path checklist; success criteria do not require real document quality, rich tools, or production LLM behavior (stubs/fakes allowed behind contracts).

**Acceptance Scenarios**:

1. **Given** all Phase 1 runtime repositories and the contracts repository are available locally, **When** a developer follows the integrated smoke documentation, **Then** a single documented path succeeds from UI through backend into both RAG and MCP contract surfaces.
2. **Given** the integrated smoke path, **When** it executes, **Then** every cross-repo hop uses the contracts repository versions—not ad hoc types or internal imports.
3. **Given** a sibling service is down during integrated mode, **When** the smoke path is attempted, **Then** the failure is visible and attributable to that boundary (clear error), while each repository’s isolated suite still passes independently.

---

### User Story 3 - Integrate Only Through Explicit Contracts (Priority: P1)

A developer integrating UI ↔ backend, backend ↔ RAG, or backend ↔ MCP uses versioned, documented contracts (request/response shapes, errors, and protocol expectations)—never by importing another repository’s internal modules or copying private types ad hoc.

**Why this priority**: Contract-based integration is what makes multi-repository ownership sustainable and keeps subsystems replaceable.

**Independent Test**: Attempt to add a cross-repo call using only the versioned contracts package and docs; verify no consumer depends on another repo’s `src` internals or on a raw sibling path into the contracts repository source tree.

**Acceptance Scenarios**:

1. **Given** two repositories that must communicate, **When** integration is implemented, **Then** both sides depend on the same semver version of the contracts package and agree on success and error shapes.
2. **Given** a breaking contract change is proposed, **When** versioning rules are applied, **Then** the contracts package MAJOR version increments and consumers can detect incompatibility via dependency resolution before runtime (documented version bump and compatibility policy).
3. **Given** Phase 1 platform setup, **When** cross-repo boundaries are defined, **Then** UI↔backend, backend↔RAG, and backend↔MCP contracts all live in `ai-assistant-contracts` as the canonical home—not duplicated inside implementation repositories.
4. **Given** a provider-only implementation detail that is not part of a cross-repo boundary, **When** types are needed inside one repository only, **Then** those types stay private to that repository and are not promoted into the contracts repository.
5. **Given** local development without a public registry, **When** a developer installs a runtime repository, **Then** they can obtain the contracts package through the documented local/package distribution method while still pinning an explicit semver version.

---

### User Story 4 - Apply Consistent Engineering Standards Across Repositories (Priority: P2)

A contributor moving between repositories finds the same expectations for TypeScript quality gates: linting, formatting, testing commands, CI checks, and documentation layout—so onboarding cost does not multiply per repository.

**Why this priority**: Standards reduce friction and keep quality comparable; they are secondary to ownership and contracts but required before feature depth grows.

**Independent Test**: Compare the documented standard checklist against each repository; every repository either complies or has an explicit, time-bounded exception recorded.

**Acceptance Scenarios**:

1. **Given** any runtime repository, **When** a contributor runs the documented quality commands (lint, format check, test), **Then** those commands exist and behave consistently with the platform standard.
2. **Given** a pull request to any runtime repository, **When** continuous integration runs, **Then** the same baseline gates (at minimum: install, lint/typecheck, test) are enforced.
3. **Given** a new repository is added later, **When** contributors follow the platform conventions guide, **Then** they can stand up the same baseline structure without inventing a new style.

---

### User Story 5 - Configure Environments Without Secrets in Source Control (Priority: P2)

A developer configures each repository for local use via documented environment variables and example files, with secrets never committed, and with clear which settings are required vs optional for isolated vs integrated runs.

**Why this priority**: Environment clarity is required for independent local runs and for safe multi-repo integration.

**Independent Test**: Starting from a clean clone, copy example env files, fill required local values, and run without committing secrets.

**Acceptance Scenarios**:

1. **Given** a fresh clone of any runtime repository, **When** the developer opens environment documentation, **Then** every required variable is listed with purpose, example, and whether it is needed for isolated vs integrated mode.
2. **Given** secret values (API keys, tokens), **When** configuration is reviewed, **Then** no secrets appear in committed files; only placeholders/examples are present.
3. **Given** integrated local mode (multiple repositories), **When** developers align ports/base URLs via documented variables, **Then** they can point consumers at providers without editing code and without configuring inter-service credentials.

---

### Edge Cases

- What happens when a consumer depends on a newer contract version than the provider implements? → Compatibility check or dependency resolution fails with a clear version mismatch; silent partial compatibility is not allowed.
- What happens when a developer links the contracts repository source tree directly instead of the versioned package? → Standards and review checklist reject path coupling to contracts `src`; consumers MUST depend on the versioned contracts package only.
- What happens when a type is useful inside one repository but is not part of a cross-repo boundary? → Keep it private to that repository; do not promote it into the contracts repository.
- What happens when a developer accidentally imports another repository’s source tree (path dependency on internals)? → Standards and review checklist reject this; integration must use published contracts only.
- How does the system handle a repository that cannot yet provide a real dependency (e.g., RAG not built)? → Provider repositories ship a minimal stub/smoke surface and documented fake so consumers remain independently testable and the integrated smoke path can still complete.
- What if the integrated smoke path fails while isolated suites pass? → Treat as a Phase 1 blocking contract/integration defect; isolation success alone is not sufficient for Phase 1 completion.
- What if constitution guidance prefers a modular monolith but this phase chooses separate repositories? → Treat multi-repo as an intentional Phase 1 boundary for ownership and contracts; keep each repository small and avoid unnecessary distributed complexity (no cluster orchestration, no paid infra).
- What about unauthorized callers hitting local services? → Accepted Phase 1 risk for localhost/private development only; documentation MUST state services are not production-hardened and MUST NOT be exposed publicly without auth (future phase).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The platform MUST define a repository topology for the ai-assistant workspace with these canonical names: `ai-assistant-ui` (existing), `ai-assistant-backend`, `ai-assistant-rag`, `ai-assistant-mcp`, and `ai-assistant-contracts`; `ai-assistant-spec-hub` remains the home for specifications and governance, not a runtime service.
- **FR-002**: Each runtime repository MUST have a written ownership statement covering: purpose, in-scope responsibilities, out-of-scope responsibilities, inbound/outbound contracts, and primary consumers/providers.
- **FR-003**: `ai-assistant-ui` MUST own conversational presentation and client UX only; it MUST NOT own agent orchestration, retrieval indexing, or tool-server implementation.
- **FR-004**: `ai-assistant-backend` (formerly referred to as backend/agent) MUST own request orchestration, model interaction boundaries, and decisions about when to retrieve knowledge vs invoke tools; it MUST NOT own document index storage internals or tool-server internals beyond consuming their contracts.
- **FR-005**: `ai-assistant-rag` MUST own document ingestion/retrieval responsibilities exposed through an explicit retrieval contract; it MUST NOT own end-user chat UX or general-purpose tool execution.
- **FR-006**: `ai-assistant-mcp` MUST own tool/resource capability exposure through an explicit capability contract; it MUST NOT own chat UX or retrieval index ownership.
- **FR-007**: Integration between repositories MUST use explicit, versioned contracts (interfaces, schemas, and error semantics)—not shared private source modules across repository boundaries.
- **FR-008**: Phase 1 MUST create `ai-assistant-contracts` as the canonical home for all cross-repository boundary contracts (UI↔backend, backend↔RAG, backend↔MCP), regardless of current consumer count; implementation repositories MUST consume those contracts rather than redefine them; non-boundary/private types MUST remain inside the owning implementation repository.
- **FR-009**: Each runtime repository (`ai-assistant-ui`, `ai-assistant-backend`, `ai-assistant-rag`, `ai-assistant-mcp`) MUST be independently installable, runnable, and testable locally without paid cloud services; `ai-assistant-contracts` MUST be independently installable, versionable, package-producible, and testable (schema/contract validation) locally without requiring runtime siblings.
- **FR-010**: Each runtime repository MUST document environment configuration (required/optional variables, examples, and isolated vs integrated modes) and MUST NOT commit secrets.
- **FR-011**: The platform MUST define a contract versioning and compatibility policy using semantic versioning on the contracts package (MAJOR for breaking, MINOR for additive, PATCH for compatible fixes/docs); consumers MUST pin versions so incompatible upgrades are detectable at install/dependency resolution time.
- **FR-012**: The platform MUST define communication protocol expectations for each boundary (UI↔backend, backend↔RAG, backend↔MCP) at the contract level (message shapes, transport assumptions, and failure semantics)—without prescribing a specific cloud vendor.
- **FR-013**: The platform MUST establish common conventions across repositories for TypeScript usage, automated testing, linting, formatting, continuous integration baseline gates, and documentation structure.
- **FR-014**: Each runtime repository MUST include a README that covers purpose, local setup, how to run tests, configuration, and links to relevant contracts.
- **FR-015**: Cross-repository dependencies MUST be expressible as contract consumers/providers via the versioned contracts package; path-based coupling to another repository’s internal implementation (including the contracts repo source tree) is prohibited.
- **FR-016**: Phase 1 MUST deliver skeleton or minimal runnable surfaces for `ai-assistant-backend`, `ai-assistant-rag`, and `ai-assistant-mcp`, plus `ai-assistant-contracts` seeded with the three boundary contracts, sufficient to prove ownership, contracts, and local quality gates—full RAG quality, rich tools, and polished agent behavior are out of scope for this phase.
- **FR-017**: Phase 1 MUST provide documented integrated local mode and ONE end-to-end smoke path proving UI → backend → RAG contract surface and UI → backend → MCP contract surface (stubs/minimal fakes allowed), in addition to per-repository isolated run/test requirements.
- **FR-018**: Runtime repositories MUST obtain boundary contracts exclusively via a semver-versioned contracts package produced by `ai-assistant-contracts`; they MUST NOT import the contracts repository’s internal source tree or another repository’s internals. Local/offline installs MAY use a documented package distribution method but MUST still pin an explicit semver version.
- **FR-019**: Phase 1 MUST NOT require inter-service authentication between local runtime services (`ai-assistant-ui`, `ai-assistant-backend`, `ai-assistant-rag`, `ai-assistant-mcp`); services MAY trust configured localhost/private base URLs. End-user authentication product features and production service auth remain out of scope. Secrets MUST still never be committed or exposed to the browser.
- **FR-020**: New repositories created in Phase 1 MUST use the canonical names in FR-001; documentation and ownership maps MUST use those names consistently.

### Key Entities

- **Repository**: A separately versioned codebase in the ai-assistant workspace with a single primary ownership domain. Canonical runtime/contract names: `ai-assistant-ui`, `ai-assistant-backend`, `ai-assistant-rag`, `ai-assistant-mcp`, `ai-assistant-contracts`; governance: `ai-assistant-spec-hub`.
- **Contracts Repository**: `ai-assistant-contracts` — the dedicated, non-runtime repository that owns versioned cross-repo boundary contracts and produces the versioned contracts package; it does not own business behavior or service processes.
- **Contracts Package**: The semver-versioned distributable artifact consumers depend on to use boundary contracts; the sole allowed consumption path for cross-repo contract definitions.
- **Ownership Boundary**: The documented set of responsibilities a repository may change without requiring another repository’s implementation knowledge.
- **Contract**: A versioned, documented agreement between provider and consumer covering inputs, outputs, errors, and compatibility rules; boundary contracts live in `ai-assistant-contracts` and ship via the contracts package.
- **Communication Boundary**: A named integration edge (UI→backend, backend→RAG, backend→MCP) with an associated contract and protocol expectations.
- **Environment Profile**: Named configuration set for isolated local run vs multi-repository integrated local run.
- **Engineering Standard Baseline**: Shared expectations for language quality gates, tests, CI, formatting/linting, and docs that every runtime repository must meet.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A new contributor can correctly map 5 sample change requests to the owning repository with 100% accuracy using only ownership documentation (no code diving).
- **SC-002**: For every runtime repository, a clean-machine local setup reaches a documented runnable state in under 15 minutes (excluding dependency download variability), without paid cloud provisioning.
- **SC-003**: For every runtime repository, the isolated automated test suite passes with zero requirement for live sibling services or paid credentials.
- **SC-004**: 100% of cross-repository integrations introduced in this phase depend on a pinned contracts package version; audit finds zero imports of another repository’s internal source tree (including contracts repo `src`).
- **SC-005**: 100% of runtime repositories expose the agreed baseline commands and CI gates (lint/typecheck, test, and documented run entrypoint).
- **SC-006**: Environment documentation coverage is complete: every required configuration key for each runtime repository is listed with an example, and a secrets scan of committed files finds no live credentials.
- **SC-007**: Contract compatibility rules are demonstrable: a deliberate breaking change bumps the contracts package MAJOR version and is detectable by consumers at install/dependency resolution before runtime undefined behavior.
- **SC-008**: Stakeholders can explain, in under 5 minutes, which repository owns UI, backend orchestration, retrieval, tools, and contracts—and how they connect—using only Phase 1 documentation and the canonical repository names.
- **SC-009**: A developer can complete the documented integrated local smoke path (UI → backend → RAG and MCP contract surfaces) in under 20 minutes after repositories are installed, with zero paid cloud dependencies.
- **SC-010**: Ownership docs and READMEs use the canonical names (`ai-assistant-ui`, `ai-assistant-backend`, `ai-assistant-rag`, `ai-assistant-mcp`, `ai-assistant-contracts`) with zero conflicting alternate repo names for those roles.

## Assumptions

- The existing `ai-assistant-ui` repository remains the UI codebase; Phase 1 adapts it to platform conventions rather than replacing it.
- The `ai-assistant-spec-hub` repository continues to hold specifications, constitution, and planning artifacts; it is not a runtime participant.
- Sibling repositories will live under the current `ai-assistant` workspace alongside the UI and spec-hub, using canonical names: `ai-assistant-backend`, `ai-assistant-rag`, `ai-assistant-mcp`, `ai-assistant-contracts`.
- `ai-assistant-contracts` is created in Phase 1 as the canonical home for all cross-repo boundary contracts (UI↔backend, backend↔RAG, backend↔MCP); “where justified” applies to promoting types into that home (boundary contracts yes; private implementation types no).
- Runtime repositories consume boundary contracts only through a semver-versioned contracts package; local/offline package distribution is allowed if versions remain explicit and pinned.
- Multi-repository layout is an intentional Phase 1 choice for clear ownership and replaceability, even though a modular monolith can also satisfy separation; repositories stay minimal and local-first to avoid unjustified distributed complexity.
- Phase 1 does not require production deployment, AWS provisioning, authentication productization (including inter-service auth), or high-quality RAG/tool behavior—only foundations, contracts, runnable skeletons, and one integrated local smoke path across stub/minimal surfaces.
- Local integrated mode trusts configured private/localhost URLs between services; no shared service tokens are required in Phase 1.
- Communication defaults: UI talks to the backend over a documented request/response conversation boundary; the backend consumes RAG via a documented retrieval boundary; the backend consumes MCP via a documented tool/resource capability boundary.
- Common TypeScript/testing/lint/format/CI conventions may be described once in platform docs and applied per repository (duplicated config is acceptable in Phase 1; a shared tooling package is optional, not required).
- Versioning for contracts follows semantic versioning on the contracts package (MAJOR for breaking, MINOR for additive, PATCH for fixes/docs-compatible changes).

## Out of Scope

- Full document ingestion quality, embedding provider selection, and retrieval evaluation beyond a minimal contract-proving surface
- Rich MCP tool packs beyond a minimal capability surface needed to prove the boundary
- Advanced agent planning, multi-step evaluation harnesses, and production observability backends
- Cloud deployment, paid providers as defaults, and infrastructure-as-code
- End-user authentication/authorization product features
- Inter-service authentication / authorization for local or production deployments
- Merging repositories into a monorepo or introducing cluster/orchestrator platforms

## Platform Constraints *(align with constitution)*

- **Local-first**: Feature MUST be demonstrable locally without AWS provisioning
- **Zero-cost default**: MUST NOT require paid infrastructure for local/MVP verification
- **Capability type**: Platform foundation (repository topology, contracts, standards)—enables UI, agent orchestration, RAG, and MCP work in later phases
- **Authoritative data**: Not applicable to this phase’s deliverables; future RAG vs API guidance remains unchanged
- **Security**: No secrets in browser or source control; contracts MUST not require embedding secrets in client-side repositories; Phase 1 local services are trusted-localhost only (no inter-service auth), and MUST NOT be treated as publicly exposable
- **Definition of Done**: Local TypeScript repositories, tests without paid cloud, error/compatibility handling for contracts, documented dependencies/env, portability/security considered
- **Complexity note**: Separate repositories are chosen for ownership clarity; avoid additional operational complexity (no Kubernetes, no mandatory cloud services, no unjustified shared runtime infrastructure)
