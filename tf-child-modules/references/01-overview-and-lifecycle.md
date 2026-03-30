---
page_title: Terraform Module Documentation Overview
description: Entry point for the Terraform module documentation set, describing the module lifecycle, how to navigate the guides, and which document is authoritative for each topic.
---

# Terraform Module Documentation Overview

This guide is the entry point for the module documentation set. It explains how to navigate the guides, outlines the module lifecycle, and calls out which documents are authoritative for each topic.

## Core Principles

- Use modules to create reusable, higher-level abstractions rather than thin wrappers around single resources.
- Keep module hierarchies shallow and compose modules at the root module level.
- Favor secure defaults, least privilege, and encryption at rest and in transit.
- Pin Terraform and provider versions to stable constraints.
- Prefer discoverable, repeatable patterns already used in this repository.
- For external or AWS-managed resources, use data sources; for internal stacks, use `terraform_remote_state`.

## Module Lifecycle

1. Idea and justification
2. Design and interface definition
3. Scaffold module structure and files
4. Implement resources and logic
5. Validate locally and in CI
6. Document inputs, outputs, and examples
7. Release, version, and maintain
8. Refactor or deprecate safely

Lifecycle automation touchpoints:

- Scaffolding: [child_script](./scripts/child-module.sh)
- Examples: [root_script](./scripts/root-module.sh)
- Validation: [test_script](./scripts/test.sh)
- Cleanup: [clean_script](./scripts/cleanup.sh)
- Documentation: [document_script](./scripts/document.sh) and `terraform-docs`

## Automation Scripts (Authoritative)

All automation lives in [scripts](./scripts) directory. Use these scripts instead of
ad-hoc scaffolding or tests.

### `read.sh`

Purpose: read files from a directory (or filtered by pattern) and emit a single JSON document.

Inputs:

- `-d|--directory`: root directory to read (required)
- `-n|--name-pattern`: `rg` pattern to filter file paths (optional)

Outputs:

- JSON with `root`, `generated_at`, `file_count`, and file contents.

Safety notes:

- Read-only; no changes to the repo.

### `plan.sh`

Purpose: create a standardized plan document before implementing a root module.

Inputs:

- `-m|--module`: Module name (required). Use kebab-case. Used to derive the plan
  filename and populate placeholders.
- `-g|--goal`: Short, human-readable goal for the module (optional but
  recommended). Included in the Summary section of the plan.

Outputs:

- Creates a `Plan/` directory in the repository root if it does not already exist.
- Generates `Plan/<YYYYMMDD>-<module_slug>.md`, where `module_slug` is a sanitized form of `<module_name>`.
- Populates the file with a structured template.

Failure modes:

- Missing `-m|--module` value.
- Unknown or malformed flags.
- Filesystem errors when creating the `Plan/` directory or writing the plan file.

### `child-module.sh`

Purpose: scaffold a new child module directory with baseline Terraform files.

Inputs:

- `-m|--module`: module name (required). Used for directory name and TODO text.
- `-rv|--required-version`: Terraform required version constraint (optional; default `>= 1.14.3`).
- `-av|--aws-version`: AWS provider version constraint (optional; default `>= 6.14.1`).
- `-h|--help`: show usage and exit.

Outputs:

- Creates `modules/<module_name>/` containing `main.tf`, `outputs.tf`, `variables.tf`, `versions.tf`.
- Writes TODO placeholders in `main.tf`, `outputs.tf`, and `variables.tf`.
- Prints `Created modules/<module_name>` on success.
- If module already exists, prints a skip message and exits without changes.

Failure modes:

- Missing `-m|--module` value.
- Missing value for `-rv|--required-version` or `-av|--aws-version`.
- Unknown or malformed flags.
- Filesystem errors when creating the module directory or writing files.

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

### `document.sh`

Purpose: create a README template for a specific child module.

Inputs:

- `-m|--module`: module name (required; must exist under `modules/`)
- `-h|--help`: show usage and exit

Outputs:

- Overwrites `modules/<module_name>/README.md` with a documentation template.
- Prints a confirmation message with the README path.

Failure modes:

- Missing `-m|--module` value.
- Unknown flags.
- `terraform-docs` missing from `PATH`.
- Module directory does not exist.
- Filesystem errors when writing the README.

Once the files are created, update them according to the following rules:

- Read the module `.tf` files to understand module purpes and features.
- Read the new README.md file for child module.
- Update sections containing `<!-- TODO: ... -->` with clear and concise documentation based on the requirements from that comment.
- Title must use capital letters when appropriate. (e.g. Athena Module, API-Gateway Module...)
- After the editing is done, run the `terraform-docs` command to compleate the file:
   ```bash
   terraform-docs markdown table modules/<module_name> >> modules/<module_name>/README.md
   ```

## Production Readiness Checklist

- Module purpose and abstraction are clear and not a thin wrapper (`02-module-creation-and-fundamentals.md`).
- Standard layout and required files exist (`03-module-structure-and-layout.md`).
- Inputs, outputs, types, variables, and validation are well defined (`04-module-interfaces-and-arguments.md`).
- Provider requirements and state/backends follow repo conventions (`05-providers-state-and-backends.md`).
- Security baseline, naming, and tagging are enforced (`08-security-naming-and-tagging.md`).
- Examples and documentation are complete and generated (`10-examples-and-docs-automation.md`).
- Local validation and CI gates pass (`09-testing-and-ci.md`).
- Distribution, versioning, and upgrade guidance is documented (`06-sources-and-distribution.md`).

## Module Review Checklist

- Scope and non-goals are explicit; no hidden behavior or implicit dependencies.
- Inputs are typed, validated, documented, and environment-agnostic by default.
- Sensitive data is handled via secrets managers or data sources and marked `sensitive = true` where appropriate.
- Resources default to least privilege, encryption at rest and in transit, and no public exposure.
- Module composition is flat and dependencies are passed in explicitly.
- Examples demonstrate realistic usage and prefer internal modules over raw resources.
- Documentation includes purpose, usage, architecture notes, security considerations, and limitations.

## Definition of Done (Production Modules)

- Plan completed with MCP documentation references and approved scope.
- Module scaffold exists with required files and versions pinned.
- Inputs/outputs are documented, typed, validated, and sensitive where required.
- README includes metadata, usage, architecture notes, security considerations, and limitations.
- Examples exist and run successfully with `scripts/test.sh`.
- CI checks pass, including formatting and security scans.
- Versioning and upgrade notes are recorded when changes are breaking.
- After implementation and documentation are complete, update all relevant Plan files and memory files for the task. The task is not done until Plan and memory are fully updated.

## Sources of Truth

As each new guide is filled, it becomes the authoritative source for that topic and the corresponding legacy sections will be replaced with pointers.
