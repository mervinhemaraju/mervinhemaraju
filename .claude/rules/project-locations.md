# DuoKey Project Locations

Local clones of DuoKey repos. When a task touches one of these systems,
check the matching path for existing conventions (module layout, chart
values, script patterns) before writing anything new, and reference files
there directly instead of asking where things live.

| Project | Path |
|---|---|
| Cloudflare IaC | `~/Projects/work/azuredev/duokeych/dke-devops/dke-cloudflare-iac` |
| DuoKey Helm charts | `~/Projects/work/azuredev/duokeych/dke-devops/dke-devops` |
| GCP IaC | `~/Projects/work/azuredev/duokeych/dke-devops/dke-infra-gcp` |
| Vercel IaC | `~/Projects/work/azuredev/duokeych/dke-devops/dke-vercel-iac` |
| Tech documentation | `~/Projects/work/azuredev/duokeych/dke-devops/docs-internal` |
| Cockpit | `~/Projects/work/azuredev/duokeych/dke-cockpit-rs/dke-cockpit-rs` |
| MPC (KMS) | `~/Projects/work/azuredev/duokeych/dke-kms-mpc/dke-kms-mpc` |

## When to use this

- A request names one of these systems (Cloudflare, GCP infra, Vercel,
  docs-internal, Cockpit, MPC) or asks to build/troubleshoot/change
  something that lives in one of them.
- Read the matching path first to match existing patterns before writing
  new Terraform, Helm, or scripts.
- Browsing/reading these paths needs no extra approval. Editing a file
  inside them still goes through the normal approval workflow: see
  `no-auto-changes.md`.
