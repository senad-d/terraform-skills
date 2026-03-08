---
page_title: Testing and Continuous Integration for Modules
description: >-
  Defines how to validate modules locally, how to use the test-module script, and what tests and checks must run in CI.
---

# Testing and Continuous Integration for Modules

## Audience
Module authors and pipeline maintainers.

## Purpose
Define the minimum testing bar, local validation workflow, and CI gates for modules and examples.

## Local Validation Workflow
At minimum, local validation should include:
- `terraform fmt -recursive`
- `terraform init -backend=false` in examples
- `terraform validate` in examples
- Security and lint scans (tfsec, tflint) when available

When localstack does not support a resource, use:
- `terraform init -backend=false`
- `terraform validate`

## CI Expectations
CI must fail on:
- Formatting issues
- Validation errors
- High-severity security findings

CI should include:
- `terraform fmt -recursive`
- `terraform validate` on examples
- Security scans (`tfsec`, `checkov`, `trivy` as applicable)
- Linting (`tflint`)

## Script Usage: `test-module.sh`
Use the test script to validate module examples consistently.

Canonical invocation:
```bash
./scripts/test-module.sh -m <module_name> [-t <example_type> ...] [--plan <true|false>]
```

Inputs:
- `-m|--module`: Module name (required).
- `-t|--type`: Example type(s). Defaults to `basic` if none are provided.
- `-p|--plan`: `true` or `false` to enable or disable `terraform plan`.

Behavior:
- Runs `terraform fmt -recursive`.
- Runs `terraform init -backend=false` and `terraform validate` per example.
- Runs `tfsec` and `tflint` if installed, otherwise skips with a warning.
- Runs `terraform plan` unless `--plan=false`.

Failure modes:
- Missing module name.
- Missing example directories for requested example types.

## Runtime-Specific Test Assets
For Lambda modules, use the canonical Node.js handler when example code is required and no custom runtime code is provided. For EC2 examples, use the standard Nginx user data snippet to display the instance local IP. Both are documented in `10-examples-and-docs-automation.md`.

## Related Guides
- `10-examples-and-docs-automation.md` for example creation and documentation automation.
- `08-security-naming-and-tagging.md` for security requirements.

