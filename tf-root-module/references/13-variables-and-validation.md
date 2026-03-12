---
page_title: Variables and Validation Standards
description: >-
  Defines required standards for Terraform variables, including descriptions, types, defaults, validation conditions, and error messages.
---

# Variables and Validation Standards

## Audience
Module authors defining input variables for reusable modules.

## Purpose
Provide clear, enforceable standards for variable definitions to ensure stable, self-documenting interfaces.

## Required Fields
Every input variable must include:
- `description` with a clear, concise purpose.
- `type` with explicit typing.
- `validation` with both `condition` and `error_message` where constraints exist.
- `default` if the variable is optional.
- `nullable = false` unless `null` has a deliberate meaning.

## Naming and Structure
- Use `snake_case` for variable names.
- Prefer objects and maps for grouped configuration over many loosely related variables.
- Avoid `any` except for advanced passthrough cases that are documented and validated.

## Examples
### Required Variable
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

### Optional Variable with Default
```hcl
variable "enable_logging" {
  description = "Whether to enable logging for this module."
  type        = bool
  default     = true
  nullable    = false
}
```

### Object Variable with Validation
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

## Validation Guidance
Use validation to enforce:
- Non-empty strings.
- Valid CIDR blocks.
- Allowed enumerations (use `contains([...], var.value)`).
- Ranges for numbers.

Keep error messages actionable and specific.

## Sensitive Inputs
If a variable may contain secrets, mark related outputs as `sensitive = true` and avoid printing values in logs or documentation.

## Related Guides
- `04-module-interfaces-and-arguments.md` for interface patterns.
- `12-dynamic-blocks-and-conditional-sections.md` for dynamic block input design.
