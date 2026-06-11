---
name: k8s-troubleshoot
description: Troubleshoot a failing Kubernetes resource or issue bottom-up, find the root cause, and propose a fix. Invoke with /k8s-troubleshoot <namespace> [<kind>/<name>] [issue description]. Assumes you are already authenticated to the cluster.
allowed-tools: Bash(kubectl get:*), Bash(kubectl describe:*), Bash(kubectl logs:*), Bash(kubectl events:*), Bash(kubectl top:*), Bash(kubectl exec:*), Bash(kubectl api-resources:*), Bash(kubectl explain:*), Bash(kubectl config current-context:*), Bash(kubectl cluster-info:*), Bash(kubectl version:*), Bash(kubectl rollout status:*), Bash(kubectl rollout history:*), Bash(kubectl auth can-i:*), Read(~/Projects/work/azuredev/duokeych/dke-devops/dke-devops/helm-charts/**), Read(~/Projects/work/azuredev/duokeych/dke-devops/dke-infra-aws/apps/**), Read(~/Projects/work/azuredev/duokeych/dke-devops/dke-infra-gcp/apps/**), Write(k8s-troubleshoot-*.md)
---

# Kubernetes Troubleshoot: $ARGUMENTS

Troubleshoot a failing resource bottom-up. The user is already authenticated
to the cluster. Be fast and systematic — check each layer one by one, report
findings as you go, and stop digging once the root cause is proven.

## Arguments

Parse `$ARGUMENTS` in this order:

- **`NAMESPACE`** — first token, mandatory. If `$ARGUMENTS` is empty, ask
  for the namespace before starting.
- **`RESOURCE`** — optional: `<kind>/<name>` or `<kind> <name>` right after
  the namespace.
- **`DESCRIPTION`** — optional: everything else is a free-text description
  of the issue (e.g. "api returns 503 since this morning").

At least one of `RESOURCE` or `DESCRIPTION` must be present — if both are
missing, ask what is failing. If only a description is given, identify the
affected resource(s) yourself in step 1 before triaging.

## Ground Rules

- **Read-only.** Pre-approved commands above are reads. NEVER run mutating
  commands (`apply`, `delete`, `edit`, `scale`, `rollout restart`, `patch`,
  `cordon`, `drain`, `port-forward`) — these always need explicit user
  approval, and only as part of an agreed fix.
- **`kubectl exec` is for diagnostics only.** Use one-shot non-interactive
  commands (`kubectl exec <pod> -- <cmd>`, never `-it`). Inside the pod,
  run only read/inspect commands (cat, ls, ps, df, curl to health endpoints,
  nslookup, etc.). NEVER run anything mutating inside a pod — no writes,
  deletes, installs, restarts, or kill signals — without explicit approval.
- **Secrets:** check existence and key names only
  (`kubectl get secret <n> -n <ns> -o jsonpath='{.data}' | jq 'keys'` or
  `kubectl describe secret`). NEVER print secret values, even base64-encoded.
  When inspecting env vars inside a pod, mask values whose names suggest
  credentials (KEY, TOKEN, SECRET, PASSWORD, PAT).
- **Cross-namespace:** if evidence points to a resource in another namespace
  (a backing service, an operator, a controller), follow it with the same
  read-only commands. No approval needed.
- **Keep an audit trail:** remember every command you run and what it proved
  or ruled out — needed for the optional report in step 5.

## 1 — Orient

```bash
kubectl config current-context
```

Note the cloud provider (AWS or GCP) from the context/node names — needed
for helm chart lookup later.

**If a resource was given:**

```bash
kubectl get <kind> <name> -n <namespace> -o wide
```

Confirm it exists; if not, list similar names in the namespace and ask
which one.

**If only a description was given**, survey the namespace to locate the
affected resource(s):

```bash
kubectl get all -n <namespace>
kubectl get events -n <namespace> --sort-by=.lastTimestamp
```

Match what you see (crashloops, restarts, warnings, names mentioned in the
description) against the description. State which resource(s) you picked as
the starting point and why, then proceed. If nothing in the namespace
plausibly matches the description, say so and ask for a pointer.

## 2 — Triage Bottom-Up

Work upward through the layers. At each layer, state what you checked and
whether it's healthy before moving on. Skip layers that don't apply to the
resource kind.

1. **Pods** — `kubectl get pods` (selector from the workload), then for
   unhealthy pods: `kubectl describe pod` (events, probe failures, OOMKilled,
   image pull errors, scheduling failures), `kubectl logs` and
   `kubectl logs --previous` for crashed containers. Use `kubectl exec` for
   in-pod checks (config files, connectivity, DNS) when the outside view is
   inconclusive.
2. **Controller** — ReplicaSet/Deployment/StatefulSet/DaemonSet:
   `kubectl describe`, `kubectl rollout history`. Look for failed rollouts,
   resource quota issues, bad image tags.
3. **Config** — referenced ConfigMaps and Secrets exist? Keys match what the
   pod mounts/envs expect? (Names only — see ground rules.)
4. **Service / Endpoints** — `kubectl get endpoints`: do selectors actually
   match pod labels? Empty endpoints = selector or readiness mismatch.
5. **Ingress / networking** — Ingress/IngressRoute (Traefik), certificates,
   external-dns annotations if exposure is the problem.
6. **Node / cluster** — `kubectl describe node` for the affected nodes:
   pressure conditions, capacity. `kubectl get events -n <ns>
   --sort-by=.lastTimestamp` for anything missed.
7. **Dependencies** — if a layer points elsewhere (operator in another
   namespace, ArgoCD app out of sync, external-secrets not syncing), follow
   the chain with the same read commands until the true origin is found.

## 3 — Correlate with Helm Charts

When the issue traces back to configuration, find the chart that deploys it:

- App charts: `~/Projects/work/azuredev/duokeych/dke-devops/dke-devops/helm-charts/`
- Core apps (argocd, external-secrets, external-dns, traefik):
  - AWS cluster → `~/Projects/work/azuredev/duokeych/dke-devops/dke-infra-aws/apps/`
  - GCP cluster → `~/Projects/work/azuredev/duokeych/dke-devops/dke-infra-gcp/apps/`
- Not found in any of these → ask the user where the chart lives.

Compare chart values/templates against the live state to pinpoint whether
the fault is in the chart, the values, or the cluster.

## 4 — Report Root Cause

Concise output, no padding:

- **Root cause** — one or two sentences, with the proving evidence.
- **Fix** — exact change needed (chart diff, value change, or kubectl
  command). Do NOT apply it. If a fix requires a mutating command, say so
  and wait for explicit approval. If no fix is possible from here, say what
  is blocking and who/what can unblock it.

Then ask: **"Want a detailed report written to a markdown file?"**

## 5 — Detailed Report (only if requested)

Write `k8s-troubleshoot-<resource>-<YYYY-MM-DD>.md` to the current working
directory:

- Summary: resource, namespace, cluster context, root cause, fix.
- Investigation timeline: each command run, in order, with a short note on
  what it showed and what it ruled out.
- Evidence: the key output snippets that prove the root cause.
- Fix: exact steps/diffs, and rollback notes if applicable.

Plain markdown, straightforward language. No emojis, no fluff.
