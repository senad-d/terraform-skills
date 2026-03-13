---
page_title: Module Interfaces, Variables, and Validation
description: >-
  Defines how to design module inputs and outputs, structure variables and
  validation, use Terraform meta-arguments safely, and present a stable,
  composable interface.
---

# Module Interfaces, Variables, and Validation

## Audience
Engineers designing inputs, outputs, variables, and calling patterns for modules.

## Purpose
Define best practices for variables, validation, outputs, meta-arguments
(`for_each`, `count`, `depends_on`), dynamic nested blocks, and interface
stability. This is the canonical guide for module interfaces, variables, and
validation.

## Interface Design Principles
- Provide variable descriptions and validations for all public inputs.
- Prefer explicit types over implicit typing.
- Use `nullable = false` where appropriate to avoid ambiguous defaults.
- Keep interfaces stable; avoid frequent renames or breaking changes.
- Document outputs with descriptions and mark sensitive outputs with
  `sensitive = true`.
- Keep interfaces environment-agnostic by default; accept environment-specific
  values (regions, account IDs) as inputs when needed.

For composition patterns and how interfaces are consumed at the root-module
level, see `07-composition-and-patterns.md`.

## Variables and Inputs

### Required Fields for Variables
Every input variable must include:
- `description` with a clear, concise purpose.
- `type` with explicit typing.
- `validation` with both `condition` and `error_message` where constraints exist.
- `default` if the variable is optional.
- `nullable = false` unless `null` has a deliberate meaning.

Example (required variable):
```hcl
variable "vpc_id" {
  description = "VPC ID where resources will be created."
  type        = string
  nullable    = false

  validation {
    condition     = length(var.vpc_id) > 0
    error_message = "vpc_id must be a non-empty string."
  }
}
```

Example (optional variable with default):
```hcl
variable "enable_logging" {
  description = "Whether to enable logging for this module."
  type        = bool
  default     = true
  nullable    = false
}
```

### Naming and Structure
- Use `snake_case` for variable names.
- Prefer objects and maps for grouped configuration over many loosely related
  variables.
- Avoid `any` except for advanced passthrough cases that are documented and
  validated.
- Keep variable names consumer-focused (for example, `enable_logging` rather
  than an internal flag name).

Example (object variable with validation):
```hcl
variable "subnet_config" {
  description = "Subnet configuration for the module."
  type = object({
    cidr_block = string
    az         = string
  })
  nullable = false

  validation {
    condition     = can(cidrhost(var.subnet_config.cidr_block, 0))
    error_message = "subnet_config.cidr_block must be a valid CIDR block."
  }
}
```

### Sensitive Inputs
If a variable may contain secrets (for example, passwords, tokens, or
connection strings):
- Treat it as sensitive in documentation and examples.
- Avoid writing values to logs or outputs.
- Ensure any related outputs are marked `sensitive = true`.
- Follow the broader security and secret-handling rules in
  `08-security-naming-and-tagging.md`.

## Validation Guidance
Use validation blocks to enforce:
- Non-empty strings.
- Valid CIDR blocks.
- Allowed enumerations (use `contains([...], var.value)`).
- Ranges for numbers.
- Internal consistency of object fields.

Keep error messages actionable and specific so users understand how to fix
invalid input.

Example:
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

## Outputs and Consumer Expectations
Outputs define the contract between a module and its consumers.

Guidelines:
- Every output must include a `description` explaining its purpose.
- Outputs should be stable over time; prefer adding new outputs over renaming
  existing ones.
- Use structured types (objects, maps, lists) when returning related values.
- Mark outputs that may expose secrets or sensitive identifiers with
  `sensitive = true`.
- Use preconditions on outputs when they must only be exposed under specific
  safe conditions.

Example with a precondition:
```hcl
output "api_base_url" {
  value = "https://${aws_instance.example.private_dns}:8433/"

  precondition {
    condition     = data.aws_ebs_volume.example.encrypted
    error_message = "The server's root volume is not encrypted."
  }
}
```

For versioning and refactor implications when changing outputs, see
`06-sources-and-distribution.md`.

## Meta-Arguments in Modules
Terraform meta-arguments let you scale configurations without duplicating code.
Use them on `resource`, `data`, and `module` blocks as appropriate.

Reusable modules must not contain `provider` blocks. They should declare
provider requirements only in `required_providers` (typically in
`versions.tf`). Modules that configure providers cannot be safely used with
`for_each`, `count`, or `depends_on` on module calls.

### `for_each`
`for_each` creates one instance per element in a map or set of strings. Use it
when each instance has a stable identity.

Typical uses:
- Multiple named subnets.
- Security group rules from a map of rule objects.
- One IAM role per component or environment.
- Multiple module instances keyed by environment, region, or account.

Example: multiple subnets
```hcl
variable "subnets" {
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
}

resource "aws_subnet" "this" {
  for_each = var.subnets

  vpc_id            = var.vpc_id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = {
    Name = each.key
  }
}
```

Example: security group rules from a map
```hcl
variable "ingress_rules" {
  type = map(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
}

resource "aws_security_group_rule" "ingress" {
  for_each = var.ingress_rules

  type              = "ingress"
  security_group_id = var.security_group_id
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
}
```

Example: IAM roles per component
```hcl
variable "components" {
  type = set(string)
}

data "aws_iam_policy_document" "assume_role" {
  for_each = var.components

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  for_each = var.components
  name     = "${each.key}-role"

  assume_role_policy = data.aws_iam_policy_document.assume_role[each.key].json
}
```

### `count`
`count` creates a fixed number of instances, addressed by index.

Typical uses:
- Simple replication where identity is not important.
- Optional resources controlled by booleans (0 or 1 instance).

Caveat: identity is tied to indices; changing `count` or ordering can cause
replacement.

Example: optional resource
```hcl
resource "aws_cloudwatch_log_group" "this" {
  count = var.enable_logging ? 1 : 0

  name              = "${var.name}-logs"
  retention_in_days = 30
}
```

Example: fixed number of instances
```hcl
resource "aws_instance" "worker" {
  count = var.instance_count

  ami           = var.ami_id
  instance_type = var.instance_type

  tags = {
    Name = "worker-${count.index}"
  }
}
```

### `depends_on`
Prefer implicit dependencies expressed via attribute references. Use
`depends_on` only when there is no attribute reference or when API constraints
require explicit ordering.

Example:
```hcl
resource "aws_cloudwatch_log_subscription_filter" "this" {
  name            = "lambda-subscriber"
  log_group_name  = var.log_group_name
  filter_pattern  = ""
  destination_arn = var.lambda_function_arn

  depends_on = [aws_lambda_permission.logs]
}
```

## Meta-Arguments on Module Calls
`for_each`, `count`, and `depends_on` can be used on module blocks. Called
modules must not define provider blocks.

Example: `for_each` on a module
```hcl
module "network" {
  for_each = var.environments
  source   = "./modules/aws-network"

  name       = each.key
  cidr_block = each.value.cidr_block
}
```

Example: `count` on a module
```hcl
module "worker" {
  count  = var.worker_stack_count
  source = "./modules/worker-stack"

  name_suffix = count.index
}
```

Example: `depends_on` on a module
```hcl
module "app" {
  source = "./modules/app"

  vpc_id       = module.network.vpc_id
  database_url = module.database.url

  depends_on = [module.network, module.database]
}
```

## Dynamic Blocks and Conditional Sections (Interface-Focused)
Dynamic blocks let you generate nested configuration blocks from variable
structures. They are tightly coupled to variable design and defaults.

### When to Use Dynamic Blocks
Use `dynamic` blocks when a resource supports nested blocks that are:
- Optional and should appear only when input is provided.
- Repeated and should be generated from a list or map.

Prefer static blocks when the nested block is always present or when only a
single optional attribute can be handled with `null` or `try()` without
conditional generation.

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

### How Dynamic Blocks Affect Variables
- Inputs should be structured as lists or maps of objects that match the nested
  block schema.
- Defaults should be empty (`[]` or `{}`) to avoid creating blocks
  unintentionally.
- Use `nullable = false` to keep evaluation predictable.
- Add validation to enforce required fields and acceptable ranges.

### Dynamic Block Anti-Patterns
Avoid:
- Using `dynamic` blocks to hide required configuration.
- Passing raw `any` or loosely typed variables to dynamic blocks.
- Omitting validation for nested object inputs.

## Decision Guidelines for Meta-Arguments and Dynamic Blocks
Use `for_each` when:
- Instances have meaningful identities.
- You want stable addressing by key.

Use `count` when:
- You need a simple toggle or fixed number of instances.
- Index-based identity is acceptable.

Use `depends_on` when:
- There is no attribute reference to express the dependency.
- Ordering is required by provider behavior or side effects.

Use `dynamic` blocks when:
- The nested block is optional or repeated.
- A structured variable (object, list, or map) can represent the desired
  configuration cleanly.

## Refactoring Interfaces Safely
Adding `for_each` or `count`, or restructuring variables and outputs, changes
addresses and can trigger destructive plans. Use `moved` blocks to preserve
state when refactoring.

For semantic versioning policy, `moved` block patterns, and upgrade playbooks,
see `06-sources-and-distribution.md`.

## Related Guides
- `07-composition-and-patterns.md` for composition patterns and root module
  design.
- `05-providers-state-and-backends.md` for provider rules and state layout.
- `06-sources-and-distribution.md` for refactor and upgrade guidance.
- `08-security-naming-and-tagging.md` for security and secret-handling
  requirements.
