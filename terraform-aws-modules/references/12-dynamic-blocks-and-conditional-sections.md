---
page_title: Dynamic Blocks and Conditional Sections
description: >-
  How to use dynamic nested blocks in Terraform modules, when to prefer them, and how they impact variable design and validation.
---

# Dynamic Blocks and Conditional Sections

## Audience
Module authors implementing optional or repeated nested configuration blocks.

## Purpose
Explain when and how to use `dynamic` blocks in modules and how that choice shapes variable design, defaults, and validation.

## When to Use Dynamic Blocks
Use `dynamic` blocks when a resource supports nested blocks that are:
- Optional and should appear only when input is provided.
- Repeated and should be generated from a list or map.

Prefer static blocks when the nested block is always present or when only a single optional attribute can be handled with `null` or `try()` without conditional generation.

## Core Patterns
### Single Optional Nested Block
Use a list with zero or one element and iterate over it:

```hcl
variable "logging" {
  type = list(object({
    destination_arn = string
    log_format      = string
  }))
  default  = []
  nullable = false
}

resource "aws_lb" "this" {
  # ... other arguments ...

  dynamic "access_logs" {
    for_each = var.logging
    content {
      bucket  = access_logs.value.destination_arn
      prefix  = access_logs.value.log_format
      enabled = true
    }
  }
}
```

### Repeated Nested Blocks
Use a map or list of objects to create multiple blocks:

```hcl
variable "ingress_rules" {
  type = map(object({
    from_port = number
    to_port   = number
    protocol  = string
    cidr      = string
  }))
  default  = {}
  nullable = false
}

resource "aws_security_group" "this" {
  # ... other arguments ...

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = [ingress.value.cidr]
    }
  }
}
```

## How Dynamic Blocks Affect Variables
- Inputs should be structured as lists or maps of objects that match the nested block schema.
- Defaults should be empty (`[]` or `{}`) to avoid creating blocks unintentionally.
- Use `nullable = false` to keep evaluation predictable.
- Add validation to enforce required fields and acceptable ranges.

## Validation Guidance
Add validation to ensure dynamic blocks are well-formed and safe:

```hcl
variable "ingress_rules" {
  type     = map(object({ from_port = number, to_port = number, protocol = string, cidr = string }))
  default  = {}
  nullable = false

  validation {
    condition     = alltrue([for r in var.ingress_rules : r.from_port <= r.to_port])
    error_message = "Each ingress rule must have from_port <= to_port."
  }
}
```

## Anti-Patterns
- Using `dynamic` blocks to hide required configuration.
- Passing raw `any` or loosely typed variables to dynamic blocks.
- Omitting validation for nested object inputs.

## Related Guides
- `04-module-interfaces-and-arguments.md` for interface design.
- `13-variables-and-validation.md` for variable requirements.
