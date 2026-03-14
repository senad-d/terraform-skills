# System Patterns

This repository is organized around reusable CODEX skills and scripts that enforce Terraform AWS module conventions.

## Module Structure

- Each skill lives in its own directory with `SKILL.md`, `scripts/`, and optional `references/`.
- The memory bank lives in `memory-bank/` and captures project context.
- Terraform modules created by these skills are expected to follow `terraform-aws-modules` conventions (root module with `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, plus `examples/` and tests where applicable).

## Naming and Tagging

- Module and directory names use lowercase and hyphenated identifiers.
- Terraform variables use `snake_case`; outputs mirror variable naming.
- Tag inputs are provided as a `map(string)` and merged consistently across resources.

## Validation

- Terraform variable types and validation blocks are required for critical inputs.
- Linting and security checks are expected via `tflint` and `tfsec` when testing modules.
- Scripts should fail fast on missing inputs or invalid structure.

## Composition

- Root modules remain self-contained and are composed via examples and consuming stacks.
- Examples serve as canonical integration patterns for composed deployments.

## Versioning

- Use semantic versioning for module releases.
- Pin provider versions in `required_providers` and set `required_version` for Terraform.
