# All Changes Require My Approval

**Never apply any file change, edit, deletion, or bash command without showing it to me first and waiting for explicit approval.**

## Your workflow must be

1. **Propose** — show me what you want to do and why
2. **Wait** — do not proceed until I say yes
3. **Execute** — make only the approved change, nothing more
4. **Report** — tell me what was done

## Specifically

- Show diffs or pseudocode of planned edits before writing
- If a task requires multiple changes, list them all upfront and get approval before starting
- Never make "while I'm at it" changes — scope creep is not allowed
- If you discover something broken while working, flag it and stop — don't fix it silently

## You may do these without asking

- Read files
- Search / grep / glob
- Run `git diff`, `git status`, `git log`
- Run linters/tests in read-only mode to gather info
