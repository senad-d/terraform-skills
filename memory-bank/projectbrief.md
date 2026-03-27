# Project Brief

Define a standardized framework for creating, organizing, and executing Codex skills that automate common engineering workflows with consistent structure, safe defaults, and repeatable execution.

## Purpose

Enable reusable, consistent, and automated task execution (deployments, validation, troubleshooting) with minimal user input through safe defaults and repeatable workflows.

## Scope

- Define the standard skill package layout: `SKILL.md` as the entrypoint, `scripts/` for automation, `resources/` for templates/data, and optional `rules/` or `tests/` when needed.
- Specify execution patterns and I/O contracts: inputs via args/env/config, validated before run; outputs as artifacts plus a clear summary of actions and results.
- Document integration points with existing tooling (AWS CLI, Terraform, CI/CD runners), including credential handling, workspace/state conventions, and safe execution gates.
- Establish logging and feedback requirements: structured logs, step-by-step progress, error context, and success/failure summaries.

## Goals

- Reduce manual steps in repetitive workflows through reusable, automated skill execution.
- Ensure consistent, reliable outcomes across runs with standardized inputs, validations, and outputs.
- Improve developer productivity and experience by minimizing required context and decision overhead.
- Align skill behavior with best practices, including AWS operational standards and safe defaults.

## Non-goals

- Replacing complex decision-making or architecture design.
- Handling highly dynamic or undefined workflows.
- Acting as a full CI/CD platform replacement.

## Workflow Requirements

- Validate all inputs, required tools, credentials, and workspace state before any action; fail fast with clear errors.
- Execute in explicit, ordered steps (pre-checks → plan → apply/execute → verify), reporting progress per step.
- Prefer idempotent operations (safe re-runs, no unintended drift) and use `plan`/`diff` outputs to gate changes.
- Emit structured logs and visible outputs for each step, including success/failure summaries and artifacts.
- Require explicit approval before destructive or irreversible actions (e.g., destroy, force replace), with a clear confirmation gate.
