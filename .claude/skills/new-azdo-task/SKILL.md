---
name: new-azdo-task
description: Create a new Azure DevOps task assigned to me, with an auto-generated description and acceptance criteria and an optional priority (default 3). Invoke with /new-azdo-task [title] [project] [priority].
allowed-tools: Bash(printenv:*), Bash(az boards:*)
---

# New Azure DevOps Task

## Arguments

Parse `$ARGUMENTS` into:

- **`TITLE`** (required) — the task title.
- **`PROJECT`** (required) — the Azure DevOps project name.
- **`PRIORITY`** (optional) — an integer 1–4 (1 = highest). Defaults to `3` if omitted.

Accept either flag form (`title="..." project="..." priority=2`) or natural language
(e.g. "Fix the login redirect in the Platform project, priority 1"). If `TITLE` or
`PROJECT` cannot be confidently determined, ask the user once before continuing.
Reject a `PRIORITY` that is not 1–4 with a usage message.

## Prompt-free contract (important)

This skill is designed to run **without any permission prompts** after the single
approval gate in step 3. The permission gate fires on **any** command containing shell
variable expansion (`$VAR`) — it cannot see what a variable resolves to, so it asks.
To stay prompt-free, **every `az` command below must contain no `$` expansion**:

- The PAT is **never** passed inline. It must already be exported in the shell profile
  as `AZURE_DEVOPS_EXT_PAT` (see step 1). Never inline the PAT value into a command —
  that would leak the secret into shell history and the tool log.
- All other values (org URL, assignee, project, priority, title, description) are read
  first via `printenv` and then **inlined as literals** into the `az` commands.

Prompt-free requires BOTH of these, together:

1. The command contains no `$` expansion (above), AND
2. `settings.json` `permissions.allow` contains a matching rule —
   `Bash(az boards work-item*)`. The `allowed-tools:` line in this skill's frontmatter does
   **not** suppress permission prompts; only `settings.json` does.

## Steps

### 1 — Verify env and capture literal values

```bash
printenv AZDO_ASSIGNEE
printenv AZDO_ORG
printenv AZURE_DEVOPS_EXT_PAT | wc -c
```

- If `AZDO_ASSIGNEE` is empty, stop and tell the user to export it in `~/.zshenv`.
- If `AZDO_ORG` is empty, stop and tell the user to export it in `~/.zshenv`.
- If the `AZURE_DEVOPS_EXT_PAT` byte count is 0 or 1, stop and tell the user to add
  `export AZURE_DEVOPS_EXT_PAT="<pat>"` to `~/.zshenv` and restart Claude Code. This is
  the env var `az` reads natively, and it lets the skill authenticate without ever passing
  the PAT inline (which would leak the secret and trigger a permission prompt).

Capture the **literal** values printed for `AZDO_ASSIGNEE` and `AZDO_ORG` — you will inline
them into the `az` commands below (do not reference them as `$VAR` in those commands).

**Build the org URL** from the captured `AZDO_ORG` value:

- If it already starts with `http`, use it as-is.
- Otherwise it is a slug — the org URL is `https://dev.azure.com/<slug>`.

### 2 — Generate title, description, and acceptance criteria

**Title**: If `TITLE` is more than 6 words, summarize it into a concise title of 6 words
or fewer. Otherwise use as-is. Always capitalize the first letter.

From the title, generate:

- **Description** (2–4 sentences): what the task is, why it matters, expected approach.
- **Acceptance Criteria** (3–6 bullets): specific, testable conditions, each starting with
  an action verb (Implement, Verify, Ensure, Add, Confirm).

Build the HTML body that will be written to the task's description field:

```html
<p><!-- description paragraph --></p>
<p><strong>Acceptance Criteria</strong></p>
<ul>
  <li><!-- criterion 1 --></li>
  <li><!-- criterion 2 --></li>
</ul>
```

### 3 — Validate with the user (single approval gate)

Show the user:

- Title
- Project
- Assignee (the literal value captured in step 1)
- Priority (the value, defaulting to `3`)
- Description
- Acceptance Criteria

Wait for approval. **After approval, proceed with all remaining steps automatically
without asking the user any further clarifying questions.**

### 4 — Create the task

Inline the literal org URL (from step 1), project, HTML body, and priority. The command
must begin with `az boards` and contain no `$` expansion:

```bash
az boards work-item create \
  --title "<title>" \
  --type "Task" \
  --project "<project>" \
  --organization "https://dev.azure.com/<org-slug>" \
  --description "<html body from step 2>" \
  --fields "Microsoft.VSTS.Common.Priority=<priority>" \
  --output json
```

Capture the `id` field from the JSON output as `TASK_ID`.

### 5 — Assign to me

`--assigned-to` is silently ignored on create, so always assign with a follow-up update.
Inline the literal assignee and org URL (no `$` expansion):

```bash
az boards work-item update \
  --id <TASK_ID> \
  --assigned-to "<assignee>" \
  --organization "https://dev.azure.com/<org-slug>" \
  --output none
```

### 6 — Output

Print the task URL: `https://dev.azure.com/<org-slug>/<project>/_workitems/edit/<TASK_ID>`
Print the title, project, assignee, and priority that were set.
