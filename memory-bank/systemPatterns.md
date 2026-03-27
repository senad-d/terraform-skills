# System Patterns

## Design Patterns

- Follow a layered structure: `interface` (inputs/outputs and prompts), `core` (deterministic logic), `adapters` (tools/CLI/API), and `assets` (templates/data). Keep adapters replaceable without changing core logic.
- Use explicit contracts for each skill: required inputs, optional inputs with defaults, outputs/artifacts, and side effects. Document these in `SKILL.md` and enforce them in scripts.
- Keep skills idempotent and composable: no hidden state, no implicit dependencies, and no environment-specific hardcoding. Use clear pre-checks and return codes for chaining.
- Prefer small, single-responsibility skills over monoliths. Compose workflows with shared interfaces instead of reimplementing logic across skills.
- Centralize shared logic in reusable scripts/utilities with stable entrypoints. Avoid copy-paste; version shared utilities and note compatibility in `SKILL.md`.

## Module Structure

- Each skill is self-contained (SKILL.md, scripts, configs), with a clear separation of input → processing → output. Reusable components live in shared scripts/utilities, and configuration is environment-aware (dev/qa/prod).

## Naming and Tagging

- Use consistent naming: `<domain>-<action>` (e.g., `aws-terraform-deploy`). Tag by purpose: `deploy`, `validate`, `monitor`, `cleanup`. Include environment/context where relevant (e.g., `-prod`, `-shared`). Follow AWS tagging strategy for resources: `Environment`, `Owner`, `Project` (extend with domain-specific tags as needed).

## Validation

- Validate all inputs before execution. Pre-check dependencies (credentials, tools, state). Fail fast with clear error messages.

## Composition

- Skills are small, single-responsibility units with clear inputs/outputs and explicit artifacts. They can be chained (e.g., validate -> plan -> deploy) via shared interfaces rather than internal logic. Avoid tight coupling, hard-coded sequencing, or hidden dependencies. Design for reuse across workflows and pipelines.

## Versioning

- Use semantic versioning for skills (e.g., v1.2.0). Preserve backward compatibility whenever possible. Pin skill versions in dependent workflows to avoid breaking changes.
