---
page_title: Versioning, Refactors, and Upgrades
description: >-
  Defines semantic versioning policy for modules, safe refactor patterns using moved blocks, and how to document and execute upgrades.
---

# Versioning, Refactors, and Upgrades

## Audience
Maintainers and anyone making breaking or structural changes to modules.

## Purpose
Consolidate versioning policy, upgrade paths, and refactor mechanics.

## Semantic Versioning Policy
- Use semantic versioning for modules.
- Document breaking changes and include migration notes.
- Keep backward compatibility where possible using `moved` blocks.

## `moved` Blocks and Safe Refactors
Terraform interprets address changes as destroy and recreate unless you add `moved` blocks. Use `moved` to preserve state across refactors.

Example:
```hcl
moved {
  from = aws_instance.a
  to   = aws_instance.b
}
```

## Requirements
- Terraform v1.1+ is required for `moved` blocks. Use `terraform state mv` only when you cannot use `moved`.

## Refactor Scenarios
### Move or Rename a Resource
```hcl
moved {
  from = aws_instance.a
  to   = aws_instance.b
}
```

### Enable `for_each` or `count` for a Resource
Switching from single-instance to multiple instances requires mapping the old address to a specific key or index.

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

### Enable `count` or `for_each` for a Module Call
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

### Rename a Module Call
```hcl
module "b" {
  source = "../modules/example"
}

moved {
  from = module.a
  to   = module.b
}
```

### Split a Module
When splitting a module into multiple modules, use a shim module that calls the new modules and includes `moved` blocks to map old resource addresses to their new locations.

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
Removing a `moved` block is a breaking change. Retain historical `moved` blocks whenever possible to preserve upgrade paths for existing users.

If you must remove them, do so only when you are confident all consumers have applied the newer module version. If you rename the same object multiple times, chain `moved` blocks to preserve the full history.

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
- `04-module-interfaces-and-arguments.md` for interface change implications.
- `05-providers-state-and-backends.md` for state layout considerations.
