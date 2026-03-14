---
page_title: Module Structure and Repository Layout
description: >-
  Defines the standard repository and module layout, required files, and positioning
  of root modules, nested modules, examples, and supporting directories.
---

# Module Structure and Repository Layout

## Audience
Module implementers and reviewers.

## Purpose
Define the canonical filesystem layout for module repositories and internal module
directories in this repo, including root modules, nested modules, examples, and
supporting scaffolding.

## Standard Layout
The standard module structure is a file and directory layout recommended for reusable
modules. Terraform tooling expects this structure for documentation and module
indexing. The only required element is the root module; everything else is optional
but strongly recommended.

### Root Module (Required)
Terraform files must exist in the root directory of the module. This root module is
the primary entry point and should be opinionated about defaults and behavior.

A typical root module contains at least:
- `main.tf` – primary entry point; child module calls belong here.
- `variables.tf` – variable definitions and validation.
- `outputs.tf` – outputs exposed to callers.
- `versions.tf` – Terraform and provider version requirements (`terraform` and
  `required_providers` blocks).

For detailed interface and variable standards, see
`04-module-interfaces-and-arguments.md`.

### Variables and Outputs
All variables and outputs must include descriptions. See
`04-module-interfaces-and-arguments.md` for full interface rules, including
naming, types, defaults, and validation.

## Child Modules
- Child modules live under `modules/`.
- Any child module with a `README.md` is considered usable by external consumers.
- If the root module calls child modules, use relative paths like
  `./modules/<name>` so Terraform treats them as part of the same package.
- Keep module hierarchies shallow and prefer composition over deep nesting.
  See `07-composition-and-patterns.md` for composition patterns and root module
  design guidance.

## Structure Examples
Minimal structure:
```text
minimal-module/
|-- README.md
|-- main.tf
|-- variables.tf
|-- versions.tf
|-- outputs.tf
```

Complete structure:
```text
|-- modules/
|   |-- child-a/
|   |   |-- README.md
|   |   |-- main.tf
|   |   |-- variables.tf
|   |   |-- versions.tf
|   |   |-- outputs.tf
|   |-- child-b/
|-- examples/
|   |-- example-a/
|   |   |-- variables/
|   |   |   |-- env.tfvars
|   |   |-- backends/
|   |   |   |-- env.tfvars
|   |   |-- main.tf
|   |   |-- variables.tf
|   |   |-- outputs.tf
|   |   |-- README.md
|   |-- example-b/
```

## Supporting Directories

### `Plan/`
Planning documents for new or significantly changed modules live under `Plan/` in the
repository root. Use `scripts/create-plan.sh` to scaffold plans. For planning
requirements and workflow, see `02-module-creation-and-fundamentals.md`.

## Script Overview (Scaffolding and Validation)
This repository provides helper scripts for consistent scaffolding, documentation,
examples, and testing. Detailed usage lives in specialized guides; this section
summarizes where they fit into the structure.

### `root-module.sh`
- Scaffolds root module files (`main.tf`, `variables.tf`, `outputs.tf`,
  `versions.tf`, and `README.md` when present).
- Creates standard module directories and optional example skeletons under
  `examples/` when requested.
- Enforces kebab-case module naming and the repository layout conventions.
- Keeps provider and backend ownership in the root module (no provider blocks in
  child modules).
- Inserts TODO placeholders to guide initial implementation.

For when and why to introduce a new module, see
`02-module-creation-and-fundamentals.md`.

### `test-module.sh`
Purpose: run a consistent validation workflow against module examples.

- Runs `terraform fmt -recursive` across module and example files.
- Runs `terraform init -backend=false` and `terraform validate` per example.
- Runs `tfsec` and `tflint` when installed; skips with warnings if missing.
- Supports selecting example type(s) and optional `terraform plan`.
- Intended for local validation and CI parity.

For detailed testing workflow, CI gates, and failure criteria, see
`09-testing-and-ci.md`.

## Related Guides

- `02-module-creation-and-fundamentals.md`
- `04-module-interfaces-and-arguments.md`
- `07-composition-and-patterns.md`
- `09-testing-and-ci.md`
- `10-examples.md`
