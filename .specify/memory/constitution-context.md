# Constitution: TypeScript RAG AI Agent Platform

## 1. Mission

Build a production-oriented AI agent platform in **TypeScript** that combines:

* A minimalist conversational UI
* An LLM-powered agent/orchestration layer
* RAG for retrieving relevant documents
* MCP for exposing agent capabilities/tools
* Local-first development and testing
* AWS portability
* A **$0/month target for development and MVP operation**, using paid services only when technically necessary

The system MUST be designed so that infrastructure choices can evolve without requiring a rewrite of the core application.

---

## 2. Technology Standards

### Mandatory

* **TypeScript** MUST be the primary programming language.
* Node.js MUST be used for backend/agent services.
* The frontend MUST use TypeScript.
* Prefer well-maintained open-source packages over implementing infrastructure from scratch.
* Dependencies MUST be justified when they introduce significant complexity, cost, or vendor lock-in.
* The application MUST be runnable locally without requiring AWS.
* Environment-specific configuration MUST be externalized through environment variables/configuration.
* Secrets MUST NEVER be committed to source control.

### UI

Use an existing AI/chat UI framework when appropriate rather than building chat infrastructure from scratch.

**assistant-ui** should be evaluated and preferred where it provides the required functionality:

<https://www.assistant-ui.com/>

The UI should remain independent from the agent implementation so that the backend can be replaced without redesigning the frontend.

---

## 3. Architecture Principles

The architecture MUST maintain clear separation between:

```text
UI
 ↓
Agent Application
 ↓
┌───────────────┬────────────────┐
│ RAG           │ MCP            │
│ Retrieval     │ Capabilities   │
└───────────────┴────────────────┘
 ↓
External systems / data
```

The system MUST distinguish between:

### RAG

RAG is responsible for **retrieving contextual knowledge**.

Examples:

* PDFs
* Markdown
* Documentation
* Knowledge bases
* Product information
* Internal documents

The agent MUST NOT use vector search when an authoritative structured query/API is more appropriate.

For example:

```text
"What does the refund policy say?"
→ RAG

"What is the current account balance?"
→ Database/API

"What is the current product price?"
→ Authoritative product API/database
```

### MCP

MCP is responsible for exposing **capabilities and contextual resources** to the agent.

Examples:

* HTTP/API calls
* Database queries
* File operations
* Calculations
* External services
* Application-specific actions

MCP tools MUST have explicit schemas, predictable inputs/outputs, validation, and clear error handling.

The application MUST NOT couple business logic directly to a specific MCP implementation where an abstraction is practical.

---

## 4. Local-First Development

The entire MVP MUST be executable locally.

A developer should be able to:

```bash
npm install
npm run dev
```

and run the application without provisioning AWS infrastructure.

Local development SHOULD use:

* Local document storage
* Local vector storage where practical
* Mock/fake MCP tools where appropriate
* Configurable LLM providers
* Deterministic test fixtures

Cloud services MUST have local alternatives wherever reasonably possible.

The architecture MUST avoid making AWS a prerequisite for development.

---

## 5. AWS Portability

AWS compatibility MUST be treated as a deployment target, not a hard dependency.

The application SHOULD be deployable to AWS using commonly available primitives such as:

* S3 for document/object storage
* Bedrock for LLM/embedding providers
* OpenSearch or another vector-capable datastore when required
* Lambda, ECS, or another suitable compute platform
* API Gateway or equivalent API layer

The core domain and agent logic MUST NOT contain unnecessary AWS-specific code.

Provider-specific implementations SHOULD be isolated behind interfaces/adapters.

Example:

```text
EmbeddingProvider
 ├── LocalEmbeddingProvider
 ├── OpenAIEmbeddingProvider
 └── BedrockEmbeddingProvider
```

The same principle applies to:

* LLM providers
* Vector stores
* Object storage
* Authentication
* External APIs

---

## 6. Zero-Cost Principle

The default implementation MUST target **$0 infrastructure cost** during development and early MVP usage.

Prefer:

1. Local execution
2. Open-source software
3. Free tiers
4. Existing infrastructure
5. Pay-per-use services only when necessary

Before introducing a paid AWS service or third-party service, the implementation MUST document:

* Why it is required
* Why a local/free alternative is insufficient
* Expected cost
* Whether the dependency can be removed later

No architecture decision should introduce recurring infrastructure costs merely for convenience.

The system MUST remain functional locally even when all paid/cloud integrations are disabled.

---

## 7. RAG Standards

RAG MUST be implemented as a replaceable subsystem.

The pipeline SHOULD follow:

```text
Document
 ↓
Parse
 ↓
Normalize
 ↓
Chunk
 ↓
Embed
 ↓
Store
 ↓
Retrieve
 ↓
Optional rerank
 ↓
LLM context
```

Document ingestion MUST be separated from query-time retrieval.

Each retrieved chunk SHOULD retain metadata such as:

```text
documentId
source
title
page/section
chunkId
createdAt/version
```

The agent SHOULD provide citations or source references whenever the retrieved information supports a user-facing factual answer.

RAG retrieval MUST be testable independently from the LLM.

---

## 8. Agent Standards

The agent MUST have a clear separation between:

```text
User input
 ↓
Agent reasoning/orchestration
 ↓
Retrieval/tool selection
 ↓
Execution
 ↓
Response
```

The agent MUST NOT blindly call every available tool.

Tools MUST be:

* Explicitly registered
* Schema validated
* Permission aware where relevant
* Observable
* Testable independently

The agent MUST gracefully handle:

* Missing information
* Retrieval failure
* Tool failure
* Invalid tool arguments
* Timeouts
* External API failures
* LLM failures

The system MUST prefer deterministic application logic over LLM reasoning when deterministic logic is sufficient.

---

## 9. Security

Security MUST be considered part of the architecture, not a later enhancement.

MUST:

* Never expose secrets to the browser.
* Validate all tool inputs.
* Validate external API responses where practical.
* Apply least-privilege principles.
* Prevent arbitrary code execution unless explicitly implemented as a controlled capability.
* Treat retrieved documents as untrusted input.
* Treat tool output as untrusted data.
* Protect against prompt injection originating from documents or external sources.
* Never allow retrieved content to override system/developer instructions.

Dangerous capabilities such as shell execution, filesystem modification, database writes, or external side effects MUST require explicit authorization boundaries.

---

## 10. Testing

Every major subsystem MUST be testable independently.

Minimum test boundaries:

```text
Document parsing
Chunking
Embedding
Retrieval
RAG context construction
MCP tools
Agent orchestration
API layer
UI
```

Tests MUST NOT require paid cloud services.

Use mocks, fixtures, local implementations, or recorded responses where appropriate.

The project SHOULD include evaluation cases such as:

```text
Question → expected documents
Question → expected tool
Question → expected final answer characteristics
```

RAG quality and tool-selection quality MUST be evaluated separately from general LLM quality.

---

## 11. Observability

The system MUST make it possible to understand:

```text
User question
 ↓
Retrieved documents
 ↓
Selected MCP tools
 ↓
Tool inputs/outputs
 ↓
LLM request/response metadata
 ↓
Final response
```

Sensitive information MUST NOT be logged unnecessarily.

Logging SHOULD support local debugging first and AWS-compatible observability later.

---

## 12. Maintainability

Prefer simple architecture over premature infrastructure.

Do NOT introduce:

* Kubernetes
* Microservices
* Complex event buses
* Managed vector databases
* Complex agent frameworks
* Multiple cloud services

unless the requirement demonstrates a real need.

The initial system SHOULD be a modular monolith where appropriate.

Prefer:

```text
packages/
  agent/
  rag/
  mcp/
  llm/
  storage/
  ui/
```

or an equivalent structure that maintains clear module boundaries.

Avoid unnecessary abstractions until there is a demonstrated reason for them.

---

## 13. Vendor Independence

No single LLM, embedding provider, vector database, or cloud provider should be deeply embedded into business logic.

Provider-specific integrations MUST be isolated behind interfaces when practical.

The architecture SHOULD allow:

```text
OpenAI ↔ Bedrock ↔ Local model
```

and:

```text
Local vector store ↔ PostgreSQL/pgvector ↔ OpenSearch
```

without rewriting the agent's core behavior.

---

## 14. Documentation

Every significant architectural decision MUST be documented.

The repository MUST contain concise documentation covering:

* Local setup
* Environment variables
* Architecture
* RAG pipeline
* MCP tools
* Testing
* AWS deployment
* Cost implications
* Security considerations

Architecture diagrams SHOULD be maintained alongside the project documentation.

---

## 15. Implementation Philosophy

The implementation MUST follow this priority:

```text
Correctness
   ↓
Simplicity
   ↓
Testability
   ↓
Security
   ↓
Portability
   ↓
Performance optimization
```

Do not optimize prematurely.

Do not introduce infrastructure merely because it is available.

Do not use RAG where a database/API query is more authoritative.

Do not use an LLM where deterministic code is sufficient.

Do not use MCP merely for the sake of using MCP.

Use each technology because it solves a specific problem.

---

## 16. Definition of Done

A feature is considered complete only when:

* It works locally.
* It is implemented in TypeScript.
* It has appropriate automated tests.
* It does not require paid infrastructure for local testing.
* Dependencies are documented.
* Errors are handled.
* Security implications have been considered.
* AWS portability has not been unnecessarily compromised.
* The implementation does not introduce unnecessary infrastructure complexity.

The MVP should ultimately demonstrate all three core capabilities:

```text
1. RAG
   "What does this document say?"

2. MCP
   "Perform this external operation."

3. Agent orchestration
   "Determine whether to retrieve knowledge,
    invoke a tool, or combine both."
```

The architecture should make these capabilities independently understandable, testable, and replaceable.
