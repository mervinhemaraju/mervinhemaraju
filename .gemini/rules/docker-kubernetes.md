# Docker / Kubernetes Rules

## Docker

- Always pin exact image versions — never use `latest`
- Multi-stage builds for production images
- Non-root user in all production containers
- `.dockerignore` must exist and exclude build artifacts, secrets, .git

## Kubernetes Manifests

- Resource `requests` AND `limits` required on every container
- Readiness and liveness probes required on every Deployment
- Use `RollingUpdate` strategy with `maxUnavailable: 0`
- Labels must include: `app`, `version`, `component`, `managed-by`

## Secrets

- Never put secrets or credentials in YAML manifests
- Use Kubernetes Secrets or external-secrets-operator
- Never log environment variable values that could contain secrets

## YAML Style

- 2-space indentation
- Explicit `namespace` on all resources
- Add comments on non-obvious fields
- Validate with kubeval or kubeconform before applying
