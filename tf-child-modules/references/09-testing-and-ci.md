---
page_title: Testing, Examples, and CI Automation
description: Canonical guide for validating modules locally, using examples as test inputs, running the test-module script, and defining required tests and checks in CI.
---

# Testing, Examples, and CI Automation

Define the minimum testing bar, how examples are used as test inputs, the local validation workflow, and CI gates for modules and examples.

## Role of Examples in Testing

Examples under `examples/` serve two purposes:

- **Documentation** – they show realistic, secure usage of a module.
- **Test assets** – they provide concrete configurations that can be validated locally and in CI.

Examples should:

- Cover common and security-sensitive scenarios.
- Use repository-standard patterns for providers, backends, and security defaults.
- Stay in sync with module interfaces and versioning.

## Local Validation Workflow

At minimum, local validation should include:

- `terraform fmt -recursive`
- `terraform init -backend=false` in examples
- `terraform validate` in examples
- Security and lint scans (tfsec, tflint) when available

When localstack or other emulation tools do not support a resource, use:

- `terraform init -backend=false`
- `terraform validate`

Run these checks before updateing.

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

## Runtime-Specific Test Assets

For certain resource types, examples may need minimal runtime code to validate
wiring.

Examples include:

- Lambda functions (Node.js handler).
- EC2 instances (Nginx user data to expose instance IP).
- Other runtimes and services listed in the additional runtime templates.

Reusing these defaults keeps examples predictable and avoids security drift.
