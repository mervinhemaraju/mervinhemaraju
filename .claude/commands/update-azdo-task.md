# Update Azure DevOps Task

## Arguments

Parse `$ARGUMENTS` (space-separated tokens):

- **`TASK_ID`** — first token, numeric (required)
- **`SOURCE`** — second token, `context` or `diff` (optional; if omitted, task content is not updated)
- **`--pr`** — optional flag; if present, create an Azure DevOps PR after updating the task
- **`--base <branch>`** — optional; base branch for the PR (default: `main`)

Stop with a usage message if `TASK_ID` is missing or `SOURCE` is present but not `context`/`diff`.

## Steps

### 1 — Resolve org + project

Check `AZDO_CLI_WORKITEMS_PAT` is set:

```bash
printenv AZDO_CLI_WORKITEMS_PAT | wc -c
```

If the byte count is 0 or 1 (empty or just a newline), stop and tell the user to export `AZDO_CLI_WORKITEMS_PAT` in `~/.zshenv` then restart Claude Code.

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

### 2 — Gather context (skip if SOURCE was not provided)

- If `SOURCE` is `diff`: run `git diff` and `git diff --staged`. Analyze what changed — files, purpose, key decisions.
- If `SOURCE` is `context`: use what was discussed and implemented in the current conversation session.

From whichever source, produce:
- A 2–4 sentence summary of what was done and why.
- List of files changed (if applicable).
- Current branch name (run `git branch --show-current`).

### 3 — Update the task discussion (skip if SOURCE was not provided)

```bash
AZURE_DEVOPS_EXT_PAT="$AZDO_CLI_WORKITEMS_PAT" az boards work-item update --id $TASK_ID \
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
AZURE_DEVOPS_EXT_PAT="$AZDO_CLI_WORKITEMS_PAT" az repos pr create \
  --title "<concise title derived from the task summary>" \
  --target-branch <base-branch> \
  --source-branch $(git branch --show-current) \
  --description "@/tmp/azdo_pr_body.md" \
  --organization "$AZDO_ORG" \
  --project "$AZDO_PROJECT" \
  --output json
```

Print the PR URL from the JSON output.

### 5 — Output

Print the task URL: `$AZDO_ORG/$AZDO_PROJECT/_workitems/edit/$TASK_ID`
