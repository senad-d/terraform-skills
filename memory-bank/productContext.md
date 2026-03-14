# Product Context

This repository delivers CODEX CLI skills that codify best-practice workflows for Terraform AWS modules and preserve context across tasks via a memory bank.

## Why this project exists

Terraform module work often repeats the same scaffolding, documentation, and testing steps, and context gets lost between sessions. This project standardizes that workflow and makes the context durable.

## Problems it solves

- Repeated boilerplate for module layout, examples, and docs.
- Inconsistent module interfaces and naming conventions.
- Lost decisions and constraints across separate coding sessions.
- Hard-to-access AWS/Terraform context during planning.

## How it should work

Users invoke `$memory-bank-bootstrap` once to create `memory-bank/` and AGENTS rules, then use `$terraform-aws-modules` scripts to create modules, examples, docs, and tests in a consistent structure. MCP servers provide up-to-date AWS and Terraform context during tasks.

## User experience goals

- Low setup friction and minimal manual boilerplate.
- Predictable, repeatable module structure and documentation.
- Clear, durable project context with fast onboarding for new sessions.
