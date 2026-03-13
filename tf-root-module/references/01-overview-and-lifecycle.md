---
page_title: Terraform Root Module Documentation Overview
description: >-
  Entry point for the Terraform root module documentation set, describing the root module lifecycle, how to navigate the guides, and which document is authoritative for each topic.
---

# Terraform Module Documentation Overview

## Audience
Module authors, reviewers, and tooling maintainers.

## Purpose
This guide is the entry point for the root module documentation set. It explains how to navigate the guides, outlines the root module lifecycle, and calls out which documents are authoritative for each topic.

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
6. Release, version, and maintain
7. Refactor or deprecate safely

Lifecycle automation touchpoints:
- Scaffolding: `scripts/root-module.sh`
- Validation: `scripts/test.sh`

## Production Readiness Checklist
- Module purpose and abstraction are clear and not a thin wrapper (`02-module-creation-and-fundamentals.md`).
- Standard layout and required files exist (`03-module-structure-and-layout.md`).
- Inputs, outputs, types, variables, and validation are well defined (`04-module-interfaces-and-arguments.md`).
- Provider requirements and state/backends follow repo conventions (`05-providers-state-and-backends.md`).
- Security baseline, naming, and tagging are enforced (`08-security-naming-and-tagging.md`).
- Examples are complete and generated (`10-examples.md`).
- Local validation and CI gates pass (`09-testing-and-ci.md`).
- Distribution, versioning, and upgrade guidance is documented (`06-sources-and-distribution.md`).

## Module Review Checklist
- Scope and non-goals are explicit; no hidden behavior or implicit dependencies.
- Inputs are typed, validated, documented, and environment-agnostic by default.
- Sensitive data is handled via secrets managers or data sources and marked `sensitive = true` where appropriate.
- Resources default to least privilege, encryption at rest and in transit, and no public exposure.
- Module composition is flat and dependencies are passed in explicitly.
- Examples demonstrate realistic usage and prefer internal modules over raw resources.

## Definition of Done (Production Modules)
- Plan completed with MCP documentation references and approved scope.
- Module scaffold exists with required files and versions pinned.
- Inputs/outputs are documented, typed, validated, and sensitive where required.
- README includes metadata, usage, architecture notes, security considerations, and limitations.
- Examples exist and run successfully with `scripts/test.sh`.
- CI checks pass, including formatting and security scans.
- Versioning and upgrade notes are recorded when changes are breaking.
- After implementation is complete, update all relevant Plan files and memory files for the task. The task is not done until Plan and memory are fully updated.

## Documentation Map

### Decide and Design
- `02-module-creation-and-fundamentals.md`: Module fundamentals and design principles (when and why to create a module, what belongs in a module vs a root module).
- `07-composition-and-patterns.md`: Composition patterns and root module design (canonical guide for how modules are combined).

### Implement
- `03-module-structure-and-layout.md`: Module structure and repository layout (root module files, nested modules, and examples directory structure).
- `04-module-interfaces-and-arguments.md`: Module interfaces, variables, and validation (canonical guide for inputs, outputs, types, and validation rules).
- `05-providers-state-and-backends.md`: Providers, state, backends, and environments (canonical guide for provider configuration and remote state layout).
- `08-security-naming-and-tagging.md`: Security, naming, and tagging guidelines (canonical security and tagging guide).
- `10-examples-and-docs-automation.md`: Examples, documentation, and user-facing docs (canonical guide for examples and documentation workflow).

### Publish and Evolve
- `06-sources-and-distribution.md`: Module distribution, versioning, and upgrades (canonical guide for source selection, versioning policy, and upgrade playbooks).
- Supporting references:
  - `05-providers-state-and-backends.md` for backend and environment layouts.
  - `07-composition-and-patterns.md` for composition implications.
  - `08-security-naming-and-tagging.md` for security and tagging impact.

### Test and Operate
- `09-testing-and-ci.md`: Testing, examples, and CI automation (canonical testing and CI guide).
- `10-examples-and-docs-automation.md`: Examples as documentation and test assets; documentation generation workflow.

### Topic Canonical Guides
- Interfaces, variables, and validation → `04-module-interfaces-and-arguments.md`.
- Providers, state, backends, and environments → `05-providers-state-and-backends.md`.
- Composition and root module design → `07-composition-and-patterns.md`.
- Security, naming, and tagging → `08-security-naming-and-tagging.md`.
- Distribution, versioning, and upgrades → `06-sources-and-distribution.md`.
- Testing and CI → `09-testing-and-ci.md`.
- Examples and documentation → `10-examples-and-docs-automation.md`.

## Sources of Truth
As each new guide is filled, it becomes the authoritative source for that topic and the corresponding legacy sections will be replaced with pointers.
