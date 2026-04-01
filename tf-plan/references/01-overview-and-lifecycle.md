---
page_title: Terraform Planning Overview
description: Overview of the Terraform plan lifecycle, principles, and checklists.
---

# Terraform Planning Overview

Plans are a structured way to reduce risk and speed up execution. The core principles are:

- Read first: gather evidence before proposing changes.
- Explicit scope: define what is in scope and out of scope.
- Safety first: avoid destructive changes without explicit approval.
- Deterministic output: follow templates and checklists for consistency.
- Reproducible inputs: record paths, snippets, and signals used in the plan.
- Separation of concerns: plans describe changes; code changes happen later.
- Risk and tradeoffs: document alternatives, dependencies, and open questions.
- Pillar alignment: map steps to Well-Architected pillars when applicable.

## Core Principles

Planning is a read-only activity that produces a plan document, not code or state changes. The lifecycle is intentionally simple and repeatable:

1. Intake: capture the goal, scope, and constraints up front.
2. Inventory: locate relevant modules/files with [find_script](./scripts/find.sh) and [read_script](./scripts/read.sh).
3. Evidence: collect snippets, links, and signals that justify decisions.
4. Synthesis: choose an approach, note alternatives, dependencies, and risks.
5. Output: generate the plan with [plan_script](./scripts/plan.sh) and fill every required section.
6. Review: run the checklists, confirm owners, and record rollback steps.

Do not run Terraform commands during planning. If execution is required, the plan should explicitly request it and note who will run it.

### `find_script`

Purpose: list immediate subdirectories as modules and emit a JSON inventory.

Inputs:

- `-d|--directory`: root directory to scan (required)
- `-n|--name-pattern`: `rg` pattern to filter module paths (optional)

Outputs:

- JSON with `root`, `generated_at`, `module_count`, and module file lists.

Safety notes:

- Read-only; no changes to the repo.

### `read_script`

Purpose: read files from a directory (or filtered by pattern) and emit a single JSON document.

Inputs:

- `-d|--directory`: root directory to read (required)
- `-n|--name-pattern`: `rg` pattern to filter file paths (optional)

Outputs:

- JSON with `root`, `generated_at`, `file_count`, and file contents.

Safety notes:

- Read-only; no changes to the repo.

### `plan_script`

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

- Confirm plan type (`new-module`, `edit-module`, `architecture`) and goal.
- Inventory relevant modules/files with `find.sh`/`read.sh` when needed.
- Record scope, assumptions, dependencies, and non-goals up front.
- Capture evidence for current behavior and constraints (links, snippets, notes).
- Run the critical thinking gates from the methodology guide.
- Apply the full planning checklists (security, reliability, cost, compliance, style).
- Document risks, tradeoffs, and open questions with owners.
- Ensure plan sections map to Well-Architected pillars where applicable.

## Definition of Done

- Plan document exists in `Plan/` with the correct template for the plan type.
- Scope, assumptions, dependencies, and non-goals are explicit and agreed.
- Evidence is captured for current behavior and constraints (links, snippets, notes).
- Critical thinking gates and full planning checklists are completed.
- Risks, tradeoffs, and rollback approach are documented with owners.
- Follow steps are concrete, ordered, and map to Well-Architected pillars.

## Sources of Truth

The plan methodology and remediation guides are authoritative for their topics. This overview should point to them instead of duplicating details.
