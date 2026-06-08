---
name: terraform-change
description: Use when making any Terraform change — fetches official provider/module docs at the exact locked version before writing any plan, so argument names and behaviour are always accurate.
---

# Terraform Change: $ARGUMENTS

Follow these steps in order. Do not skip ahead.

## 1. Capture Version Context

Read the project to find exact versions in use:
- `.terraform.lock.hcl` — exact locked provider versions (prefer this)
- `versions.tf` — provider version constraints (fallback if lock file absent)
- Any `module` blocks — note `source` and `version` for registry modules

## 2. Fetch Official Docs

Before writing any plan, fetch the docs at the exact versions identified:
- **Providers**: `https://registry.terraform.io/providers/{namespace}/{provider}/{version}/docs/resources/{resource}`
- **Modules**: `https://registry.terraform.io/modules/{namespace}/{module}/{provider}/{version}`

If the lock file is absent, use the upper bound of the version constraint.
Do not rely on memory for argument names, attribute types, or defaults — always verify from the fetched docs.

## 3. Plan

Write a short implementation plan referencing only doc-confirmed attributes:
- Files to create or modify
- Exact resource/argument names as confirmed in the docs
- Any version-specific behaviour or deprecations noted in the docs

**Stop here. Show the plan and wait for approval.**

## 4. Implement

After approval, implement following the project's existing conventions and `~/.claude/rules/terraform.md`.
One change at a time. No scope creep.

## 5. Validate

Run read-only checks and report output:

```bash
terraform fmt -check
terraform validate
```

## 6. Summarise

List every file changed and what was done to each.
Do NOT run `terraform apply`. Do NOT commit or stage anything.
