# Create Azure DevOps Task

## Arguments

`$ARGUMENTS` is the task title. Stop with a usage message if it is empty.

## Steps

### 1 — Verify env vars and resolve org + project

Check `AZDO_ASSIGNEE` is set:

```bash
echo "AZDO_ASSIGNEE=$AZDO_ASSIGNEE"
```

If empty, stop and tell the user to export it in `~/.zshenv`.

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

### 2 — Generate description and acceptance criteria

From the title in `$ARGUMENTS`, generate:

- **Description** (2–4 sentences): what the task is, why it matters, expected approach.
- **Acceptance Criteria** (3–6 bullets): specific, testable conditions, each starting with an action verb (Implement, Verify, Ensure, Add, Confirm).

Show both to the user and wait for approval before continuing.

### 3 — Create the task

```bash
az boards work-item create \
  --title "$ARGUMENTS" \
  --type "Task" \
  --project "$AZDO_PROJECT" \
  --organization "$AZDO_ORG" \
  --output json
```

Capture the `id` field from the JSON output as `TASK_ID`.

### 4 — Assign to me

```bash
az boards work-item update --id $TASK_ID \
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

az rest --method patch \
  --uri "$AZDO_ORG/$AZDO_PROJECT/_apis/wit/workitems/$TASK_ID?api-version=7.0" \
  --headers "Content-Type=application/json-patch+json" \
  --body "@/tmp/azdo_patch.json" \
  --resource "499b84ac-1321-427f-aa17-267ca6975798"
```

Note: `--resource 499b84ac-1321-427f-aa17-267ca6975798` is required for dev.azure.com — omitting it causes TF400813 "not authorized".

### 6 — Output

Print the task URL: `$AZDO_ORG/$AZDO_PROJECT/_workitems/edit/$TASK_ID`
