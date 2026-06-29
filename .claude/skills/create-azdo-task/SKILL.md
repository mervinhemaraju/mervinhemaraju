---
name: create-azdo-task
description: Create an Azure DevOps task, assign it, set its description, and create a matching git branch. Invoke with /create-azdo-task [task title].
allowed-tools: Bash(printenv:*), Bash(git remote get-url:*), Bash(az boards:*), Bash(git checkout -b:*)
---

# Create Azure DevOps Task

## Arguments

`$ARGUMENTS` is the task title. Stop with a usage message if it is empty.

## Prompt-free contract (important)

This skill is designed to run **without any permission prompts** after the single
approval gate in step 2. The permission gate fires on **any** command containing shell
variable expansion (`$VAR`) or command substitution (`$(...)`). To stay prompt-free:

- The PAT is **never** passed inline. It must already be exported as `AZURE_DEVOPS_EXT_PAT`
  (the var `az` reads natively). Never inline the PAT value — that leaks the secret.
- All other values (org URL, project, assignee, task id, branch name) are read first via
  the allowed commands, then **inlined as literals** into the `az`/`git` commands — never
  referenced as `$VAR`.
- Generated text inlined into a command (description, acceptance criteria) must not contain
  `$`, backticks, or `$(` — those are shell metacharacters and will trigger the gate.
  Rephrase to avoid them.

Prompt-free requires BOTH of these, together:

1. The command contains no `$` expansion / `$(...)` (above), AND
2. `settings.json` `permissions.allow` contains a matching rule —
   `Bash(az boards work-item*)` (and `Bash(git checkout -b*)` for the branch step). The
   `allowed-tools:` line in this skill's frontmatter does **not** suppress permission
   prompts; only `settings.json` does.

## Steps

### 1 — Verify env and resolve org + project

```bash
printenv AZDO_ASSIGNEE
printenv AZURE_DEVOPS_EXT_PAT
```

- If `AZDO_ASSIGNEE` is empty, stop and tell the user to export it in `~/.zshenv`.
- If `AZURE_DEVOPS_EXT_PAT` is empty, stop and tell the user to add
  `export AZURE_DEVOPS_EXT_PAT="<pat>"` to `~/.zshenv` and restart Claude Code. This is the
  var `az` reads natively, and it lets the skill authenticate without passing the PAT inline.

Capture the **literal** `AZDO_ASSIGNEE` value for inlining below.

Resolve the org URL and project from the git remote:

```bash
git remote get-url origin
```

Parse `https://dev.azure.com/{org}/{project}/_git/{repo}`:

- **org URL** = `https://dev.azure.com/{org}`
- **project** = `{project}`

If the URL doesn't match or no remote is set, ask the user for the missing values before
continuing. Capture these as literals — inline them into the commands below.

### 2 — Generate title, description, acceptance criteria, and branch name

**Title**: If `$ARGUMENTS` is more than 6 words, summarize it into a concise title of 6 words
or fewer. Otherwise use as-is. Always capitalize the first letter.

From the title, generate:

- **Description** (2–4 sentences): what the task is, why it matters, expected approach.
- **Acceptance Criteria** (3–6 bullets): specific, testable conditions, each starting with
  an action verb (Implement, Verify, Ensure, Add, Confirm).
- **Branch type**: infer from the title:
  - `feature` — Add, Implement, Create, Build, Introduce
  - `fix` — Fix, Resolve, Patch
  - `bugfix` — Bug, Bugfix
  - `update` — Update, Upgrade, Bump, Migrate
  - `improvement` — Improve, Enhance, Optimise, Refactor, Clean

  Slugify the **summarized title**: lowercase, spaces to hyphens, strip non-alphanumeric
  characters. The slug must be at most 5 words long — trim further if needed.
  Branch name preview: `<type>/<task-id-placeholder>-MHE-<slugified-title>`
  (the real task id replaces the placeholder once the task is created.)

Build the HTML body for the description field (description paragraph + AC as a `<ul>`):

```html
<p><!-- description paragraph --></p>
<p><strong>Acceptance Criteria</strong></p>
<ul>
  <li><!-- criterion 1 --></li>
  <li><!-- criterion 2 --></li>
</ul>
```

Show title, description, AC, and inferred branch name to the user and wait for approval.
**After approval, proceed with steps 3–6 automatically without asking the user any further
clarifying questions.**

### 3 — Create the task

Inline the literal title, project, org URL, and HTML body (no `$` expansion). The command
must begin with `az boards`:

```bash
az boards work-item create \
  --title "<title>" \
  --type "Task" \
  --project "<project>" \
  --organization "https://dev.azure.com/<org>" \
  --description "<html body from step 2>" \
  --output json
```

Capture the `id` field from the JSON output as `TASK_ID`.

### 4 — Assign to me

`--assigned-to` is silently ignored on create, so always assign with a follow-up update.
Inline the literal task id, assignee, and org URL:

```bash
az boards work-item update \
  --id <TASK_ID> \
  --assigned-to "<assignee>" \
  --organization "https://dev.azure.com/<org>" \
  --output none
```

### 5 — Create branch

> Intentional exception to `~/.claude/rules/no-git.md`: this skill is explicitly allowed to
> create a branch (the user opted in via `Bash(git checkout -b*)` in settings). Creating the
> branch is the only git write this skill performs — no add/commit/push/merge/rebase.

Inline the literal type, task id, and slug:

```bash
git checkout -b <type>/<TASK_ID>-MHE-<slugified-title>
```

### 6 — Output

Print the task URL: `https://dev.azure.com/<org>/<project>/_workitems/edit/<TASK_ID>`
Print the branch name.
