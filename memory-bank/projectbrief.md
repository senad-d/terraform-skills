# Project Brief

Terraform Skills for CODEX CLI is a skill bundle that bootstraps a memory bank and provides guided, scriptable workflows for building high-quality Terraform AWS modules.

## Purpose

Provide a repeatable, MCP-aware workflow that turns a blank Terraform/AWS repository into a guided workspace with persistent context, consistent patterns, and ready-to-run scripts.

## Scope

- Skills and scripts for memory-bank bootstrap and Terraform AWS module workflows.
- Documentation and references that encode conventions aligned with `terraform-aws-modules`.
- Repository-local memory bank used by CODEX tasks in this repo.

## Goals

- Make module creation, documentation, and testing consistent and fast.
- Preserve project decisions, constraints, and progress in a memory bank.
- Encourage safe, validated Terraform inputs and predictable module interfaces.
- Enable MCP-backed research for AWS and Terraform context.

## Non-goals

- This repo is not a Terraform module or an infrastructure deployment.
- It does not replace Terraform tooling or the CODEX CLI.
- It does not provide production-ready AWS resources by itself.

## Workflow Requirements

- Use `$memory-bank-bootstrap` to create and maintain `memory-bank/`.
- Use `$terraform-aws-modules` scripts for scaffolding, docs, and tests.
- Follow AGENTS rules and repository conventions (rg over grep, jq for JSON).
- Update memory-bank files after significant changes or decisions.
