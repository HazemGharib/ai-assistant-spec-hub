# Feature Specification: RAG Repository

**Feature Branch**: `003-rag-repository`  
**Created**: 2026-09-21  
**Status**: Draft  
**Input**: User description: "Phase 3 — RAG Repository. Create a dedicated RAG service responsible exclusively for document ingestion, parsing, normalization, chunking, embeddings, indexing, and retrieval. Initially support practical local document formats such as Markdown and PDF, with stable metadata including document ID, source, page/section, version, and chunk ID. Expose a well-defined API that allows the backend/agent to submit a query and receive relevant chunks with metadata and citations. Keep embedding providers and vector stores behind interfaces so local implementations can later be replaced by AWS Bedrock/OpenSearch or other providers without changing consumers."

## Clarifications

### Session 2026-09-21

- Q: Should document ingest complete synchronously or via async jobs? → A: Synchronous — ingest request completes only when the new version is fully indexed and retrievable (or failed atomically)
- Q: Who owns document ID assignment on ingest? → A: Caller MUST supply document ID; server rejects missing/invalid IDs
- Q: What happens to superseded document versions after successful re-ingest? → A: Drop superseded version from the active index; retrieve only the latest successful version
- Q: How does document content reach the ingest API? → A: Content in request body (caller uploads Markdown/PDF bytes); source is metadata only
- Q: Who assigns the document version number on ingest? → A: Server assigns and increments version automatically; caller does not send version

### Session 2026-09-21 (local vector store)

- Q: What durable local vector index should Phase 3 use? → A: SQLite with vector search (sqlite-vec) behind the VectorStore interface; in-memory store for unit tests; OpenSearch-class stores remain future adapters only

### Session 2026-09-21 (retrieve ranking)

- Q: When the index is non-empty but a query is unrelated, what should retrieve return? → A: Always return top-`limit` by score when the index has chunks; empty results only when the index is empty (no minimum score floor in this phase)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Retrieve Relevant Chunks for the Agent (Priority: P1)

A backend/agent caller submits a natural-language query to the RAG service and receives a ranked list of relevant text chunks. Each chunk includes stable citation metadata (document identity, source, page or section, version, and chunk identity) so the agent can ground answers and expose citations to users.

**Why this priority**: Retrieval with citation-ready metadata is the core value of RAG for the conversational agent; without it, ingestion alone delivers no user-facing benefit.

**Independent Test**: With a small pre-indexed fixture corpus, call the retrieve contract; verify returned chunks match the query topic and each chunk carries complete, stable citation metadata.

**Acceptance Scenarios**:

1. **Given** at least one indexed document containing known phrases, **When** the backend submits a query that matches that content, **Then** the service returns one or more chunks whose text relates to the query and each chunk includes document ID, source, page or section (when applicable), version, and chunk ID.
2. **Given** an indexed corpus, **When** the backend submits a retrieve request with a result-limit preference, **Then** the service returns at most that many chunks, ordered from most to least relevant.
3. **Given** an empty index (no indexed documents), **When** retrieve is called with any valid query, **Then** the service returns an empty result set with a successful response (not an error).
4. **Given** a non-empty index and a query unrelated to indexed content, **When** retrieve is called, **Then** the service still returns up to the requested limit of highest-scoring chunks (scores may be low); it does not apply a minimum-score cutoff in this phase.
5. **Given** a malformed or incomplete retrieve request, **When** it is submitted, **Then** the service rejects it with a clear, contract-aligned error that does not expose internal provider details.

---

### User Story 2 - Ingest Markdown and PDF Documents (Priority: P1)

An operator (or automated pipeline acting for the platform) uploads Markdown or PDF document bytes to the RAG service, along with a document ID and source metadata. The service parses and normalizes the content, splits it into chunks, generates embeddings, and indexes those chunks so they become available for retrieval—including metadata needed for citations.

**Why this priority**: Without ingestion of real local document formats, retrieval can only serve fixtures and cannot support the product knowledge base.

**Independent Test**: Ingest a sample Markdown file and a sample PDF; then retrieve with queries drawn from each file’s content and confirm matching chunks and correct metadata.

**Acceptance Scenarios**:

1. **Given** valid Markdown bytes, a caller-supplied document ID, and source metadata, **When** they are submitted for ingestion, **Then** the ingest request completes only after the document is fully indexed (or fails atomically), and the response echoes that document ID with a version and chunks immediately available for retrieval.
2. **Given** valid PDF bytes, a caller-supplied document ID, and source metadata, **When** they are submitted for ingestion, **Then** the ingest request completes synchronously after text extraction and indexing (or fails atomically), preserves page (or equivalent section) metadata on chunks where extractable, and those chunks are immediately retrievable.
3. **Given** a document of an unsupported format, **When** ingestion is attempted, **Then** the service rejects it with a clear unsupported-format error and does not partially index corrupted data.
4. **Given** a corrupt or unreadable PDF, **When** ingestion is attempted, **Then** the service fails the ingest with a clear error and leaves the prior index state unchanged for that document identity (no silent partial success).
5. **Given** an ingest request missing a document ID or with an invalid ID, **When** it is submitted, **Then** the service rejects it without indexing.

---

### User Story 3 - Re-ingest and Version Documents Safely (Priority: P2)

An operator updates an existing knowledge document and re-submits it. The service records a new version, indexes the new content, and ensures retrieval cites the active version without leaving ambiguous or duplicate-conflicting citation identities for the same logical document.

**Why this priority**: Knowledge bases change; version-stable citations and safe re-indexing prevent stale or conflicting chunks from confusing the agent and end users.

**Independent Test**: Ingest document v1, retrieve and note chunk IDs/version; ingest updated content as v2 for the same document identity; retrieve again and confirm results cite v2 and no longer return superseded v1 as the active match set.

**Acceptance Scenarios**:

1. **Given** a document already indexed as version N, **When** updated content is ingested for the same document identity, **Then** the service assigns version N+1, retrieval returns chunks only for that new active version, and superseded version N chunks are no longer returned.
2. **Given** a completed re-ingest, **When** a caller inspects citation metadata on retrieved chunks, **Then** version and chunk IDs are stable identifiers suitable for display and audit (same chunk content under the same version yields the same chunk ID).
3. **Given** a re-ingest that fails mid-process, **When** the failure is reported, **Then** callers can still retrieve the previously successful active version (no empty or half-written active index for that document); the prior version is removed only after the new version is fully committed.
4. **Given** a successful re-ingest to version N+1, **When** a caller attempts to retrieve or specify version N, **Then** the service does not return superseded chunks (historical version query is out of scope).

---

### User Story 4 - Swap Embedding and Index Backends Without Changing Consumers (Priority: P2)

A platform engineer configures a different embedding provider or vector index implementation behind the RAG service’s internal provider boundaries. The backend/agent continues to call the same retrieve and ingest contracts; no consumer contract or call-site changes are required for the swap.

**Why this priority**: Constitution and Phase 1 require AWS/portability without rewriting consumers; this story proves the RAG boundary stays stable while infrastructure evolves (local → Bedrock/OpenSearch or peers).

**Independent Test**: Run the same ingest + retrieve acceptance suite against two configured provider implementations (e.g., default local and an alternate local/fake provider); assert identical contract shapes and successful outcomes without changing the caller.

**Acceptance Scenarios**:

1. **Given** the RAG service configured with provider implementation A, **When** ingest and retrieve are exercised via the published API, **Then** results conform to the same contracts as when configured with provider implementation B.
2. **Given** a consumer that only depends on the published RAG contracts, **When** the embedding or vector-store implementation is swapped, **Then** the consumer requires no request/response shape changes.
3. **Given** a provider is misconfigured or unavailable, **When** ingest or retrieve is attempted, **Then** the service returns a clear operational error at the RAG boundary without leaking provider-specific secrets or stack internals to the consumer.

---

### User Story 5 - Operate the RAG Service in Isolation Locally (Priority: P3)

A developer runs only the RAG repository locally, ingests sample documents, and exercises retrieve—without starting UI, MCP, or paid cloud services—using documented local configuration and zero-cost defaults.

**Why this priority**: Local-first, independently testable services are a platform non-negotiable; this story validates RAG as a first-class runnable subsystem.

**Independent Test**: Follow the RAG repository’s local setup alone; complete ingest of fixtures and at least one retrieve call; automated tests pass without paid credentials or live sibling services.

**Acceptance Scenarios**:

1. **Given** only the RAG repository available, **When** a developer follows its local documentation, **Then** they can start the service, ingest supported sample documents, and retrieve chunks successfully.
2. **Given** the RAG automated test suite, **When** it runs in CI or locally, **Then** it completes without requiring paid cloud credentials or running sibling platform services.
3. **Given** embedding or index providers that would incur cost in production, **When** local/MVP mode is used, **Then** documented free/local alternatives are the default and the service remains fully exercisable.

---

### Edge Cases

- Empty document body (valid format but no extractable text): ingest fails with `NO_CONTENT`; nothing is retrievable for that attempt; prior active version (if any) is unchanged.
- Extremely large documents: service enforces a documented size/page limit; oversize inputs are rejected clearly rather than hanging or exhausting local resources unbounded.
- Query with empty or whitespace-only text: rejected as invalid input.
- Non-empty index + unrelated query: still returns top-`limit` chunks by score (no minimum-score filter); empty `chunks` only when the index itself is empty.
- Concurrent ingest of the same document identity: service serializes or otherwise ensures one active version wins; no corrupt mixed-version index for that document.
- Special characters, non-ASCII text, and Markdown structure (headings, code blocks): normalized such that retrieval remains useful and section metadata remains meaningful where structure is available.
- PDF with scanned/image-only pages and no extractable text: treated as unreadable/no content with a clear failure or empty-content outcome (OCR is out of scope for this phase).
- Duplicate submission of identical content under a new version: allowed; version advances; chunk IDs remain deterministic for that version’s content.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The platform MUST provide a dedicated RAG service whose sole product responsibilities are document ingestion, parsing, normalization, chunking, embedding, indexing, and retrieval—not chat UX, agent orchestration, or tool/action execution.
- **FR-002**: The RAG service MUST accept document ingestion for Markdown and PDF formats in the initial release.
- **FR-003**: During ingestion, the service MUST parse and normalize document text into a consistent internal representation before chunking.
- **FR-004**: The service MUST split normalized content into chunks suitable for embedding and retrieval, preserving linkage from each chunk back to its source document.
- **FR-005**: The service MUST generate embeddings for chunks and store them in a searchable index so similarity-based retrieval is possible.
- **FR-006**: Each indexed chunk MUST carry stable metadata including at least: document ID, source (origin identifier or URI/path as supplied), page or section locator when available, document version, and chunk ID.
- **FR-007**: Chunk IDs MUST be stable for a given document version and chunk content/position policy such that identical re-processing of the same version yields the same chunk IDs.
- **FR-008**: The service MUST expose a well-defined retrieve API that accepts a query from the backend/agent and returns relevant chunks with text, relevance ordering, metadata, and citation fields sufficient for downstream display. When the index contains at least one chunk, retrieve MUST return up to the requested limit ordered by descending score even if scores are low; an empty chunk list MUST occur only when the index is empty (no minimum similarity floor in this phase).
- **FR-009**: The service MUST expose a well-defined ingest API (or equivalent documented operator entrypoint) that requires a caller-supplied document ID, accepts Markdown or PDF content as uploaded request bytes (not a server filesystem path), accepts source as citation metadata only, does not accept a caller-supplied version, and on success returns only after the new version is fully indexed and retrievable; the response MUST report success or failure, the same document ID, and the server-assigned version (no async job handoff in this phase).
- **FR-010**: Retrieve and ingest contracts used by other repositories MUST live in the shared contracts package and remain the only cross-repo integration surface for RAG (no importing RAG internals).
- **FR-011**: Embedding generation MUST be accessed through an internal provider boundary so the concrete embedding implementation can be replaced without changing ingest/retrieve consumer contracts.
- **FR-012**: Vector/index storage MUST be accessed through an internal provider boundary so the concrete store (local or later cloud such as OpenSearch-class services) can be replaced without changing ingest/retrieve consumer contracts.
- **FR-013**: Default local/MVP configuration MUST use free/local embedding and index implementations so the service is fully demonstrable without paid cloud provisioning.
- **FR-014**: The service MUST reject unsupported formats and invalid requests with clear, contract-aligned errors.
- **FR-015**: Failed ingest of a new version MUST NOT destroy or corrupt the previously active indexed version for that document identity.
- **FR-016**: The service MUST be independently runnable and testable locally without requiring UI, MCP, or paid external services.
- **FR-017**: Retrieval MUST treat returned chunk text as untrusted content from a citation perspective: metadata must be sufficient for the agent/UI to attribute sources; the RAG service itself does not assert answer correctness.
- **FR-018**: The service MUST document operational limits relevant to local use (for example maximum upload size and supported format notes) in its repository documentation.
- **FR-019**: When page or section information cannot be determined (e.g., unstructured Markdown without headings), the service MUST still return chunks with document ID, source, version, and chunk ID, and MAY omit or null the page/section field rather than inventing false locators.
- **FR-020**: Existing Phase 1 retrieve stub behavior MUST be replaced or extended so retrieve results come from the real indexed corpus after ingestion—not only hard-coded fixtures—while preserving contract compatibility for the backend client.
- **FR-021**: The service MUST reject ingest requests that omit a document ID or supply an invalid document ID, without modifying the index.
- **FR-022**: After a successful re-ingest for a document ID, the service MUST remove superseded version chunks from the active index so retrieve returns only the latest successful version; historical version retrieval is out of scope for this phase.
- **FR-023**: The service MUST assign document versions automatically (first successful ingest for a document ID is version 1; each subsequent successful re-ingest increments by 1). Callers MUST NOT supply a version; if a version field is present on ingest, the service MUST reject the request.

### Key Entities

- **Document**: A logical knowledge item identified by a caller-supplied document ID; has a source reference, format (Markdown or PDF), and a single active version in the index after each successful ingest.
- **Document Version**: An immutable snapshot of a document’s content at ingest time; version numbers are server-assigned (starting at 1, incrementing by 1 on each successful re-ingest). Only the latest successful version is retained in the active index; on successful re-ingest the prior version is dropped after the new version is committed.
- **Chunk**: A contiguous unit of normalized text derived from a document version; has chunk ID, optional page/section locator, embedding, and parent document/version references.
- **Citation Metadata**: The subset of chunk/document fields returned to callers for attribution: document ID, source, page/section (if present), version, chunk ID.
- **Retrieve Query**: A caller-submitted natural-language (or text) query with optional limits/filters; yields an ordered list of matching chunks.
- **Embedding Provider (boundary)**: Replaceable capability that turns chunk text into vectors; consumers of the RAG API never call it directly.
- **Vector Store (boundary)**: Replaceable capability that indexes and searches vectors with associated metadata; consumers of the RAG API never call it directly.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After ingesting a known Markdown sample and a known PDF sample, at least 90% of a fixed set of 10 content-derived probe queries return at least one chunk whose text overlaps the expected source passage (evaluated with a documented probe list).
- **SC-002**: 100% of successfully retrieved chunks in acceptance tests include document ID, source, version, and chunk ID; page or section is present whenever the source format provided an extractable locator.
- **SC-003**: A backend/agent caller can complete a retrieve round-trip against a warm local index in under 2 seconds for typical short queries over a small corpus (≤50 pages / ≤100 chunks) on a standard developer machine.
- **SC-004**: A developer following RAG-only local documentation can ingest two sample documents and run a successful retrieve within 15 minutes on a clean machine (dependencies install included, paid cloud not required).
- **SC-005**: Swapping the configured embedding provider or vector-store implementation (validated with two implementations in test) requires zero changes to published retrieve/ingest request and response shapes.
- **SC-006**: Automated RAG tests achieve a passing suite in CI without paid cloud credentials; failure injection for provider outages yields clear errors in 100% of covered failure cases.
- **SC-007**: Re-ingest of an updated document results in retrieval citing the new version for content-overlapping queries in 100% of the documented versioning acceptance cases, with no active mixed-version chunk sets for that document identity.

## Assumptions

- Primary consumers of the RAG API are the backend/agent (and automated tests/operators); the UI does not call RAG directly (aligned with Phase 1 ownership: UI → backend → RAG).
- Inter-service authentication remains out of scope for local/MVP (Phase 1 trust model); production auth is deferred.
- “Source” metadata is supplied by the ingest caller (e.g., original file path, URI, or logical name) and stored opaquely for citation display; it is not used by the service to read file contents.
- Document content for ingest is provided as uploaded bytes in the request body; server-side filesystem path ingest is out of scope for this phase.
- OCR for image-only PDFs is out of scope; only extractable text is indexed.
- Additional formats (HTML, DOCX, etc.) are out of scope for this phase but should not require consumer contract redesign when added later.
- Chunking strategy (size/overlap) may be chosen by implementers for quality; stability of chunk IDs within a version is required regardless of strategy details.
- Hybrid search, reranking, access-control filtering per user/tenant, and multi-tenant isolation are out of scope for this phase unless already implied by existing contracts (single local knowledge base).
- AWS Bedrock embeddings and OpenSearch (or equivalents) are portability targets, not required implementations in this phase; local durable index defaults to SQLite with vector search (sqlite-vec) under a local data directory, with an in-memory store for tests.
- The shared contracts package will gain or extend ingest-related definitions as needed; retrieve remains backward-compatible with the Phase 1 backend client where practical, with a documented version bump if breaking changes are unavoidable.
- Document identity MUST be caller-supplied on every ingest; the server does not assign document IDs. Version numbers are server-assigned (1, then N+1 on each successful re-ingest); callers do not supply version.
- Ingest is synchronous for this phase: the caller blocks until indexing succeeds or the operation fails atomically; asynchronous ingest jobs are out of scope.
- After successful re-ingest, superseded versions are dropped from the active index (no historical version retrieve in this phase).
- Retrieve ranking uses top-`limit` by similarity score with no minimum-score cutoff in this phase; empty results only when the index has no chunks.
## Platform Constraints *(align with constitution)*

- **Local-first**: Feature MUST be demonstrable locally without AWS provisioning
- **Zero-cost default**: MUST NOT require paid infrastructure for local/MVP verification
- **Capability type**: RAG knowledge
- **Authoritative data**: RAG supplies document context only; live/structured truths remain outside RAG (prefer API/DB when applicable)
- **Security**: Treat retrieved chunk text as untrusted for answer authority; cite sources via metadata; no secrets in browser; provider credentials stay server-side in configuration
- **Definition of Done**: Local TypeScript implementation in `ai-assistant-rag`, tests without paid cloud, error handling, documented deps, embedding/vector-store portability (sqlite-vec local default) and security considered
- **Ownership**: Ingestion, indexing, and retrieval owned solely by `ai-assistant-rag`; orchestration remains in `ai-assistant-backend`; cross-repo shapes owned by `ai-assistant-contracts`
