# Terraform Provider Project

## Skills

@~/.claude/skills/tf-provider-core/SKILL.md
@~/.claude/skills/tf-provider-resources/SKILL.md
@~/.claude/skills/tf-provider-client/SKILL.md
@~/.claude/skills/tf-provider-testing/SKILL.md
@~/.claude/skills/tf-provider-versioning/SKILL.md
@~/.claude/skills/go-for-terraform/SKILL.md

---

## Stack

- Language: Go (latest stable)
- Framework: terraform-plugin-framework (never terraform-plugin-sdk/v2)
- Backend: REST API
- Testing: terraform-plugin-testing (acceptance tests hit real API)

## Quick Rules

### Provider Design

- One provider = one API
- One resource = one API object — never abstract multiple objects into one resource
- Schema must mirror the API — same field names, same structure
- Every resource must implement ImportState
- Sensitive API objects (tokens, secrets) = ephemeral resources, not regular resources

### Go

- `gofmt` and `go vet` before every commit — non-negotiable
- Error messages: lowercase, no trailing punctuation
- Always `fmt.Errorf("doing x: %w", err)` — never discard errors
- Always `defer resp.Body.Close()` immediately after `http.Do()`
- Always pass `context.Context` as first argument in I/O functions
- No panics — use `resp.Diagnostics.AddError()`
- No global state — pass everything via struct fields

### Schema

- Every attribute must have a `Description`
- `Sensitive: true` on all secret/token/password fields
- `UseStateForUnknown()` on all Computed ID and timestamp fields
- `RequiresReplace()` on immutable fields
- Boolean orientation: `true` = DO, `false` = DON'T
- Dates/times: RFC 3339 always

### API Client

- All HTTP logic in `internal/client/` — never inline in resources
- Typed errors (`NotFoundError`, `APIError`) — never string match errors
- `http.NewRequestWithContext()` — never `http.NewRequest()`

### Testing

- Every resource: Create+Read, Update, ImportState, CheckDestroy steps
- `CheckDestroy` is mandatory — never skip it
- Run: `TF_ACC=1 go test ./... -v -timeout 120m`

### Versioning

- Semver based on user state impact — not code changes
- Max one major version bump per year
- Deprecate before removing — never remove without a minor-version deprecation first
- All changes documented in `CHANGELOG.md`
