---
page_title: Module Distribution, Versioning, and Upgrades
description: >-
  Defines how to use the module source argument, when to use local paths vs
  registries, and how modules are versioned, pinned, and safely refactored and
  upgraded internally and externally.
---

# Module Distribution, Versioning, and Upgrades

## Audience
Engineers composing stacks from modules and deciding how to distribute modules,
manage versions, and plan safe upgrades.

## Purpose
Normalize guidance on the `source` argument, registry usage, internal module
distribution, version pinning, semantic versioning policy, and safe refactor and
upgrade patterns.

## Source Selection Guidance
- Use local relative paths (`./` or `../`) for closely related modules within the
  same repository.
- Use a Terraform module registry for modules intended to be shared across
  multiple configurations.
- Avoid absolute filesystem paths because they are treated like remote packages
  and couple configs to a specific machine layout.

## Supported Source Types
Terraform supports the following source types:
- Local paths
- Terraform Registry (public and private)
- GitHub
- Bitbucket
- Generic Git repositories (`git::` prefix)
- Generic Mercurial repositories (`hg::` prefix)
- HTTP URLs (archive downloads)
- S3 buckets (`s3::` prefix)
- GCS buckets (`gcs::` prefix)
- Modules in package subdirectories (`//` syntax)

## Local Paths
Local paths allow factoring within the same repository.

Example:
```hcl
module "consul" {
  source = "./consul"
}
```

A local path must begin with `./` or `../`. Absolute filesystem paths are
 treated as remote packages and are not recommended.

## Internal Child Modules (Repository Default)
- Root modules should source child modules in this repository using relative
  paths.
- Prefer `./modules/<name>` for child modules under `modules/`.
- Use registry or VCS sources only when the child module is intentionally
  external.

## Terraform Registry
Registry sources are the preferred distribution mechanism for reusable modules.
The standard format is `<NAMESPACE>/<NAME>/<PROVIDER>`.

Example:
```hcl
module "consul" {
  source  = "hashicorp/consul/aws"
  version = "0.1.0"
}
```

Private registries use a hostname prefix:
```hcl
module "consul" {
  source  = "app.terraform.io/example-corp/k8s-cluster/azurerm"
  version = "1.1.0"
}
```

Registry modules support version constraints and require appropriate
credentials for private registries.

## Modules in Package Subdirectories
If a module lives in a subdirectory of a package, use the `//` syntax:
```hcl
module "vpc" {
  source = "git::https://example.com/network.git//modules/vpc?ref=v1.2.0"
}
```

The module installer downloads the entire package but reads the module from the
subdirectory. Submodules can safely use local paths to other modules in the same
package.

## Version Pinning and Constraints

### Semantic Versioning Policy
- Use semantic versioning for modules.
- Document breaking changes and include migration notes.
- Keep backward compatibility where possible using `moved` blocks.

When using registry or VCS sources:
- Pin to a minimum compatible version using `>=` constraints when you control
  both producer and consumer.
- Pin to exact versions or narrow ranges when modules are shared broadly or
  across teams to avoid unplanned breaking changes.

Example (registry source with constraint):
```hcl
module "consul" {
  source  = "hashicorp/consul/aws"
  version = ">= 0.1.0, < 1.0.0"
}
```

Example (git source with tag):
```hcl
module "vpc" {
  source = "git::https://example.com/vpc.git?ref=v1.2.0"
}
```

Document version policies in module READMEs so consumers understand upgrade
expectations.

## `moved` Blocks and Safe Refactors
Terraform interprets address changes as destroy and recreate unless you add
`moved` blocks. Use `moved` to preserve state across refactors.

Example:
```hcl
moved {
  from = aws_instance.a
  to   = aws_instance.b
}
```

### Requirements
- Terraform v1.1+ is required for `moved` blocks. Use `terraform state mv` only
  when you cannot use `moved`.

### Refactor Scenarios
#### Move or Rename a Resource
```hcl
moved {
  from = aws_instance.a
  to   = aws_instance.b
}
```

#### Enable `for_each` or `count` for a Resource
Switching from single-instance to multiple instances requires mapping the old
address to a specific key or index.

Example:
```hcl
resource "aws_instance" "a" {
  for_each = local.instances
  instance_type = each.value.instance_type
}

moved {
  from = aws_instance.a
  to   = aws_instance.a["small"]
}
```

Other valid mappings:
```hcl
moved {
  from = aws_instance.c[0]
  to   = aws_instance.c["small"]
}

moved {
  from = aws_instance.d[2]
  to   = aws_instance.d
}
```

#### Enable `count` or `for_each` for a Module Call
```hcl
module "a" {
  source = "../modules/example"
  count  = 3
}

moved {
  from = module.a
  to   = module.a[2]
}
```

#### Rename a Module Call
```hcl
module "b" {
  source = "../modules/example"
}

moved {
  from = module.a
  to   = module.b
}
```

#### Split a Module
When splitting a module into multiple modules, use a shim module that calls the
new modules and includes `moved` blocks to map old resource addresses to their
new locations.

Example:
```hcl
module "x" {
  source = "../modules/x"
}

module "y" {
  source = "../modules/y"
}

moved {
  from = aws_instance.a
  to   = module.x.aws_instance.a
}
```

## Removing `moved` Blocks
Removing a `moved` block is a breaking change. Retain historical `moved` blocks
whenever possible to preserve upgrade paths for existing users.

If you must remove them, do so only when you are confident all consumers have
applied the newer module version. If you rename the same object multiple times,
chain `moved` blocks to preserve the full history.

Example:
```hcl
moved {
  from = aws_instance.a
  to   = aws_instance.b
}

moved {
  from = aws_instance.b
  to   = aws_instance.c
}
```

## Breaking Change Playbook
- Identify the exact breaking change and affected versions.
- Add `moved` blocks where possible to preserve state.
- Bump the major version and document upgrade notes.
- Update examples and README usage to the new interface.
- Call out required actions for consumers (renames, new inputs, removed outputs).
- Ensure validation and CI run against updated examples.

## Related Guides
- `01-overview-and-lifecycle.md` — documentation map and lifecycle overview.
- `02-module-creation-and-fundamentals.md` — when to create vs extend modules.
- `03-module-structure-and-layout.md` — required layout and structure.
- `04-module-interfaces-and-arguments.md` — variables, validation, outputs.
- `05-infrastructure-architecture-guidelines.md` — architecture baseline.
- `07-composition-and-patterns.md` — composition patterns and dependency wiring.
- `08-security-naming-and-tagging.md` — security and tagging baseline.
- `09-testing-and-ci.md` — validation workflow and CI gates.
- `10-examples.md` — examples and documentation expectations.
