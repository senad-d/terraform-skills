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

## Scope
Root modules in this repository compose reusable child modules from `modules/` into concrete stacks. They own provider and backend configuration and expose stable outputs for downstream stacks.

## Core Principles
- Use modules to create reusable, higher-level abstractions rather than thin wrappers around single resources.
- Keep module hierarchies shallow and compose modules at the root module level.
- Favor secure defaults, least privilege, and encryption at rest and in transit.
- Pin Terraform and provider versions to stable constraints.
- Prefer discoverable, repeatable patterns already used in this repository.
- For external or AWS-managed resources, use data sources; for internal stacks, use `terraform_remote_state`.

## Architecture Focus

- Decide in order: account/environment boundaries, network topology, data
  ownership/state, compute placement, observability, then DR.
- Root modules own providers and backends and make dependencies explicit through
  inputs/outputs.
- Prefer a flat module graph and internal modules before adding new resources or
  thin wrappers.
- Use data sources for external/AWS-managed services; use `terraform_remote_state`
  for internal stacks.
- Treat security and cost as first-class inputs to the architecture, not
  afterthoughts.

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

- [ ] Plan completed with MCP documentation references and approved scope.
- [ ] Providers and backends configured with secure, versioned remote state.
- [ ] Network segmentation defined with private-by-default posture.
- [ ] IAM follows least privilege; secrets stored in Secrets Manager or SSM.
- [ ] Observability wired: CloudTrail, CloudWatch metrics/logs, and alarms.
- [ ] Examples created and validated with `scripts/test.sh`.
- [ ] CI gates pass (`terraform fmt`, `terraform validate`, `tfsec`, `tflint`).
- [ ] Naming and tagging applied via shared meta conventions.
- [ ] Versioning and upgrade notes recorded for breaking changes.

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

- `02-module-creation-and-fundamentals.md` — when and why to create root modules.
- `03-module-structure-and-layout.md` — required layout and structure.
- `04-module-interfaces-and-arguments.md` — variables, validation, outputs.
- `05-infrastructure-arhitecture-guidelines.md` — architecture baseline and
  security/network/compute/observability/DR/cost expectations.
- `06-sources-and-distribution.md` — sources, versioning, upgrades.
- `07-composition-and-patterns.md` — composition patterns and dependency inversion.
- `08-security-naming-and-tagging.md` — security baseline, naming, and tags.
- `09-testing-and-ci.md` — validation workflow and CI gates.
- `10-examples.md` — examples and documentation expectations.

## Sources of Truth
As each new guide is filled, it becomes the authoritative source for that topic and the corresponding legacy sections will be replaced with pointers.
