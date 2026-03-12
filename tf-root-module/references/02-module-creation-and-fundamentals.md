---
page_title: Module Creation and Fundamentals
description: >-
  Defines what a Terraform module is in this repository, when to create one, and how modules relate to root modules and higher-level architecture.
---

# Module Creation and Fundamentals

## Audience
Engineers deciding whether to introduce a new module or reuse or refine existing ones.

## Purpose
Explain what modules are, when they are warranted, and how they relate to root modules and higher-level architecture.

## What Is a Module
A module is a container for multiple resources that are used together. Modules allow you to describe infrastructure in terms of architecture-level concepts rather than individual resource types.

The `.tf` files in your working directory when you run `terraform plan` or `terraform apply` together form the root module. The root module may call child modules and connect them by passing outputs from one module into inputs of another.

## When to Create a Module
Create a module when it introduces a reusable, higher-level abstraction that is meaningful in your architecture.

Indicators a module is warranted:
- The configuration represents a distinct architectural concept that will be reused.
- The abstraction improves readability and reduces duplication across stacks.
- The module boundary clarifies ownership, inputs, and outputs.
- The module helps reduce complexity by isolating a major component into its own project or directory.

Avoid creating modules that are thin wrappers around a single resource type. If the module name would be identical to the main resource it wraps, it is likely not adding value. Use the resource directly in the calling module instead.

## Composition and Dependency Inversion
Prefer a flat module tree and compose modules at the root module level. Keep dependencies explicit by passing required identifiers and values into modules rather than having modules create their own dependencies. This keeps modules flexible and easier to reuse in different combinations.

For composition patterns and data-only modules, see `07-composition-and-patterns.md`.

## Interface Expectations
- Use clear, typed inputs and outputs.
- Avoid hard-coded values; prefer variables with sensible defaults.
- Expose reusable values via outputs; mark sensitive outputs appropriately.

Detailed interface rules live in `04-module-interfaces-and-arguments.md` and `13-variables-and-validation.md`.

## Development Best Practices
- Prefer internal modules under `modules/` over re-implementing resources directly.
- Use `locals` for repeated values to keep configurations consistent.
- Start from official provider examples, then adapt to repository standards.
- Review inputs and outputs before implementation to avoid later refactors.
- Enable telemetry or logging features when available and appropriate.

## MCP Documentation Workflow (Required)
When planning a new module, use MCP documentation tools as the primary sources of truth. This avoids stale assumptions and keeps module behavior aligned with provider and service capabilities.

### AWS Documentation Tools
Use the AWS documentation MCP server for service behavior, limits, and best practices.

Available tools:
- `mcp__aws-knowledge-mcp-server__aws___search_documentation`
- `mcp__aws-knowledge-mcp-server__aws___read_documentation`
- `mcp__aws-knowledge-mcp-server__aws___recommend`
- `mcp__aws-knowledge-mcp-server__aws___list_regions`
- `mcp__aws-knowledge-mcp-server__aws___get_regional_availability`

Recommended usage:
1. Search for the service or feature with `search_documentation`.
2. Read the authoritative page with `read_documentation`.
3. If unsure about feature availability, check regions with `list_regions` and `get_regional_availability`.
4. Use `recommend` to discover related or newly added documentation pages.

Example search phrases:
```text
"S3 bucket encryption configuration"
"Lambda environment variables limits"
"RDS parameter group constraints"
```

### Terraform Documentation Tools
Use the Terraform MCP server to confirm provider resources, arguments, and schema details.

Available tools:
- `mcp__terraform-mcp-server__SearchAwsProviderDocs`
- `mcp__terraform-mcp-server__SearchAwsccProviderDocs`
- `mcp__terraform-mcp-server__SearchUserProvidedModule`
- `mcp__terraform-mcp-server__SearchSpecificAwsIaModules`

Recommended usage:
1. Use `SearchAwsProviderDocs` to confirm resource arguments, attributes, and examples for the AWS provider.
2. Use `SearchAwsccProviderDocs` when working with AWS Cloud Control (AWSCC) resources.
3. Use `SearchUserProvidedModule` to review upstream modules before re-implementing similar functionality.
4. Use `SearchSpecificAwsIaModules` when exploring AWS-IA reference modules for patterns and defaults.

Example search inputs:
```text
asset_name = "aws_s3_bucket"
asset_name = "aws_lambda_function"
module_url = "terraform-aws-modules/vpc/aws"
```

### Planning Expectations
- Capture findings from AWS and Terraform docs in your planning notes.
- If documentation is ambiguous, prefer the most conservative, secure defaults.
- Do not proceed with implementation until documentation sources confirm the required behavior.

## Planning Requirements (Production Modules)
Before implementing a new module, document the following in a short plan:
- Module goal, scope boundaries, and non-goals.
- Primary AWS services and Terraform resources involved (validated via MCP docs).
- Expected inputs and outputs, including sensitive fields.
- Security defaults and any required exceptions.
- Example scenario(s) and supporting modules required.

Use the plan scaffolding script:
```bash
./scripts/create-plan.sh -m <module_name> [-g <short_goal>]
```

## Script Usage: `create-module.sh`
Use the module scaffold script to create the standard module skeleton.

Canonical invocation:
```bash
./scripts/create-module.sh -m <module_name> [-rv <tf_required_version>] [-av <aws_provider_version>]
```

Inputs:
- `-m|--module`: Module name (required). Use kebab-case.
- `-rv|--required-version`: Terraform `required_version` constraint (optional). Defaults are defined in the script.
- `-av|--aws-version`: AWS provider version constraint (optional). Defaults are defined in the script.

Outputs:
- Creates `modules/<module_name>/` with `main.tf`, `variables.tf`, `outputs.tf`, and `versions.tf`.
- Adds TODO placeholders to non-version files to guide initial implementation.

Failure modes:
- Missing `-m|--module` value.
- Unknown or malformed flags.
- Module directory already exists.

## Related Guides
- `03-module-structure-and-layout.md` for file layout and required files.
- `04-module-interfaces-and-arguments.md` for input and output design.
- `07-composition-and-patterns.md` for composition patterns.
