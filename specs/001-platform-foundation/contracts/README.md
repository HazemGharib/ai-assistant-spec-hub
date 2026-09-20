# Boundary Contracts (Design Sources)

These files are the **design-time** contract sources for Phase 1. The implementable artifact is the `@ai-assistant/contracts` package produced by repository `ai-assistant-contracts`.

| Contract ID | Boundary | Spec file |
|-------------|----------|-----------|
| `ui-backend-chat` | UI → backend | [ui-backend-chat.openapi.yaml](./ui-backend-chat.openapi.yaml) |
| `backend-rag-retrieve` | backend → RAG | [backend-rag-retrieve.openapi.yaml](./backend-rag-retrieve.openapi.yaml) |
| `backend-mcp-capabilities` | backend → MCP | [backend-mcp-capabilities.md](./backend-mcp-capabilities.md) |

Versioning rules: [versioning.md](./versioning.md)

**Rule**: Runtime repositories depend on the versioned package only—never on this folder via path import, and never on another repo’s `src`.
