---
name: document-session
description: Document everything done in the current session as a detailed markdown tech doc in the local ~/Documents/techdocs buffer. Use when the user says "document this session", "write up what we did", or invokes /document-session [topic].
---

# Document Session

Writes a complete, accurate record of this session into the local buffer at
`~/Documents/techdocs`. The buffer is a staging area: docs here are later promoted to
the docs-internal repo with `/promote-techdocs`.

## Arguments

`$ARGUMENTS` is an optional topic name (e.g. `databasus`). If empty, infer a short topic
from the session and confirm it in step 3.

## Principles

- Complete: do not drop anything a future reader would need (values, versions, resource
  names, commands, decisions, failed attempts).
- Straightforward: plain language, no filler, no restating the obvious.
- Truthful: only record what actually happened in this session. Never invent, assume, or
  extrapolate. If something is unclear or missing, list it under "Open items" instead of
  guessing.
- Safe: never write secrets, tokens, passwords, PATs, or PII. Refer to them by name or
  location (e.g. "stored in GCP Secret Manager as `x`"), never by value.
- No em dash character anywhere (see `~/.claude/rules/writing-style.md`).

## 1. Gather

Collect every source of truth before writing:

- The full conversation: requests, decisions, commands run, outputs, errors, fixes.
- `git status` and `git diff` for every repo touched this session (read-only; the paths
  are listed in `~/.claude/rules/project-locations.md` for DuoKey repos).
- If the conversation was compacted and early details are missing, read the session
  transcript under `~/.claude/projects/` (newest `.jsonl` for the current project) to
  recover them.
- Any AzDO task IDs, PR links, or ticket references mentioned.

Do not rely on memory for exact values. Re-read the files or diffs when in doubt.

## 2. Locate

- Target folder: `~/Documents/techdocs/<topic>/` (flat topic folders, kebab-case).
- List the existing folders first. If one already covers this topic, do not create a
  duplicate: add to it.
- Filename:
  - New topic: `README.md`.
  - Topic folder already has a `README.md`: `YYYY-MM-DD-<short-slug>.md` for this
    session's doc (use today's date), unless the user asks to merge into the README.

## 3. Propose (approval required)

Show the user, then wait for an explicit yes before writing anything:

- The full target path.
- Whether it is a new doc or an addition to an existing one.
- The section outline with a one-line note per section on what it will contain.
- Any gaps found in step 1 that you could not fill.

## 4. Write

Use this structure. Omit a section only if it genuinely has no content (say "None" for
Problems and Open items rather than dropping them).

```markdown
---
title: <Human readable title>
date: <YYYY-MM-DD>
topic: <topic-slug>
status: draft
repos: [<repo names touched>]
azdo_tasks: [<task ids, or empty>]
---

# <Title>

## Summary
Two to four sentences: what the goal was and what the outcome is.

## Context and goal
Why this work was needed, the starting state, constraints.

## What was done
Grouped by component or step, in logical order. For each: what changed and why.

## Technical details
Exact, reference-grade facts: resource names, namespaces, versions, IPs/CIDRs, config
keys and values (non-secret), commands (as fenced code blocks), API or CLI usage,
architecture notes. Tables for anything that is a mapping or list of items.

## Files changed
Per repo: path and a one-line description of each change.

## Decisions and rationale
Each non-obvious decision, the alternatives considered, and why this one was chosen.

## Problems and fixes
Each issue hit: symptom, root cause, fix. Include dead ends worth not repeating.

## Verification
How the result was checked (commands, outputs, tests) and what was NOT verified.

## Open items
Follow-ups, known gaps, things to confirm, anything deferred.
```

Rules for content:

- Fenced code blocks with a language tag for commands and config.
- Sanitize commands and output: strip tokens, keys, passwords, and personal data.
- Use relative or repo-qualified paths, not absolute paths under the home directory.
- Research-derived claims (provider behaviour, pricing, specs) must carry the official
  source link, or be marked "unverified". This keeps promotion to docs-internal clean.
- Do not add diagrams unless the session produced one; note in Open items if one would
  help.

## 5. Report

- State the file path written and the list of sections.
- Mention any gaps or unverified claims flagged inside the doc.
- Do NOT commit or stage anything.
- Remind the user they can run `/promote-techdocs` later to move it to docs-internal.
