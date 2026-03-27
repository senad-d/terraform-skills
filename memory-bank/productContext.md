# Product Context

This repository is a collection of skills used to create, modify, and update Terraform code for AWS resources.

## Why this project exists

This project exists to give automation agents a reliable set of skills for producing consistent, high-quality, production-ready Terraform code for AWS infrastructure.

## Problems it solves

- Skills that codify validated Terraform patterns, security guardrails, naming/tagging standards, and testing steps so agents can reliably generate and refine production-ready modules by reusing proven templates and workflows.

## How it should work

A Codex skill is a reusable set of instructions, scripts, and resources designed to perform a specific task automatically. It is triggered manually or automatically, then follows predefined steps to complete the workflow. This standardizes execution for consistency and repeatability. Typical examples include deploying infrastructure, running CI/CD pipelines, or enforcing coding standards.

In this repository, skills should execute Terraform work in a predictable flow:

1. The skill is invoked for a specific Terraform task.
2. The skill clarifies intent and reads relevant documentation or context.
3. The skill proposes clear follow-up options or choices to the user.
4. The skill creates a short, concrete plan.
5. The skill validates the plan against documentation and constraints.
6. The skill executes the plan in small, manageable steps.
7. The skill reviews outputs, then offers fixes or enhancements if needed.
8. The skill updates outputs and asks the user to confirm completion.

## User experience goals

- Keep skills simple, predictable, and low-effort, asking for only the minimal required input with safe defaults.
- Handle complexity behind the scenes (validation, sequencing, and recovery) without requiring the user to remember steps.
- Provide consistent behavior with clear feedback at each stage (progress, success, failure) to reduce cognitive load.
