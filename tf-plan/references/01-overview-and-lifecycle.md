---
page_title: Terraform Planning Overview
description: Overview of the Terraform plan lifecycle, principles, and checklists.
---

# Terraform Planning Overview

<!-- TODO: -->

## Core Principles

<!-- TODO: -->

### `find.sh`

Purpose: list immediate subdirectories as modules and emit a JSON inventory.

Inputs:

- `-d|--directory`: root directory to scan (required)
- `-n|--name-pattern`: `rg` pattern to filter module paths (optional)

Outputs:

- JSON with `root`, `generated_at`, `module_count`, and module file lists.

Safety notes:

- Read-only; no changes to the repo.

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

Purpose: generate a plan document from a template based on plan type.

Inputs:

- `-t|--type`: plan type `new-module|edit-module|architecture` (required)
- `-m|--module`: module name (required for `new-module`/`edit-module`)
- `-g|--goal`: short goal text (optional)
- `-h|--help`: show usage and exit

Outputs:

- Creates `Plan/YYYYMMDD-<slug>.md` from the matching template and prints the path.

Safety notes:

- Writes to `Plan/` and may overwrite an existing plan with the same date/slug.

Plan type drives both the template and the output filename. For `new` and `edit`, the module name is required and becomes the slug, so the file is created. For `architecture`, the slug is fixed to `architecture`, so the file is created.

## Planning Checklist

<!-- TODO: -->

## Definition of Done

<!-- TODO: -->

## Sources of Truth

The plan methodology and remediation guides are authoritative for their topics. This overview should point to them instead of duplicating details.
