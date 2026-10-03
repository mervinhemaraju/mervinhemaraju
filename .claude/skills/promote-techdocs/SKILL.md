---
name: promote-techdocs
description: Promote docs from the local ~/Documents/techdocs buffer into the docs-internal repo, following its rules and skills, then offer to delete the buffered copies. Invoke with /promote-techdocs.
---

# Promote Techdocs

Moves finished docs from the local buffer (`~/Documents/techdocs`, written by
`/document-session`) into the official docs-internal repo:

`~/Projects/work/azuredev/duokeych/dke-devops/docs-internal`

The docs-internal repo's own rules and skills are the authority on structure and style.
This skill only orchestrates; it never overrides them.

## 1. List and choose

- Scan `~/Documents/techdocs` for topic folders and `.md` files. Ignore `.DS_Store`.
- For each doc, read its frontmatter (or first heading) and show: number, path, title,
  date, status.
- Ask the user which to promote:
  - 4 or fewer docs: use AskUserQuestion with multiSelect.
  - More than 4: print a numbered list and ask the user to reply with the numbers
    (AskUserQuestion allows at most 4 options).
- If the buffer is empty, say so and stop.

## 2. Load docs-internal conventions

Read these fresh on every run (they change over time), from
`~/Projects/work/azuredev/duokeych/dke-devops/docs-internal/.claude/`:

- `CLAUDE.md` and every file it imports under `rules/`
- `skills/new-doc-page/SKILL.md` (the scaffold procedure to follow)

Also look at the sibling pages in the target category to match tone, depth, and
`sidebar_position` sequence.

## 3. Check the docs-internal repo state

Run `git status` and `git branch --show-current` in docs-internal (read-only).

- If the branch looks unrelated to this doc, or there are uncommitted changes, tell the
  user and ask whether to proceed on the current branch.
- Never switch branches, commit, push, or stage.

## 4. Propose (approval required, per selected doc)

For each selected doc, show the user and wait for an explicit yes before writing:

- Target path under `docs/`, chosen per `rules/doc-placement.md` (existing category
  first, nest where the topic is an instance of one). If a new subfolder is justified,
  include the `_category_.json` contents and wait for approval of that too.
- Frontmatter: `sidebar_label`, `sidebar_position` (consistent with siblings), and the
  icon via the correct mechanism for the item type (see `rules/doc-visuals.md`).
- How the buffer doc becomes reference documentation:
  - Drop session narrative and buffer-only frontmatter (`status`, `azdo_tasks`, etc.).
  - Keep all technical content that is still true.
  - Convert links between docs to relative Markdown links.
  - Move any supporting files to `static/` per `rules/doc-structure.md`.
- Any claim that needs an official source per `rules/docs-writing.md`. Read the
  official docs and add the link, or ask the user. Never keep an unverified claim as
  fact.
- Content that does not belong in a permanent doc (one-off debugging notes, stale
  state). List it and ask whether to omit it.
- Whether an architecture diagram is warranted (follow `rules/architecture-diagrams.md`
  only if the user wants one).

## 5. Write

- Create the page (and `_category_.json` if approved) exactly as approved, following
  `skills/new-doc-page/SKILL.md`.
- Write only what the buffer doc and approved sources contain. No scope creep.
- Do not touch `legacy/`, `.azuredevops/main.yaml`, or unrelated pages.
- Never write secrets. Never use the em dash character.

## 6. Verify

Run in the docs-internal repo:

```bash
npm run typecheck
npm run build
```

Report the outcome. If either fails, fix only issues in the new page, or report and
stop. Do not proceed to cleanup for a doc whose build failed.

## 7. Offer cleanup of the buffer

For each doc that was promoted AND passed verification, ask separately:

> Remove `<exact buffer path>` from `~/Documents/techdocs`?

- Delete only on an explicit yes, and only that path (the doc, or its topic folder if
  it is now empty of other docs). Show the exact command first.
- Never delete docs that were skipped, failed verification, or were not selected.
- If the user says no, leave it and move on.

## 8. Report

- Per doc: buffer source, new docs-internal path, verification result, whether the
  buffer copy was removed or kept.
- Remind the user to review `git diff` in docs-internal and commit it themselves.
- Do NOT commit or stage anything.
