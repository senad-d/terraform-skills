---
page_title: Terraform Root Module Documentation Overview
description: >-
  Entry point for the Terraform root module documentation set, describing the root module lifecycle, how to navigate the guides, and which document is authoritative for each topic.
---

# Terraform Module Documentation Overview

## Audience

Module authors, reviewers, and tooling maintainers.

## Purpose

This guide is the entry point for the root module documentation set. It explains
how to navigate the guides, outlines the root module lifecycle, and calls out
which documents are authoritative for each topic.

## Scope

Root modules in this repository compose reusable child modules from `modules/`
into concrete stacks. They own provider and backend configuration and expose
stable outputs for downstream stacks.

## Core Principles

- Build higher-level abstractions, not thin wrappers around single resources.
- Keep module hierarchies shallow and compose modules at the root module level.
- Favor secure defaults, least privilege, and encryption at rest and in transit.
- Pin Terraform and provider versions to stable constraints.
- Prefer discoverable, repeatable patterns already used in this repository.
- Use data sources for external or AWS-managed services; use
  `terraform_remote_state` for internal stacks.

## Architecture Focus (Decision Order)

- Account/environment boundaries.
- Network topology and data ownership.
- Compute placement and service selection.
- Observability and telemetry.
- DR strategy and cost management.

Authoritative architecture guidance lives in
`05-infrastructure-architecture-guidelines.md`.

## Module Lifecycle

1. Idea and justification
2. Design and interface definition
3. Scaffold module structure and files
4. Implement resources and logic
5. Validate locally and in CI
6. Release, version, and maintain
7. Refactor or deprecate safely

Lifecycle automation touchpoints:

- Scaffolding: `scripts/root-module.sh`
- Validation: `scripts/test.sh`

## Automation Scripts (Authoritative)

All automation lives in `tf-root-module/scripts/`. Use these scripts instead of
ad-hoc scaffolding or tests.

### `read.sh`

Purpose: read files from a directory (or filtered by pattern) and emit a single
JSON document.

Inputs:

- `-d|--directory`: root directory to read (required)
- `-n|--name-pattern`: `rg` pattern to filter file paths (optional)

Outputs:

- JSON with `root`, `generated_at`, `file_count`, and file contents.

Safety notes:

- Read-only; no changes to the repo.

### `find.sh`

Purpose: list immediate subdirectories as modules and emit a JSON inventory.

Inputs:

- `-d|--directory`: root directory to scan (required)
- `-n|--name-pattern`: `rg` pattern to filter module paths (optional)

Outputs:

- JSON with `root`, `generated_at`, `module_count`, and module file lists.

Safety notes:

- Read-only; no changes to the repo.

### `plan.sh`

Purpose: create a standardized plan document before implementing a root module.

Inputs:

- `-m|--module`: module name (required)
- `-g|--goal`: short goal (optional)

Outputs:

- `Plan/<YYYYMMDD>-<module_slug>.md` with a required template.

Safety notes:

- Writes a new plan file. Do not edit Terraform code before this plan exists.

### `root-module.sh`

Purpose: scaffold root module examples and wiring for existing child modules.

Inputs:

- `-m`: comma-separated child module names (required, must exist in `modules/`)
- `-t`: root module name(s) (required)
- `-n`: stack name (optional; defaults to concatenated module names)
- `-e`: examples root (default `examples`)
- `-r`: modules root (default `modules`)
- `-T`: Terraform required version
- `-P`: AWS provider version
- `-f`: overwrite existing example (dangerous)

Outputs:

- Example scaffolding under `examples/<module_name>/<root_name>/` with
  `main.tf`, `locals.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `README.md`.

Safety notes:

- Never creates AWS resources. It only writes files.
- Fails fast if referenced child modules do not exist.

### `test.sh`

Purpose: validate examples consistently and generate a Markdown-style report.

Inputs:

- `-m|--module`: module name (required)
- `-t|--type`: example type(s) (optional; defaults to `basic`)
- `-p|--plan`: `true` or `false` for `terraform plan` (optional; default `true`)

Behavior:

- Runs `terraform fmt -recursive`.
- Runs `terraform init -backend=false` and `terraform validate` per example.
- Runs `tfsec` and `tflint` when installed.
- Runs `terraform plan` unless disabled.

Safety notes:

- Uses `AWS_PROFILE=localstack` by default.
- Do not use for real AWS changes; it is validation-only.

### `cleanup.sh`

Purpose: remove Terraform artifacts (`.terraform/`, `.terraform.lock.hcl`) under
a directory tree.

Inputs:

- `--dry-run`, `--log-level`, `--debug`, `--quiet`, plus a `MAIN_DIR` and
  optional subdirectories.

Outputs:

- Deletes Terraform artifacts; supports dry-run reporting.

Safety notes:

- Destructive by design; use `--dry-run` first.
- Skips common vendor/build directories while scanning.

## Checklists and Quality Gates (Pointers)

- Architecture and guardrails: `05-infrastructure-architecture-guidelines.md`
- Security, naming, and tagging: `08-security-naming-and-tagging.md`
- Testing and CI gates: `09-testing-and-ci.md`

## Documentation Map

- `02-module-creation-and-fundamentals.md` — when and why to create root modules.
- `03-module-structure-and-layout.md` — required layout and structure.
- `04-module-interfaces-and-arguments.md` — variables, validation, outputs.
- `05-infrastructure-architecture-guidelines.md` — architecture baseline.
- `06-sources-and-distribution.md` — sources, versioning, upgrades.
- `07-composition-and-patterns.md` — composition patterns and dependency wiring.
- `08-security-naming-and-tagging.md` — security baseline, naming, and tags.
- `09-testing-and-ci.md` — validation workflow and CI requirements.
- `10-examples.md` — example design and documentation expectations.

## Sources of Truth

Each guide is authoritative for its topic. Avoid duplicating guidance across
files; link to the correct guide instead.
