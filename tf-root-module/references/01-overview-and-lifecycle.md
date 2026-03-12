---
page_title: Terraform Module Documentation Overview
description: >-
  Entry point for the Terraform module documentation set, describing the module lifecycle, how to navigate the guides, and which document is authoritative for each topic.
---

# Terraform Module Documentation Overview

## Audience
Module authors, reviewers, and tooling maintainers.

## Purpose
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
5. Document inputs, outputs, and examples
6. Validate locally and in CI
7. Release, version, and maintain
8. Refactor or deprecate safely

Lifecycle automation touchpoints:
- Scaffolding: `scripts/create-module.sh`
- Examples: `scripts/create-examples.sh`
- Documentation: `scripts/create-documentation.sh` and `terraform-docs`
- Validation: `scripts/test-module.sh`

## Production Readiness Checklist
- Module purpose and abstraction are clear and not a thin wrapper (`02-module-creation-and-fundamentals.md`).
- Standard layout and required files exist (`03-module-structure-and-layout.md`).
- Inputs, outputs, types, and meta-arguments are well defined (`04-module-interfaces-and-arguments.md`).
- Provider requirements and state/backends follow repo conventions (`05-providers-state-and-backends.md`).
- Security baseline, naming, and tagging are enforced (`08-security-naming-and-tagging.md`).
- Examples and documentation are complete and generated (`10-examples-and-docs-automation.md`).
- Local validation and CI gates pass (`09-testing-and-ci.md`).
- Versioning and upgrade guidance is documented (`11-versioning-refactors-and-upgrades.md`).

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
- Examples exist and run successfully with `scripts/test-module.sh`.
- CI checks pass, including formatting and security scans.
- Versioning and upgrade notes are recorded when changes are breaking.
- After implementation and documentation are complete, update all relevant Plan files and memory files for the task. The task is not done until Plan and memory are fully updated.

## Documentation Map
- `01-overview-and-lifecycle.md`: Navigation, lifecycle, and sources of truth.
- `02-module-creation-and-fundamentals.md`: When to create a module, what a module is, and how it relates to root modules.
- `03-module-structure-and-layout.md`: Required files, layout, and module and example directory structure.
- `04-module-interfaces-and-arguments.md`: Inputs, outputs, types, and meta-argument usage.
- `05-providers-state-and-backends.md`: Provider rules, backends, and state topology.
- `06-sources-and-distribution.md`: Module source types and distribution strategy.
- `07-composition-and-patterns.md`: Composition, shallow hierarchies, and data-only modules.
- `08-security-naming-and-tagging.md`: Security baseline, naming, tagging, and meta module conventions.
- `09-testing-and-ci.md`: Local testing workflow and CI gates.
- `10-examples-and-docs-automation.md`: Example design and documentation automation scripts.
- `11-versioning-refactors-and-upgrades.md`: Semantic versioning, moved blocks, and upgrade playbooks.
- `12-dynamic-blocks-and-conditional-sections.md`: Dynamic block usage and conditional nested configuration.
- `13-variables-and-validation.md`: Variable standards, validation rules, and error messages.

## Sources of Truth
As each new guide is filled, it becomes the authoritative source for that topic and the corresponding legacy sections will be replaced with pointers.
