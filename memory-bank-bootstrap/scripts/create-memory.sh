#!/usr/bin/env bash
set -euo pipefail

print_usage() {
  cat << EOF
Usage: $(basename "$0") [TARGET_DIR]

Create a memory-bank directory structure with generic markdown templates
and inline TODO guidance.

Arguments:
  TARGET_DIR  Optional path for the memory-bank root.
              Defaults to ./memory-bank

Examples:
  $(basename "$0")
  $(basename "$0") my-project-memory
EOF
}

if [ "${1-}" = "-h" ] || [ "${1-}" = "--help" ]; then
  print_usage
  exit 0
fi

TARGET_DIR="${1:-memory-bank}"

if [ -e "$TARGET_DIR" ]; then
  echo "Target directory $TARGET_DIR already exists; skipping memory-bank initialization."
  exit 0
fi

mkdir -p "$TARGET_DIR/tasks"
mkdir -p "$TARGET_DIR/../Rules" "$TARGET_DIR/../Plan"

# activeContext.md
cat << 'EOF' > "$TARGET_DIR/activeContext.md"
# Active Context

> TODO: Use this file to capture what is actively happening in the project right now. Replace these TODO notes with real content and delete them.

## Current Work Focus

> TODO: List the main areas you are currently focusing on. Delete this line once you write real content.

## Recent Changes

> TODO: Summarize the important changes made recently that others should know about.

## Next Steps

> TODO: List the next concrete actions you plan to take.

## Active Decisions and Considerations

> TODO: Capture key decisions, open questions, and important constraints that affect ongoing work.
EOF

# productContext.md
cat << 'EOF' > "$TARGET_DIR/productContext.md"
# Product Context

> TODO: Describe the product or project at a high level. Replace these TODO notes with real content and delete them.

## Why this project exists

> TODO: Explain the core reason this project exists and what problem space it addresses.

## Problems it solves

> TODO: List the main problems or pain points this project is intended to solve.

## How it should work

> TODO: Describe how the system or modules are expected to behave from a functional point of view.

## User experience goals

> TODO: Capture the key experience goals such as simplicity, safety, or performance that matter for users.
EOF

# progress.md
cat << 'EOF' > "$TARGET_DIR/progress.md"
# Progress

> TODO: Use this file to track overall progress. Replace these TODO notes with real content and delete them.

## What Works

> TODO: List the parts that are implemented and working as intended.

## Remaining Work

> TODO: List the major areas that still need to be built or improved.

## Current Status

> TODO: Summarize the current status in a few sentences that someone new can read quickly.

## Known Issues

> TODO: Record known bugs, limitations, or gaps in functionality that users should be aware of.
EOF

# projectbrief.md
cat << 'EOF' > "$TARGET_DIR/projectbrief.md"
# Project Brief

> TODO: Provide a concise overview of the project. Replace these TODO notes with real content and delete them.

## Purpose

> TODO: State the primary purpose of this project in one or two sentences.

## Scope

> TODO: Describe what is in scope and what areas the project covers.

## Goals

> TODO: List the main goals or success criteria for this project.

## Non-goals

> TODO: Clarify what is intentionally out of scope so expectations stay aligned.

## Workflow Requirements

> TODO: Capture required workflows, such as how changes should be planned, reviewed, tested, and deployed.
EOF

# systemPatterns.md
cat << 'EOF' > "$TARGET_DIR/systemPatterns.md"
# System Patterns

> TODO: Document the main architectural and design patterns used in this project. Replace these TODO notes with real content and delete them.

## Module Structure

> TODO: Describe how modules are structured, where they live, and how they should be organized.

## Naming and Tagging

> TODO: Capture conventions for names, tags, and other identifiers that should stay consistent.

## Validation

> TODO: Explain how inputs and configurations are validated and what constraints must be enforced.

## Composition

> TODO: Describe how modules or components are composed together to form larger systems.

## Versioning

> TODO: Note how versions of modules, providers, or dependencies are managed and pinned.
EOF

# techContext.md
cat << 'EOF' > "$TARGET_DIR/techContext.md"
# Tech Context

> TODO: Summarize the technical stack and constraints. Replace these TODO notes with real content and delete them.

## Stack

> TODO: List the main technologies, languages, and services used in this project.

## Tooling

> TODO: Describe the key tools and commands developers are expected to use.

## Repository Structure

- `Plan/` contains required plan files.
- `Rules/` contains required rules for modules.
- `memory-bank/` stores project context.
> TODO: Outline the important directories and how the repository is organized.

## Constraints

> TODO: Capture important technical, security, or process constraints that must be respected.
EOF

# tasks/_index.md
cat << 'EOF' > "$TARGET_DIR/tasks/_index.md"
# Tasks Index

> TODO: Use this file as an index of tasks and their status. Replace these TODO notes with real content and delete them.

## In Progress

> TODO: List tasks that are currently being worked on.

## Pending

> TODO: List tasks that are planned but not started.

## Completed

> TODO: List tasks that are done, optionally with dates or links to more detail.

## Abandoned

> TODO: List tasks that were dropped or intentionally abandoned, with brief reasons if helpful.
EOF

echo "Created generic memory-bank structure in: $TARGET_DIR"
