---
page_title: Investigation Procedure
description: Investigate Terraform modules using the scripts and MCP servers to gather authoritative information about Terraform and AWS resources.
---

# Investigation Procedure

Provide a strict, repeatable process for locating relevant files, reading them
via scripts, and collecting authoritative reference data about
Terraform and AWS resources using MCP servers.

## Confirm Scope

- Record the exact module path and the expected module type (child or root).
- Capture any stated non-goals or exclusions before scanning.
- DO NOT proceed if the module target is ambiguous.

## Locate the code for review

Use the automation [find_script](./scripts/find.sh) to find module directories.

```bash
./scripts/find.sh -d <directory> [-n <name-pattern>]
```

Rules:

- Use `-n` to reduce noise and match the module name or prefix.
- If multiple candidates match, list each path and ask for confirmation.
- DO NOT assume the correct module based on filename alone.

## Read Files

Read files to build the evidence set using [read_script](./scripts/read.sh).

```bash
./scripts/read.sh -d <directory> [-n <name-pattern>]
```

Rules:

- Include connected directories if they exist.
- Use `-n` to focus on specific file types when necessary.
- Treat output from `./scripts/read.sh` as the source of truth for the review.

## Build a Resource Inventory

- Identify all resources, data sources, modules, and providers used.
- Record each resource type and where it is defined.
- Note external dependencies and cross-module references.
- Track any hard-coded identifiers (regions, ARNs, account IDs).

### Resource Inventory Format

Capture the inventory in this format (or equivalent):

```markdown
**Resources:** aws_*, random_*, null_*, etc.
**Data sources:** data.aws_*, etc.
**Modules:** module.<name> (source and path)
**Providers:** aws, random, etc. (version constraints)
**External dependencies:** remote modules, shared state, data lookups
```

## Gather MCP References

Use MCP servers to confirm expected configuration, limits, and security
defaults for each resource type.

### AWS Knowledge MCP

- Use for AWS service behavior, security baselines, and feature constraints.
- Confirm encryption support, logging, network exposure, and IAM defaults.
- Prefer authoritative AWS documentation over secondary sources.

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

### Terraform MCP

- Use for provider arguments, schema requirements, and resource behavior.
- Confirm required vs optional arguments and defaults.
- Validate lifecycle behavior and drift expectations.

Rules:

- DO NOT recommend a change without confirming it in MCP references.
- Record the reference source and the exact behavior it supports.
- If references conflict, document the discrepancy and request confirmation.

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

## Evidence Log Requirements

- For every finding, capture file path + line references or tool output.
- Attach MCP reference summaries for any recommended change.
- Mark unverified items as hypotheses and seek confirmation.

### Evidence Log Expectations

The evidence log must include:

- File path and line references for each finding.
- Plan output or tool output when available.
- MCP reference summary used to justify the change.
- Any assumptions or gaps requiring confirmation.

## Output Expectations

- A file inventory with module paths.
- A resource inventory with locations.
- Evidence notes ready to be used in findings.
- A list of references used to justify recommendations.

## DO NOT DO

- DO NOT skip `find_script` and `read_script` in favor of manual browsing.
- DO NOT guess resource behavior.
- DO NOT rely on README claims if code contradicts them.
- DO NOT proceed if the module scope is unclear.
