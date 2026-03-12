---
page_title: Module Interfaces and Arguments
description: >-
  Defines how to design module inputs and outputs, use Terraform meta-arguments safely, and present a stable, composable interface.
---

# Module Interfaces and Arguments

## Audience
Engineers designing inputs, outputs, and calling patterns for modules.

## Purpose
Define best practices for variables, outputs, meta-arguments (`for_each`, `count`, `depends_on`), and interface stability.

## Interface Design Principles
- Provide variable descriptions and validations for all public inputs.
- Prefer explicit types over implicit typing.
- Use `nullable = false` where appropriate to avoid ambiguous defaults.
- Document outputs with descriptions and mark sensitive outputs with `sensitive = true`.

For detailed variable standards, see `13-variables-and-validation.md`.

## Module Interface Contract (Template)
Use this template in planning or documentation to make interfaces explicit and reviewable.

Inputs:
| Name | Type | Required | Default | Sensitive | Validation | Description |
| --- | --- | --- | --- | --- | --- | --- |
| `example_input` | `string` | yes | n/a | no | `length > 0` | Short purpose statement |

Outputs:
| Name | Type | Sensitive | Description |
| --- | --- | --- | --- |
| `example_output` | `string` | no | Short purpose statement |

## Meta-Arguments in Modules
Terraform meta-arguments let you scale configurations without duplicating code. Use them on `resource`, `data`, and `module` blocks as appropriate.

Reusable modules must not contain `provider` blocks. They should declare provider requirements only in `required_providers` (typically in `versions.tf`). Modules that configure providers cannot be safely used with `for_each`, `count`, or `depends_on` on module calls.

### `for_each`
`for_each` creates one instance per element in a map or set of strings. Use it when each instance has a stable identity.

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

Caveat: identity is tied to indices; changing `count` or ordering can cause replacement.

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
Prefer implicit dependencies expressed via attribute references. Use `depends_on` only when there is no attribute reference or when API constraints require explicit ordering.

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
`for_each`, `count`, and `depends_on` can be used on module blocks. Called modules must not define provider blocks.

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

## Decision Guidelines
Use `for_each` when:
- Instances have meaningful identities.
- You want stable addressing by key.

Use `count` when:
- You need a simple toggle or fixed number of instances.
- Index-based identity is acceptable.

Use `depends_on` when:
- There is no attribute reference to express the dependency.
- Ordering is required by provider behavior or side effects.

## Refactoring for `for_each` or `count`
Adding `for_each` or `count` changes addresses and can trigger destructive plans. Use `moved` blocks to preserve state when refactoring. See `11-versioning-refactors-and-upgrades.md` for patterns.

## Related Guides
- `07-composition-and-patterns.md` for composition patterns.
- `05-providers-state-and-backends.md` for provider rules.
- `11-versioning-refactors-and-upgrades.md` for refactor guidance.
- `12-dynamic-blocks-and-conditional-sections.md` for dynamic block patterns.
- `13-variables-and-validation.md` for variable standards and validation.
