# Universal Code Style

## Principles

- Prefer composition over inheritance
- Dependency injection for testability
- Fail fast — validate early, surface errors clearly
- Write self-documenting code; comments explain *why*, not *what*
- DRY, but don't abstract prematurely

## Quality Rules

- Full type annotations everywhere (no untyped variables or return values)
- Specific exception/error types — never catch-all handlers that swallow errors
- Never log or expose secrets, tokens, or PII
- All secrets via environment variables — never hardcoded
- Validate and sanitize all external input

## Diffs & Changes

- Keep diffs minimal — only change what is needed
- Do not reformat unrelated code in the same edit
- Do not add unused imports or dead code
- One concern per commit (I'll do the committing)
