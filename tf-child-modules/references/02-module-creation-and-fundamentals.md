---
page_title: Module Fundamentals and Design Principles
description: Explains what a Terraform module is in this repository, when and why to create one, what belongs inside a module vs in a root module, and the high-level design principles that keep modules cohesive, reusable, and stable over time.
---

# Module Fundamentals and Design Principles

Explain what modules are, when they are warranted, how they relate to root modules and higher-level architecture, and which other guides provide detailed layout, interface, composition, and testing rules.

## What Is a Module

A module is a container for multiple resources that are used together. Modules allow you to describe infrastructure in terms of architecture-level concepts rather than individual resource types.

The `.tf` files in your working directory when you run `terraform plan` or `terraform apply` together form the root module. The root module may call child modules and connect them by passing outputs from one module into inputs of another.

### Root Modules vs Reusable Modules

Root modules:

- Represent a concrete stack or environment.
- Wire together multiple child modules and any remaining resources.
- Configure providers and backends.

Reusable modules:

- Encapsulate a coherent capability (for example, "VPC with subnets" or "ECS service with ALB").
- Expose a stable interface via variables and outputs.
- Avoid hard-coded environment-specific values.

## When to Create a Module

Create a module when it introduces a reusable, higher-level abstraction that is meaningful in your architecture.

Indicators a module is warranted:

- The configuration represents a distinct architectural concept that will be reused.
- The abstraction improves readability and reduces duplication across stacks.
- The module boundary clarifies ownership, inputs, and outputs.
- The module helps reduce complexity by isolating a major component into its own project or directory.

Avoid creating modules that are thin wrappers around a single resource type. If the module name would be identical to the main resource it wraps, it is likely not adding value. Use the resource directly in the calling module instead.

## High-Level Design Principles

Well-designed modules share the following characteristics:

- **Cohesive scope** – each module owns a clear capability and does not mix unrelated concerns.
- **Stable interface** – variable names, types, and outputs change rarely and are documented before implementation.
- **Environment-agnostic** – modules avoid hard-coded account IDs, regions, or environment names and instead accept them as inputs when needed.
- **Secure by default** – defaults favor least privilege, encryption at rest and in transit, and no public exposure.
- **Composable** – modules can be combined at the root module level without hidden dependencies or provider configuration inside the module.

## Composition and Dependency Inversion

Prefer a flat module tree and compose modules at the root module level. Keep dependencies explicit by passing required identifiers and values into modules rather than having modules create their own dependencies. This keeps modules flexible and easier to reuse in different combinations.

## Interface Expectations

- Use clear, typed inputs and outputs.
- Avoid hard-coded values; prefer variables with sensible defaults.
- Expose reusable values via outputs; mark sensitive outputs appropriately.

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

- `aws-knowledge-mcp-server.aws___search_documentation`
- `aws-knowledge-mcp-server.aws___read_documentation`
- `aws-knowledge-mcp-server.aws___recommend`
- `aws-knowledge-mcp-server.aws___list_regions`
- `aws-knowledge-mcp-server.aws___get_regional_availability`

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

- `terraform-mcp-server.SearchAwsProviderDocs`
- `terraform-mcp-server.SearchAwsccProviderDocs`
- `terraform-mcp-server.SearchUserProvidedModule`
- `terraform-mcp-server.SearchUserProvidedModule`
- `terraform-mcp-server.SearchSpecificAwsIaModules`

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
