# Contracts Package Versioning

**Package**: `@ai-assistant/contracts`  
**Source repo**: `ai-assistant-contracts`  
**Initial version**: `0.1.0`

## Semver rules

| Change | Bump |
| -------- | ------ |
| Remove/rename field, change type, tighten validation, change error semantics incompatibly | **MAJOR** |
| Add optional field, add new tool/endpoint while keeping old ones | **MINOR** |
| Docs, comments, non-behavioral fixes | **PATCH** |

Phase 1 ships all three boundaries in one package version. A breaking change to *any* boundary bumps the shared package MAJOR.

## Consumer rules

1. Depend on an **explicit** version (e.g. `"0.1.0"` or `"^0.1.0"` with awareness that MAJOR must be deliberate).
2. Obtain the package via documented `file:` / packed tarball method—not by importing `ai-assistant-contracts/src`.
3. After a MAJOR bump, providers and consumers MUST upgrade together before integrated smoke is considered green.

## Compatibility detection

- **Install-time**: dependency resolver / `pnpm install` fails or warns on unsatisfiable ranges.
- **Smoke-time**: `/health` and chat `diagnostics.contractPackageVersion` SHOULD echo the running package version for audit.
- **CI**: contracts repo runs schema tests; consumers typecheck against installed package.

Silent partial compatibility is not allowed.
