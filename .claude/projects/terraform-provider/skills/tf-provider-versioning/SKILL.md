---
name: tf-provider-versioning
description: Use when versioning a Terraform provider release, writing a CHANGELOG, or naming resources, data sources, attributes, or functions — covers official HashiCorp semver rules, breaking change classification, CHANGELOG.md format, and naming conventions.
---

# Skill: Terraform Provider Versioning & Naming

# Source: https://developer.hashicorp.com/terraform/plugin/best-practices/versioning

# Source: https://developer.hashicorp.com/terraform/plugin/best-practices/naming

## Semantic Versioning (Provider Context)

Versioning is about **user state and configurations** — not code contracts.

```
MAJOR.MINOR.PATCH
```

### MAJOR — Breaking changes (increment max once per year)

Breaking = anything that can break existing user configs or state:

- Removing a resource or data source
- Removing or renaming an attribute
- Renaming a resource or data source
- Changing resource import ID format or resource ID format
- Changing attribute type incompatibly (e.g. TypeSet → TypeList)
- Changing attribute format (e.g. epoch timestamp → RFC 3339 string)
- Changing a default value incompatibly with existing state
- Adding a default value that doesn't match the API default
- Changing fundamental provider behaviours (auth, config precedence)

### MINOR — New features, backwards compatible

- Adding a new resource or data source
- Marking a resource, data source, or attribute as deprecated
- Adding new attributes to existing resources
- Adding new validation to existing resources
- Aliasing an existing resource or data source
- Changing attribute type compatibly (e.g. TypeInt → TypeFloat)

### PATCH — Bug fixes, functionally equivalent

- Fixing broken CRUD operations
- Fixing attributes to match actual API behaviour
- Fixing validation logic
- Documentation updates

---

## CHANGELOG.md Format

The changelog must live at the project root as `CHANGELOG.md`.
The upcoming release is always at the top, marked `(Unreleased)`.

```markdown
## 1.2.0 (Unreleased)

FEATURES:

- **New Resource:** `<n>_cluster` [GH-43]

IMPROVEMENTS:

- resource/thing: Add `tags` attribute [GH-12]
- resource/thing: Add `enabled` attribute [GH-15]

BUG FIXES:

- resource/thing: Fix read returning incorrect `description` value [GH-20]

## 1.1.0 (January 15, 2026)

BREAKING CHANGES:

- resource/thing: `region` attribute is now Required (was Optional) [GH-8]

NOTES:

- provider: Minimum Terraform version is now 1.3 [GH-9]

FEATURES:

- **New Data Source:** `<n>_things` [GH-11]

## 1.0.0 (December 1, 2025)

FEATURES:

- **New Resource:** `<n>_thing` [GH-1]
- **New Resource:** `<n>_project` [GH-2]
```

### Changelog Categories (in order)

1. `BREAKING CHANGES` / `BACKWARDS INCOMPATIBILITIES` — major version only
2. `NOTES` — unexpected upgrade behaviour, upcoming deprecations
3. `FEATURES` — new resources, data sources, major new capabilities
4. `IMPROVEMENTS` / `ENHANCEMENTS` — new attributes, minor improvements
5. `BUG FIXES` — bug fixes

### Entry Format

```
* subsystem: Descriptive message [GH-####]
```

- `subsystem` is the resource/data source name e.g. `resource/thing`, `data-source/things`, `provider`
- `[GH-####]` references the PR number
- Order: `provider` entries first, then lexicographically by subsystem

---

## Naming Conventions

### Provider Name

Repository: `terraform-provider-<n>`
Provider address: `registry.terraform.io/<org>/<n>`

### Resource Names

- Format: `<provider>_<noun>` — always provider prefix + underscore
- Use nouns (resources represent objects)
- Match names familiar to users of the service (match the API / web UI terminology)
- Examples: `postgresql_database`, `aws_instance`, `github_repository`

```go
resp.TypeName = req.ProviderTypeName + "_thing"   // correct
resp.TypeName = "thing"                            // WRONG — missing provider prefix
```

### Data Source Names

- Same rules as resources — nouns
- Can be **plural** when returning a list
- Examples: `aws_availability_zones` (list), `github_repository` (single)

### Function Names

- Use **verbs** (functions perform computation)
- Do NOT include provider name (it's already in the call syntax: `provider::<n>::parse_rfc3339`)
- All lowercase with underscores: `parse_rfc3339`, `encode_base64`

### Attribute Names

- All lowercase with underscores: `instance_type`, `vpc_id`, `created_at`
- Single-value attributes: singular noun (`ami`, `region`, `name`)
- Boolean attributes: noun or verb describing what is enabled (`monitoring`, `delete_on_termination`)
- **Boolean orientation: `true` = DO, `false` = DON'T** — avoid negative flags
- List/set/map attributes: plural noun (`tags`, `security_group_ids`, `availability_zones`)
- Sub-blocks: singular noun even if multiple allowed (`root_block_device`)
- Write-only arguments: suffix with `_wo` (`password_wo`, `token_wo`)
- Dates/times: always RFC 3339 format (`2024-01-15T10:30:00Z`)

### Deprecation Pattern

When deprecating an attribute (not removing — that's a major bump):

```go
"old_name": schema.StringAttribute{
    Optional:           true,
    Computed:           true,
    DeprecationMessage: "Use new_name instead. This attribute will be removed in a future major release.",
    Description:        "Deprecated: use new_name.",
},
"new_name": schema.StringAttribute{
    Optional:    true,
    Computed:    true,
    Description: "The new preferred attribute.",
},
```

---

## DO / DON'T: Versioning & Naming

- ✅ Release major versions no more than once per year
- ✅ Keep both old and new attribute names during deprecation period
- ✅ Document all breaking changes in `BREAKING CHANGES` section
- ✅ Use RFC 3339 for all date/time attributes
- ✅ Suffix write-only fields with `_wo`
- ❌ Never remove an attribute without first deprecating it in a minor release
- ❌ Never rename a resource without providing an alias first
- ❌ Never use negative boolean names (`disable_x`, `no_x`) — invert to positive
