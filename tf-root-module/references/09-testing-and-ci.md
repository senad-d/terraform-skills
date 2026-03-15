---
page_title: Testing, Examples, and CI Automation
description: >-
  Canonical guide for validating modules locally, using examples as test
  inputs, running the test script, and defining required tests and checks
  in CI.
---

# Testing, Examples, and CI Automation

## Audience

Module authors, reviewers, and pipeline maintainers.

## Purpose

Define the minimum testing bar, how examples are used as test inputs, the local
validation workflow, and CI gates for modules and examples.

## Role of Examples in Testing

Examples under `examples/` serve two purposes:

- **Documentation** — they show realistic, secure usage of a module.
- **Test assets** — they provide concrete configurations that can be validated
  locally and in CI.

For how to design examples, organize directories, and generate READMEs, see
`10-examples.md`.

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

Security baseline and tagging conventions are defined in
`08-security-naming-and-tagging.md`.

## Script Usage: `test.sh`

Use the test script to validate modules and their examples consistently.

Canonical invocation:

```bash
./tf-root-module/scripts/test.sh -m <module_directory> [--plan <true|false>]
```

Inputs:

- `-m|--module`: Module directory to test (required), relative to the repo root, for example `networking` or `private-network`.
- `-p|--plan`: `true` or `false` to enable or disable `terraform plan` (defaults to `true`).

Behavior:

- Runs `terraform fmt -recursive` from the repository root.
- Runs `terraform init -backend=false` and `terraform validate -no-color` in the specified module directory.
- Runs `tfsec` and `tflint` once in the module directory if installed, otherwise skips each with a warning.
- Runs `terraform plan -input=false -refresh=false -lock=false` in the module directory unless `--plan=false`.

Failure modes:

- Missing `-m|--module` argument.
- Module directory path does not exist.
- Invalid `--plan` value (anything other than `true` or `false`).

Use this script locally and in CI wherever possible to keep validation
consistent across modules.

## Runtime-Specific Test Assets

For certain resource types, examples may need minimal runtime code to validate
wiring. Standard defaults live in `10-examples.md` and should be reused instead
of ad-hoc snippets.

Examples include:

- Lambda functions (Node.js handler).
- EC2 instances (Nginx user data to expose instance IP).
- Other runtimes and services listed in the additional runtime templates.

Reusing these defaults keeps examples predictable and avoids security drift.

## Related Guides

- `01-overview-and-lifecycle.md` — documentation map and lifecycle overview.
- `02-module-creation-and-fundamentals.md` — when to create vs extend modules.
- `03-module-structure-and-layout.md` — required layout and structure.
- `04-module-interfaces-and-arguments.md` — variables, validation, outputs.
- `05-infrastructure-architecture-guidelines.md` — architecture baseline.
- `06-sources-and-distribution.md` — versioning and upgrade guidance.
- `07-composition-and-patterns.md` — composition patterns and dependency wiring.
- `08-security-naming-and-tagging.md` — security and tagging baseline.
- `10-examples.md` — examples and documentation expectations.
