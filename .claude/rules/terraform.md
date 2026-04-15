# Terraform Rules

## Style & Formatting

- Always run `terraform fmt` before considering any file done
- Use `terraform validate` after any change to catch syntax errors early
- 2-space indentation, one blank line between blocks
- Resource names use snake_case — never kebab-case or camelCase
- No hardcoded values — use variables, locals, or data sources

## File Structure

Every module/root must follow this layout:
main.tf          # core resources
variables.tf     # all input variables
outputs.tf       # all outputs
locals.tf        # local values and computed expressions
versions.tf      # required_providers and terraform version constraint
terraform.tfvars # default values (never commit secrets here)

## Variables

- Every variable must have a `description` and `type` — no exceptions
- Use `validation` blocks for variables with constrained values
- Sensitive variables must have `sensitive = true`
- Never use `any` as a type — be explicit (string, number, bool, list, map, object)

```hcl
variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}
```

## Outputs

- Every output must have a `description`
- Mark sensitive outputs with `sensitive = true`
- Only expose what consumers actually need

## Locals

- Use `locals` to avoid repeating expressions
- Common tags belong in a local, not duplicated across resources

```hcl
locals {
  common_tags = {
    environment = var.environment
    project     = var.project_name
    managed_by  = "terraform"
  }
}
```

## Versioning

- Always pin provider versions with `~>` (pessimistic constraint)
- Always set a minimum Terraform version in `versions.tf`
- Never use an unpinned provider

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

## State

- Remote state is mandatory — never use local state for real environments
- State backend config goes in `backend.tf` — never inline in `main.tf`
- Never store secrets in state if avoidable — use secret manager references
- Never manually edit `.tfstate` files

## Secrets

- Never hardcode secrets, passwords, or tokens anywhere in `.tf` files
- Use environment variables (`TF_VAR_*`) or a secrets manager (Vault, AWS SSM, GCP Secret Manager)
- `terraform.tfvars` must be in `.gitignore` if it contains sensitive values
- `.terraform/` directory must always be in `.gitignore`

## Modules

- Prefer small, single-purpose modules over monolithic ones
- Module source must be pinned to a specific version/tag — no floating refs
- All module inputs must be explicitly passed — no relying on inherited scope
- Document every module with a README.md covering: purpose, inputs, outputs, example usage

```hcl
# Good — pinned version
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"
  ...
}

# Bad — unpinned
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  ...
}
```

## Resource Naming

- Follow the pattern: `{resource_type}_{purpose}_{qualifier}`
- Example: `aws_s3_bucket_app_assets`, `google_compute_instance_api_server`
- Always apply common_tags to every resource that supports tags

## Plan Before Apply

- Always run `terraform plan` and review output before `terraform apply`
- Never run `terraform apply -auto-approve` in production
- Destroy operations (`terraform destroy`) require explicit approval — always flag this to me

## What You Must Never Do

- Never run `terraform apply` without showing me the plan first
- Never run `terraform destroy` without explicit instruction from me
- Never modify `.tfstate` directly
- Never commit `.terraform/`, `*.tfvars` with secrets, or `*.tfplan` files
- Never use `terraform force-unlock` without flagging it to me first
