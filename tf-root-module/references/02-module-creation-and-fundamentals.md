---
page_title: Root Module Fundamentals and Design Principles
description: >-
  Explains what a Terraform root module is in this repository, when to create a
  new root module versus reusing an existing one, what belongs inside a root
  module, and the high-level design principles for composing existing reusable
  modules into concrete stacks.
---

# Root Module Fundamentals and Design Principles

## Audience
Engineers creating or evolving Terraform root modules that compose existing 
standardized child modules into concrete stacks or environments.

## Purpose
Explain what root modules are in this repository, when a new root module is 
warranted versus reusing or extending an existing one, how root modules relate 
to reusable child modules, and which other guides provide detailed layout, 
interface, composition, and testing rules.

## What is a root module
A Terraform module is a container for multiple resources that are used together. 
Modules allow you to describe infrastructure in terms of architecture-level concepts 
rather than individual resource types.

In Terraform, the `.tf` files in your working directory when you run 
`terraform plan` or `terraform apply` together form the root module.

In this repository, a root module:
- Represents a concrete stack or environment 
(for example, a production application deployment in a multiple account and regions).
- Wires together multiple reusable child modules and any remaining glue resources.
- Configures providers and backends for that stack 
(see `05-providers-state-and-backends.md`).
- Supplies environment, and account-specific values to child modules.
- Exposes any outputs that other stacks or automation need.

### Root Modules (stack) vs Reusable Modules (child)
Root modules:
- Represent a concrete stack or environment.
- Wire together multiple child modules and any remaining resources.
- Configure providers and backends.

Reusable modules:
- Encapsulate a coherent capability (for example, "VPC with subnets" or
  "ECS service with ALB").
- Expose a stable interface via variables and outputs.
- Avoid hard-coded environment-specific values.

For file layout and where root modules, nested modules, and examples live in this
repository, see `03-module-structure-and-layout.md`.

## When to create a root module
Create a root module when you need a new, concrete stack that has its own lifecycle, ownership, or blast radius.

Prefer reusing or extending an existing root module instead of creating a new one when:
- The new requirement is a small variation on an existing stack that can be handled via additional variables, feature flags, or configuration files (for example, different instance sizes or capacity, but same topology).
- Multiple stacks share the same structure and differ only by values; use variables and `*.tfvars` files rather than cloning the root module directory.
- You only need to add or swap child modules within an existing stack without changing its lifecycle or ownership.

Avoid creating root modules that are thin wrappers around a single reusable child module unless:
- The wrapper encodes important stack-level policy (for example, required tagging, logging, or monitoring) and will be the canonical entry point for consumers.

Otherwise, consume the reusable module directly from the existing root modules.

## High-Level Design Principles
Well-designed modules share the following characteristics:

- **Cohesive scope** – each module owns a clear capability and does not mix unrelated
  concerns.
- **Stable interface** – variable names, types, and outputs change rarely and are
  documented before implementation.
- **Environment-agnostic** – modules avoid hard-coded account IDs, regions, or
  environment names and instead accept them as inputs when needed.
- **Secure by default** – defaults favor least privilege, encryption at rest and in
  transit, and no public exposure.
- **Composable** – modules can be combined at the root module level without hidden
  dependencies or provider configuration inside the module.

Interface and variable standards that apply to root modules are defined in `04-module-interfaces-and-arguments.md`.

## Composition and Dependency Inversion
Prefer a flat module tree and compose modules at the root module level. Keep
dependencies explicit by passing required identifiers and values into modules rather
than having modules create their own dependencies. This keeps modules flexible and
easier to reuse in different combinations.

For composition patterns, data-only modules, and root module responsibilities, see
`07-composition-and-patterns.md`.

## Interface Expectations
- Use clear, typed inputs and outputs.
- Avoid hard-coded values; prefer variables with sensible defaults.
- Expose reusable values via outputs; mark sensitive outputs appropriately.

Detailed interface, variable, and validation rules live in
`04-module-interfaces-and-arguments.md`.

## Development Best Practices
- Prefer internal modules under `modules/` over re-implementing resources directly.
- Use `locals` for repeated values to keep configurations consistent.
- Review inputs and outputs before implementation to avoid later refactors.
- Enable telemetry or logging features when available and appropriate.

## MCP Documentation Workflow (Required)
When planning a new root module, use MCP documentation tools as the primary sources of
truth. This avoids stale assumptions and keeps module behavior aligned with provider
and service capabilities.

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
3. If unsure about feature availability, check regions with `list_regions` and
   `get_regional_availability`.
4. Use `recommend` to discover related or newly added documentation pages.

Example search phrases:
```text
"S3 bucket encryption configuration"
"Lambda environment variables limits"
"RDS parameter group constraints"
```

### Terraform Documentation Tools
Use the Terraform MCP server to confirm provider resources, arguments, and schema
details.

Available tools:
- `mcp__terraform-mcp-server__SearchAwsProviderDocs`
- `mcp__terraform-mcp-server__SearchAwsccProviderDocs`
- `mcp__terraform-mcp-server__SearchUserProvidedModule`
- `mcp__terraform-mcp-server__SearchSpecificAwsIaModules`

Recommended usage:
1. Use `SearchAwsProviderDocs` to confirm resource arguments, attributes, and
   examples for the AWS provider.
2. Use `SearchAwsccProviderDocs` when working with AWS Cloud Control (AWSCC)
   resources.
3. Use `SearchUserProvidedModule` to review upstream modules before re-implementing
   similar functionality.
4. Use `SearchSpecificAwsIaModules` when exploring AWS-IA reference modules for
   patterns and defaults.

Example search inputs:
```text
asset_name = "aws_s3_bucket"
asset_name = "aws_lambda_function"
module_url = "terraform-aws-modules/vpc/aws"
```

### Planning Expectations
- Capture findings from AWS and Terraform docs in your planning notes.
- If documentation is ambiguous, prefer the most conservative, secure defaults.
- Do not proceed with implementation until documentation sources confirm the
  required behavior.

## Planning Requirements (Production Modules)
Before implementing a new root module, document the following in a short plan:
- Module goal, scope boundaries, and non-goals.
- Primary AWS services, child modules, and Terraform resources involved (validated via MCP docs).
- Expected inputs and outputs, including sensitive fields.
- Security defaults and any required exceptions.
- Example scenario(s) and supporting modules required.

## Script Usage: `plan.sh`
Use the plan scaffolding script to create a standardized planning document before
implementing a new module.

Canonical invocation:
```bash
./scripts/plan.sh -m <module_name> [-g <short_goal>]
```

Inputs:
- `-m|--module`: Module name (required). Use kebab-case. Used to derive the plan
  filename and populate placeholders.
- `-g|--goal`: Short, human-readable goal for the module (optional but recommended).
  Included in the Summary section of the plan.

Outputs:
- Creates a `Plan/` directory in the repository root if it does not already exist.
- Generates `Plan/<YYYYMMDD>-<module_slug>.md`, where `module_slug` is a sanitized
  form of `<module_name>`.
- Populates the file with a structured template that includes:
  - Summary section with module and goal checkboxes.
  - Investigation Notes for AWS and Terraform documentation, and any upstream
    modules.
  - Interface Contract tables for inputs and outputs.
  - Security Defaults and Exceptions checklist.
  - Implementation Plan checklist (scaffolding, examples, docs, validation).
  - Example usage notes.
  - Validation, Cleanup, Documentation, Risks/Rollback, and Investigation
    information sections.

Failure modes:
- Missing `-m|--module` value.
- Unknown or malformed flags.
- Filesystem errors when creating the `Plan/` directory or writing the plan file.

## Where to go next
- `03-module-structure-and-layout.md` for file layout and required files.
- `04-module-interfaces-and-arguments.md` for input, output, and validation design.
- `07-composition-and-patterns.md` for composition patterns and root module design.
