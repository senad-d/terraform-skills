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

## What Is a Root Module

A Terraform module is a container for multiple resources used together. Modules
let you describe infrastructure in terms of architecture-level concepts rather
than individual resource types.

In Terraform, the `.tf` files in your working directory when you run
`terraform plan` or `terraform apply` together form the root module.

### Root Modules (Stack) vs Reusable Modules (Child)

Root modules:

- Represent a concrete stack or environment.
- Wire together multiple child modules and any remaining resources.
- Configure providers and backends.

Reusable modules:

- Encapsulate a coherent capability (for example, "VPC with subnets" or
  "ECS service with ALB").
- Expose a stable interface via variables and outputs.
- Avoid hard-coded environment-specific values.

For file layout and where root modules, nested modules, and examples live in
this repository, see `03-module-structure-and-layout.md`.

## When to Create a Root Module

Create a root module when you need a new, concrete stack that has its own
lifecycle, ownership, or blast radius.

- The stack has a distinct lifecycle, release cadence, or operational owner.
- The blast radius or failure domain must be isolated from existing stacks.
- The environment boundary is different (new account, region, or env tier).
- Compliance or security posture differs (data residency, stricter controls).
- The stack introduces a new shared platform capability with clear consumers.
- Do not create a new root module if only inputs/outputs change; extend the
  existing module instead.

## Decision Flow (Root vs Extend)

1. Does a root module already exist for this stack or capability?
2. If yes, can the change be handled with new inputs/outputs or examples?
3. Would extending it introduce breaking changes for current consumers?
4. Is the lifecycle, ownership, or blast radius meaningfully different?
5. Are account/region or compliance boundaries distinct from existing stacks?
6. If most answers are yes, create a new root module; otherwise extend.

## High-Level Design Principles

Well-designed modules share the following characteristics:

- **Cohesive scope**: each module owns a clear capability and does not mix
  unrelated concerns.
- **Stable interface**: variable names, types, and outputs change rarely and are
  documented before implementation.
- **Environment-agnostic**: modules avoid hard-coded account IDs, regions, or
  environment names and instead accept them as inputs when needed.
- **Secure by default**: defaults favor least privilege, encryption at rest and
  in transit, and no public exposure.
- **Composable**: modules can be combined at the root module level without
  hidden dependencies or provider configuration inside the module.

Interface and variable standards are defined in
`04-module-interfaces-and-arguments.md`.

## Child Module Selection Workflow

1. Search `modules/` for an existing capability before adding resources.
2. Read each candidate module README to confirm scope and interface.
3. Prefer internal modules; avoid raw resources unless no module exists.
4. Validate required behavior with MCP docs when capabilities are unclear.
5. If no module exists, document the gap and propose a new module name/scope.

## Org Guardrails Apply (Always)

Root modules must follow the organization architecture and security guardrails:

- Architecture baseline: `05-infrastructure-architecture-guidelines.md`
- Security, naming, tagging: `08-security-naming-and-tagging.md`

## MCP Documentation Workflow (Required)

When planning a new root module, use MCP documentation tools as the primary
sources of truth. This avoids stale assumptions and keeps module behavior
aligned with provider and service capabilities.

### AWS Documentation Tools

Use the AWS documentation MCP server for service behavior, limits, and best
practices.

Available tools:

- `aws-knowledge-mcp-server.aws___search_documentation`
- `aws-knowledge-mcp-server.aws___read_documentation`
- `aws-knowledge-mcp-server.aws___recommend`
- `aws-knowledge-mcp-server.aws___list_regions`
- `aws-knowledge-mcp-server.aws___get_regional_availability`

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

Use the Terraform MCP server to confirm provider resources, arguments, and
schema details.

Available tools:

- `terraform-mcp-server.SearchAwsProviderDocs`
- `terraform-mcp-server.SearchAwsccProviderDocs`
- `terraform-mcp-server.SearchUserProvidedModule`
- `terraform-mcp-server.SearchUserProvidedModule`
- `terraform-mcp-server.SearchSpecificAwsIaModules`

Recommended usage:

1. Use `SearchAwsProviderDocs` to confirm resource arguments, attributes, and
   examples for the AWS provider.
2. Use `SearchAwsccProviderDocs` when working with AWS Cloud Control (AWSCC)
   resources.
3. Use `SearchUserProvidedModule` to review upstream modules before re-
   implementing similar functionality.
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
- Primary AWS services, child modules, and Terraform resources involved
  (validated via MCP docs).
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
- `-g|--goal`: Short, human-readable goal for the module (optional but
  recommended). Included in the Summary section of the plan.

Outputs:

- Creates a `Plan/` directory in the repository root if it does not already
  exist.
- Generates `Plan/<YYYYMMDD>-<module_slug>.md`, where `module_slug` is a
  sanitized form of `<module_name>`.
- Populates the file with a structured template.

Failure modes:

- Missing `-m|--module` value.
- Unknown or malformed flags.
- Filesystem errors when creating the `Plan/` directory or writing the plan
  file.

## Related Guides

- `01-overview-and-lifecycle.md` — documentation map and lifecycle overview.
- `03-module-structure-and-layout.md` — required layout and structure.
- `04-module-interfaces-and-arguments.md` — variables, validation, outputs.
- `05-infrastructure-architecture-guidelines.md` — architecture baseline.
- `06-sources-and-distribution.md` — versioning and upgrade guidance.
- `07-composition-and-patterns.md` — composition patterns and dependency wiring.
- `08-security-naming-and-tagging.md` — security and tagging baseline.
- `09-testing-and-ci.md` — validation workflow and CI gates.
- `10-examples.md` — examples and documentation expectations.
