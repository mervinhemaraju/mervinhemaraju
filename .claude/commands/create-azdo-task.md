# Create Azure DevOps Task

## Arguments

`$ARGUMENTS` is the task title. Stop with a usage message if it is empty.

## Steps

### 1 — Verify env vars and resolve org + project

Check `AZDO_ASSIGNEE` and `AZDO_CLI_WORKITEMS_PAT` are set:

```bash
printenv AZDO_ASSIGNEE
printenv AZDO_CLI_WORKITEMS_PAT | wc -c
```

If `AZDO_ASSIGNEE` is empty, stop and tell the user to export it in `~/.zshenv`.
If the PAT byte count is 0 or 1 (empty or just a newline), stop and tell the user to export `AZDO_CLI_WORKITEMS_PAT` in `~/.zshenv` then restart Claude Code.

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

### 2 — Generate title, description, acceptance criteria, and branch name

**Title**: If `$ARGUMENTS` is more than 6 words, summarize it into a concise title of 6 words or fewer. If 6 words or fewer, use as-is. Always capitalize the first letter.

From the title, generate:

- **Description** (2–4 sentences): what the task is, why it matters, expected approach.
- **Acceptance Criteria** (3–6 bullets): specific, testable conditions, each starting with an action verb (Implement, Verify, Ensure, Add, Confirm).
- **Branch type**: infer from the title using these rules:
  - `feature` — Add, Implement, Create, Build, Introduce
  - `fix` — Fix, Resolve, Patch
  - `bugfix` — Bug, Bugfix
  - `update` — Update, Upgrade, Bump, Migrate
  - `improvement` — Improve, Enhance, Optimise, Refactor, Clean

  Slugify the **summarized title** (not the raw input): lowercase, spaces to hyphens, strip non-alphanumeric characters. The slug must be at most 5 words long — trim further if needed.
  Branch name preview: `<type>/<task-id-placeholder>-MHE-<slugified-title>`
  (The real task ID replaces the placeholder once the task is created.)

Show title, description, AC, and inferred branch name to the user and wait for approval.
**After approval, proceed with steps 3–6 automatically without asking for further confirmation.**

### 3 — Create the task

```bash
AZURE_DEVOPS_EXT_PAT="$AZDO_CLI_WORKITEMS_PAT" az boards work-item create \
  --title "$ARGUMENTS" \
  --type "Task" \
  --project "$AZDO_PROJECT" \
  --organization "$AZDO_ORG" \
  --output json
```

Capture the `id` field from the JSON output as `TASK_ID`.

### 4 — Assign to me

```bash
AZURE_DEVOPS_EXT_PAT="$AZDO_CLI_WORKITEMS_PAT" az boards work-item update --id $TASK_ID \
  --assigned-to "$AZDO_ASSIGNEE" \
  --organization "$AZDO_ORG" \
  --output none
```

Note: `--assigned-to` on the create call is silently ignored — always use a follow-up update.

### 5 — Set description via REST API

Write the HTML description (description paragraph + AC as `<ul>`) to `/tmp/azdo_body.html`, then:

```bash
python3 -c "
import json
html = open('/tmp/azdo_body.html').read()
print(json.dumps([{'op':'add','path':'/fields/System.Description','value':html}]))
" > /tmp/azdo_patch.json

curl -s -o /dev/null -w "%{http_code}" -X PATCH \
  -H "Authorization: Basic $(printf ':%s' "$AZDO_CLI_WORKITEMS_PAT" | base64)" \
  -H "Content-Type: application/json-patch+json" \
  --data-binary "@/tmp/azdo_patch.json" \
  "$AZDO_ORG/$AZDO_PROJECT/_apis/wit/workitems/$TASK_ID?api-version=7.0"
```

Note: `az rest` with `--resource` fails with TF400813 on dev.azure.com — use curl with Basic auth (PAT) instead.

### 6 — Create branch

```bash
git checkout -b <type>/<TASK_ID>-MHE-<slugified-title>
```

### 7 — Output

Print the task URL: `$AZDO_ORG/$AZDO_PROJECT/_workitems/edit/$TASK_ID`
Print the branch name.
