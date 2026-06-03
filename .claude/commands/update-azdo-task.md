# Update Azure DevOps Task

## Arguments

Parse `$ARGUMENTS` (space-separated tokens):

- **`TASK_ID`** — first token, numeric (required)
- **`SOURCE`** — second token, must be `context` or `diff` (required)
- **`--pr`** — optional flag; if present, create a GitHub PR after updating the task
- **`--base <branch>`** — optional; base branch for the PR (default: `main`)

Stop with a usage message if `TASK_ID` or `SOURCE` are missing or `SOURCE` is not `context`/`diff`.

## Steps

### 1 — Resolve org + project

Verify Azure CLI credentials are valid:

```bash
az account show --output none
```

If this fails, stop and tell the user to run `azauth-dke` first, then retry.

Derive `AZDO_ORG` and `AZDO_PROJECT` from the git remote:

```bash
git remote get-url origin
```

Parse the URL: `https://dev.azure.com/{org}/{project}/_git/{repo}`
- `AZDO_ORG` = `https://dev.azure.com/{org}`
- `AZDO_PROJECT` = `{project}`

If the URL doesn't match this pattern or no remote is set, ask the user to provide the missing values before continuing.

### 2 — Gather context

- If `SOURCE` is `diff`: run `git diff` and `git diff --staged`. Analyze what changed — files, purpose, key decisions.
- If `SOURCE` is `context`: use what was discussed and implemented in the current conversation session.

From whichever source, produce:
- A 2–4 sentence summary of what was done and why.
- List of files changed (if applicable).
- Current branch name (run `git branch --show-current`).

### 3 — Update the task discussion

```bash
az boards work-item update --id $TASK_ID \
  --discussion "<summary of what was done>. Files: <list>. Branch: <branch>." \
  --organization "$AZDO_ORG" \
  --output none
```

### 4 — Create PR (only if --pr was passed)

Determine the base branch: use the value from `--base` if provided, otherwise `main`.

#### 4a — Find the PR template

```bash
find .azuredevops -name "*.md" | head -1
```

- If a file is found, read it. Fill in each section using the context from Step 2 (diff or session). Preserve the template structure exactly — do not add or remove sections.
- If no file is found, generate a standard PR template body from the Step 2 summary with sections: **Summary**, **Changes**, **Test plan**, and **Notes**.

Write the result to `/tmp/azdo_pr_body.md`.

#### 4b — Create the PR

```bash
gh pr create \
  --title "<concise title derived from the task summary>" \
  --base <base-branch> \
  --body-file /tmp/azdo_pr_body.md
```

Print the PR URL.

### 5 — Output

Print the task URL: `$AZDO_ORG/$AZDO_PROJECT/_workitems/edit/$TASK_ID`
