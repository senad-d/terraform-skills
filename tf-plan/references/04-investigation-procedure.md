---
page_title: Investigation Procedure
description: Research the topic using scripts and MCP servers to obtain authoritative information about Terraform and AWS resources.
---

# Investigation Procedure

<!-- TODO: -->

## Confirm Scope

<!-- TODO: -->

## Build a Resource Inventory

<!-- TODO: -->

### Resource Inventory Format

Capture the inventory in this format (or equivalent):

```markdown
**Resources:** aws_*, random_*, null_*, etc.
**Data sources:** data.aws_*, etc.
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

- DO NOT guess resource behavior.
- DO NOT proceed if the scope is unclear.
