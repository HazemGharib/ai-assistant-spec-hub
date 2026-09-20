# Engineering Standards (Phase 1)

Shared quality gates for all runtime + contracts repositories.

## Script names (required)

| Script | Purpose |
| -------- | --------- |
| `dev` | Local server / Vite (runtime) |
| `build` | Compile / bundle |
| `test` | Vitest unit/contract tests |
| `lint` | oxlint |
| `typecheck` | `tsc` noEmit (or project references) |
| `format` | Prettier write |
| `format:check` | Prettier check |

Contracts may omit `dev` but must expose `build`, `test`, `lint`, `typecheck`, `format`, `format:check`.

## Tooling

- **Package manager**: pnpm (`packageManager` field)
- **Node**: 22 LTS (`engines.node >=22`)
- **Language**: TypeScript strict
- **Lint**: oxlint
- **Format**: Prettier
- **Tests**: Vitest (no paid cloud; fakes/fixtures)
- **HTTP stubs**: Hono (backend, rag, mcp HTTP)
- **Schemas**: Zod via `@hazemgharib/ai-agent-contracts`

## CI checklist (GitHub Actions)

Every contracts/runtime repo `.github/workflows/ci.yml` should:

1. Checkout
2. Setup Node 22 + pnpm
3. `pnpm install`
4. For consumers: install `@hazemgharib/ai-agent-contracts@0.2.0` from GitHub Packages (`NODE_AUTH_TOKEN`); locally you may `pnpm link` a built contracts package when iterating before publish
5. `pnpm lint`
6. `pnpm typecheck`
7. `pnpm test`
8. `pnpm build` (where applicable)

## Contracts dependency rule

- Depend on `"@hazemgharib/ai-agent-contracts": "0.2.0"` (GitHub Packages). CI must not sibling-checkout contracts source.
- **Never** `"file:../ai-assistant-contracts/src"` or relative imports into sibling `src`.
- Audit helper: [`../specs/001-platform-foundation/scripts/assert-no-src-path-deps.sh`](../specs/001-platform-foundation/scripts/assert-no-src-path-deps.sh)

## Cost / security

- Default **$0** — no AWS, no paid APIs required for stubs.
- No secrets in git; use `.env.example` placeholders only.
- No inter-service auth in Phase 1; localhost trust only — do not expose publicly.
