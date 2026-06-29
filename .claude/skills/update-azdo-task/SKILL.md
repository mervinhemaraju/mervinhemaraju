---
name: update-azdo-task
description: Update an Azure DevOps task with progress, optionally set its state and create/link a PR. Invoke with /update-azdo-task [task-id] [context|diff] [--status <state>] [--pr] [--base <branch>].
allowed-tools: Bash(printenv:*), Bash(git remote get-url:*), Bash(git diff:*), Bash(git branch --show-current:*), Bash(find .azuredevops:*), Bash(az boards:*), Bash(az repos:*), Write(/tmp/azdo_*)
---

# Update Azure DevOps Task

## Arguments

Parse `$ARGUMENTS` (space-separated tokens):

- **`TASK_ID`** — first token, numeric (optional — see resolution rules below)
- **`SOURCE`** — next token, `context` or `diff` (optional; if omitted, task content is not updated)
- **`--status <state>`** — optional; sets the work item's State field (e.g. `To Do`, `Doing`, `Done`, or `New`/`Active`/`Closed` depending on the project's process). Passed through verbatim to `--state`.
- **`--pr`** — optional flag; if present, create an Azure DevOps PR after updating the task
- **`--base <branch>`** — optional; base branch for the PR (default: `main`)

**Resolving `TASK_ID`:**

1. If the first token is numeric, use it as `TASK_ID`.
2. Otherwise, scan the current conversation context for a task ID that was created or mentioned (e.g. from a prior `/create-azdo-task` run). Use that ID and tell the user which one you picked.
3. If no ID is found in context, ask the user: "Which task ID should I update?"

Stop with a usage message if `SOURCE` is present but not `context`/`diff`.

## Prompt-free contract (important)

This skill is designed to run **without any permission prompts** after the approval gate in
step 1b. The permission gate fires on **any** command containing shell variable expansion
(`$VAR`) or command substitution (`$(...)`). To stay prompt-free:

- The PAT is **never** passed inline. It must already be exported as `AZURE_DEVOPS_EXT_PAT`
  (the var `az` reads natively). Never inline the PAT value — that leaks the secret.
- All other values (org URL, project, task id, branch name, PR id) are read first via the
  allowed commands, then **inlined as literals** — never referenced as `$VAR`, and never
  via `$(...)`.
- Generated text inlined into a command (discussion/status text) must not contain `$`,
  backticks, or `$(`. Rephrase to avoid them. For the PR body, write it to a
  `/tmp/azdo_*` file and pass `--description "@<file>"` (no shell metacharacters in the
  command itself).

Prompt-free also requires that `settings.json` `permissions.allow` contains a matching rule
for each command (the `allowed-tools:` frontmatter does NOT suppress prompts; only
`settings.json` does). This skill's commands rely on: `Bash(printenv*)`,
`Bash(git remote get-url*)`, `Bash(git diff*)`, `Bash(git branch --show-current*)`,
`Bash(find .azuredevops*)`, `Bash(az boards work-item*)`, `Bash(az repos pr*)`, and
`Write(/tmp/azdo_*)`.

## Steps

### 1 — Resolve org + project

```bash
printenv AZURE_DEVOPS_EXT_PAT
```

If `AZURE_DEVOPS_EXT_PAT` is empty, stop and tell the user to add
`export AZURE_DEVOPS_EXT_PAT="<pat>"` to `~/.zshenv` and restart Claude Code. This is the
var `az` reads natively, and it lets the skill authenticate without passing the PAT inline.

Resolve the org URL and project from the git remote:

```bash
git remote get-url origin
```

Parse `https://dev.azure.com/{org}/{project}/_git/{repo}`:

- **org URL** = `https://dev.azure.com/{org}`
- **project** = `{project}`

If the URL doesn't match or no remote is set, ask the user for the missing values before
continuing. Capture these as literals — inline them into the commands below.

### 1b — Show plan and wait for approval

Tell the user:

- Task ID that will be updated
- Whether discussion will be added (SOURCE provided or not)
- Whether the task will be reported as completed in the status comment (ask the user if unclear)
- The new State, if `--status` was passed (and what it will change from, if known)
- Whether a PR will be created (`--pr` flag)
- Base branch for PR (if applicable)

**Wait for the user to confirm. After confirmation, proceed with all remaining steps
automatically without asking the user any further clarifying questions.**

### 2 — Gather context (skip if SOURCE was not provided)

- If `SOURCE` is `diff`: run `git diff` and `git diff --staged`. Analyze what changed — files, purpose, key decisions.
- If `SOURCE` is `context`: use what was discussed and implemented in the current conversation session.

Also capture the current branch name as a literal (you'll inline it for the PR):

```bash
git branch --show-current
```

From whichever source, produce:

- A 2–4 sentence summary of what was done and why.
- List of files changed (if applicable).

### 3 — Update the task discussion (skip if SOURCE was not provided)

Inline the literal task id, org URL, and summary text (no `$`, backticks, or `$(`):

```bash
az boards work-item update \
  --id <TASK_ID> \
  --discussion "<summary>. Files: <list>. Branch: <branch>." \
  --organization "https://dev.azure.com/<org>" \
  --output none
```

### 3b — Post a completion status comment

Always run this step (even if SOURCE was not provided), so the task carries an explicit,
human-readable record of its state directly in the comments.

Determine completion status:

- If the user stated the task is done/complete, treat it as **completed**.
- If the work is partial or follow-up remains, treat it as **not completed**.
- If unclear, ask the user before posting.

```bash
az boards work-item update \
  --id <TASK_ID> \
  --discussion "Task summary: <2-4 sentence description>. Status: <Completed | Not completed - remaining: <what's left>>." \
  --organization "https://dev.azure.com/<org>" \
  --output none
```

This step posts a comment only; it does not change the work item's State field.

### 3c — Set the work item state (only if --status was passed)

Inline the literal task id, state value, and org URL (no `$` expansion). The value passes
through verbatim to `--state` — AzDO validates it against the project's process and errors on
an invalid state, in which case surface the error to the user:

```bash
az boards work-item update \
  --id <TASK_ID> \
  --state "<status>" \
  --organization "https://dev.azure.com/<org>" \
  --output none
```

### 4 — Create PR (only if --pr was passed)

Determine the base branch: use the value from `--base` if provided, otherwise `main`.

#### 4a — Find the PR template

```bash
find .azuredevops -name "*.md"
```

- If one or more files are found, read the first. Fill in each section using the context
  from step 2 (diff or session). Preserve the template structure exactly — do not add or
  remove sections.
- If no file is found, generate a standard PR body from the step 2 summary with sections:
  **Summary**, **Changes**, **Test plan**, and **Notes**.

Write the result to `/tmp/azdo_pr_body.md` (via the Write tool — keeps shell metacharacters
in the body out of the command line).

#### 4b — Create the PR

Inline the literal title, base branch, source branch (from step 2), org URL, and project:

```bash
az repos pr create \
  --title "<concise title derived from the task summary>" \
  --target-branch <base-branch> \
  --source-branch <current-branch> \
  --description "@/tmp/azdo_pr_body.md" \
  --organization "https://dev.azure.com/<org>" \
  --project "<project>" \
  --output json
```

Capture the `pullRequestId` field from the JSON output as `PR_ID`.

#### 4c — Link the PR to the work item

Inline the literal PR id, task id, and org URL:

```bash
az repos pr work-item add \
  --id <PR_ID> \
  --work-items <TASK_ID> \
  --organization "https://dev.azure.com/<org>"
```

Print the PR URL from the JSON output in step 4b.

### 5 — Output

Print the task URL: `https://dev.azure.com/<org>/<project>/_workitems/edit/<TASK_ID>`
If `--status` was passed, print the new State that was set.
