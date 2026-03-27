---
page_title: Investigation Procedure
description: >-
  How to investigate Terraform modules using the automation scripts and MCP
  servers to gather authoritative information about Terraform and AWS resources.
---

# Investigation Procedure

## Audience

Module reviewers, authors, and tooling maintainers.

## Purpose

Provide a strict, repeatable process for locating relevant files, reading them
via automation scripts, and collecting authoritative reference data about
Terraform and AWS resources using MCP servers.

## Required Inputs

- Root directory of the Terraform repository.
- Module or stack name under review.
- Review goal or change context (new module, update, incident response).

## Investigation Workflow

1. Confirm scope and module name.
2. Locate candidate module directories.
3. Read module files with the automation scripts.
4. Build a resource inventory from the code.
5. Gather authoritative references with MCP servers.
6. Record evidence and cite sources.

## Step 1: Confirm Scope

- Record the exact module path and the expected module type (child or root).
- Capture any stated non-goals or exclusions before scanning.
- DO NOT proceed if the module target is ambiguous.

## Step 2: Locate Modules with `find.sh`

Use the automation script to find module directories.

```bash
"$FIND" -d <repository_root> [-n <name-pattern>]
```

Rules:

- Use `-n` to reduce noise and match the module name or prefix.
- If multiple candidates match, list each path and ask for confirmation.
- DO NOT assume the correct module based on filename alone.

## Step 3: Read Files with `read.sh`

Read the module files to build the evidence set.

```bash
"$READ" -d <module_path> [-n <name-pattern>]
```

Rules:

- Start with `main.tf`, `variables.tf`, `outputs.tf`, `locals.tf`,
  `versions.tf`, and `README.md`.
- Include example directories if they exist.
- Use `-n` to focus on specific file types when necessary.
- Treat output from `read.sh` as the source of truth for the review.

## Step 4: Build a Resource Inventory

- Identify all resources, data sources, modules, and providers used.
- Record each resource type and where it is defined.
- Note external dependencies and cross-module references.
- Track any hard-coded identifiers (regions, ARNs, account IDs).

## Step 5: Gather MCP References

Use MCP servers to confirm expected configuration, limits, and security
defaults for each resource type.

### AWS Knowledge MCP

- Use for AWS service behavior, security baselines, and feature constraints.
- Confirm encryption support, logging, network exposure, and IAM defaults.
- Prefer authoritative AWS documentation over secondary sources.

### Terraform MCP

- Use for provider arguments, schema requirements, and resource behavior.
- Confirm required vs optional arguments and defaults.
- Validate lifecycle behavior and drift expectations.

Rules:

- DO NOT recommend a change without confirming it in MCP references.
- Record the reference source and the exact behavior it supports.
- If references conflict, document the discrepancy and request confirmation.

## Step 6: Evidence Log Requirements

- For every finding, capture file path + line references or tool output.
- Attach MCP reference summaries for any recommended change.
- Mark unverified items as hypotheses and seek confirmation.

## Output Expectations

- A file inventory with module paths.
- A resource inventory with locations.
- Evidence notes ready to be used in findings.
- A list of references used to justify recommendations.

## DO NOT DO

- DO NOT skip `find.sh` and `read.sh` in favor of manual browsing.
- DO NOT guess resource behavior without MCP confirmation.
- DO NOT rely on README claims if code contradicts them.
- DO NOT proceed if the module scope is unclear.
