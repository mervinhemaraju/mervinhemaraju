---
name: review
description: Review code changes against my personal standards. Use after implementing a feature or fix. Auto-invoke when user says "review my changes", "check this", or "LGTM?".
---

# Code Review

Review the current changes (use `git diff` and `git status` to find them).

Check each of these in order:

## Architecture

- Does it follow the project's existing patterns and layer boundaries?
- Does it introduce unnecessary coupling?

## Code Quality

- Type annotations present and correct?
- Error handling specific (no catch-all swallowing)?
- Any dead code, unused imports, or debug statements?
- Secrets or sensitive data exposed anywhere?

## Tests

- Are new tests present for new behaviour?
- Do existing tests still make sense?

## Diff Hygiene

- Are unrelated files changed?
- Is the scope of change appropriate?

Produce a concise report:

- ✅ What looks good
- ⚠️ Concerns (with file + line reference)
- 🚫 Blockers (must fix before shipping)

Do NOT commit or stage anything. Report only.
