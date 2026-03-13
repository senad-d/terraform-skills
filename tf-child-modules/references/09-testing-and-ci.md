---
page_title: Testing, Examples, and CI Automation
description: >-
  Canonical guide for validating modules locally, using examples as test
  inputs, running the test-module script, and defining required tests and
  checks in CI.
---

# Testing, Examples, and CI Automation

## Audience
Module authors, reviewers, and pipeline maintainers.

## Purpose
Define the minimum testing bar, how examples are used as test inputs, the local
validation workflow, and CI gates for modules and examples.

## Role of Examples in Testing
Examples under `examples/` serve two purposes:
- **Documentation** – they show realistic, secure usage of a module.
- **Test assets** – they provide concrete configurations that can be validated
  locally and in CI.

Examples should:
- Cover common and security-sensitive scenarios.
- Use repository-standard patterns for providers, backends, and security
  defaults.
- Stay in sync with module interfaces and versioning.

For how to design examples, organize directories, and generate READMEs, see
`10-examples-and-docs-automation.md`.

## Local Validation Workflow
At minimum, local validation should include:
- `terraform fmt -recursive`
- `terraform init -backend=false` in examples
- `terraform validate` in examples
- Security and lint scans (tfsec, tflint) when available

When localstack or other emulation tools do not support a resource, use:
- `terraform init -backend=false`
- `terraform validate`

Run these checks before opening a PR or updating module versions.

## CI Expectations
CI must fail on:
- Formatting issues.
- Validation errors.
- High-severity security findings.

Typical CI steps:
- `terraform fmt -recursive`.
- `terraform validate` on examples.
- Security scans (`tfsec`, `checkov`, `trivy` as applicable).
- Linting (`tflint`).
- Optional `terraform plan` on selected examples for additional safety.

Security scan coverage and tagging conventions are defined in
`08-security-naming-and-tagging.md`.

## Script Usage: `test.sh`
Use the test script to validate module examples consistently.

Canonical invocation:
```bash
./scripts/test.sh -m <module_name> [-t <example_type> ...] [--plan <true|false>]
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

Use this script locally and in CI wherever possible to keep validation
consistent across modules.

## Runtime-Specific Test Assets
For certain resource types, examples may need minimal runtime code to validate
wiring. Standard defaults live in `10-examples-and-docs-automation.md` and
should be reused instead of ad-hoc snippets.

Examples include:
- Lambda functions (Node.js handler).
- EC2 instances (Nginx user data to expose instance IP).
- Other runtimes and services listed in the additional runtime templates.

Reusing these defaults keeps examples predictable and avoids security drift.

## Related Guides
- `10-examples-and-docs-automation.md` for example design and documentation
  automation.
- `03-module-structure-and-layout.md` for where examples live in the
  repository.
- `08-security-naming-and-tagging.md` for security requirements and scan
  expectations.
