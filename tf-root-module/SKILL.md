---
name: tf-root-module
description: Standards and workflow for planning, composing, validating, and documenting Terraform root modules that integrate child modules with secure defaults.
---

# Terraform Root module Generator

- Provides a repeatable root-module workflow with enterprise-grade guardrails for planning, composition, and validation.

## Skill path (set once)

- Export all variables needed for running scripts.

Automation scripts:
```bash
export CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
export FIND="$CODEX_HOME/skills/tf-root-module/scripts/find.sh"
export READ="$CODEX_HOME/skills/tf-root-module/scripts/read.sh"
export PLAN="$CODEX_HOME/skills/tf-root-module/scripts/plan.sh"
export TEST="$CODEX_HOME/skills/tf-root-module/scripts/test.sh"
export CREATE="$CODEX_HOME/skills/tf-root-module/scripts/root-module.sh"
export CLEAN_TF="$CODEX_HOME/skills/tf-root-module/scripts/cleanup.sh"
```

User-scoped skills install under `$CODEX_HOME/skills` (default: `skills`).

## List child modules
- Use `find.sh` to sarch for child modules in the repository:
```bash
"$FIND" -d <directory> [-n <name-pattern>]
```

## Reading files
- Use `read.sh` to read files by selecting a directory and optionally specifying the file name:
```bash
"$READ" -d <directory> [-n <name-pattern>]
```

## Planning Template
- Use `plan.sh` to create the plan for new module:
```bash
"$PLAN" -m <module_name> [-g <short_goal>]
```
- `Plan/` holds required change plans before any Terraform edits.
- `memory-bank/` stores project context and task history; read for background when needed.

## Module Organization & Structure
- To create a new root module directories and files, use the automation script `root-module.sh`:
```bash
"$CREATE" -m <module1,module2> [-t <basic,advanced>] [-n <example-name>] [-e <examples-root>] [-r <modules-root>] [-f]
```

## Testing Guidelines
- For any change, add or update an example under `examples/<module_name>/<example_type>/` run tests for that example only using `test.sh`, e.g.:
```bash
"$TEST" -m <module_name> [-t <example_type> ...]
```

## Terraform state cleanup
- Use `cleanup.sh` to clean up terraform state after testing.
```bash
"$CLEAN_TF" --quiet examples/<module_name>
```

## Required Workflow

1. Investigate first via `$READ`
   - Read `Rules/` and `$CODEX_HOME/skills/tf-root-module/references` standards and review existing patterns before changing code.
   - Examine the `modules/` directory to locate appropriate child and wrapper modules for constructing the root module via `$FIND`.
   - Confirm behavior against official Terraform and AWS documentation; capture links and findings in the plan.

2. Plan before code (hard gate)
   - Request the user to specify the root module name, the module scope, and the overall purpose or use case. Provide clear choices for all questions based on investigation, e.g.:
     ```markdown
     1. Name:
          A) ... 
          B) ... 
          C) ...
          D) Custom name.
     2. Scope:
          A) ...
          B) ...
          C) ...
          D) Describe custom requirements.
     3. Purpose:
          A) ...
          B) ...
          C) ...
          D) Describe custom requirements.
      Reply with your picks (e.g., “1A, 2B, 3A”) and any extra constraints.
     ```
   - Create a plan file in the `Plan/` directory using the provided information along with the `$PLAN` automation script.
   - Do not edit Terraform until the plan exists.

3. Prepare files
   - Utilize the automation script `$CREATE` to generate files and directories for a new root module, and make updates to these files.
   - You may create files like `.tftpl`, `.tfvars`, and `.json` manually only if they are missing from the automation script.

4. Implement in small, focused steps
   - Follow the plan.
   - Keep changes scoped and intentional; avoid unrelated refactors.

5. Validate
   - Use automation scripts from skill `$TEST` for running tests.
   - Note assumptions or workarounds in the plan.
   - Address any issues identified by the tests and rerun them until resolved. 
   - If you encounter problems that you cannot resolve independently, seek guidance from the user.

6. Cleanup
   - Use `$CLEAN_TF` to clean up after testing and documentation is done.

---

## Best-Practice Expectations

- Define scope, non-goals, and service ownership before scaffolding.
- Compose from existing `modules/` and keep module hierarchies shallow.
- Root modules configure providers/backends; child modules only declare `required_providers`.
- Use typed variables, validation blocks, and `nullable = false` unless `null` is intentional.
- Favor least privilege, private networking, and encryption at rest/in transit by default.
- Provide examples under `examples/` and validate them with fmt, validate, lint, and security scans.
- Use semantic versioning and `moved` blocks for refactors; document breaking changes.

## Security & Configuration Notes

- Remote state must use S3 with DynamoDB locking, SSE-KMS, versioning, and restricted access.
- Use consistent naming and tag merging via the meta module and `owner-environment-basename` convention.
- Prefer short-lived credentials and `assume_role` for cross-account access.
- Mark sensitive outputs with `sensitive = true` and avoid secrets in variables/outputs when possible.
- Document security exceptions with scope, justification, and compensating controls.

## Coding Style & Naming Conventions
- Module directories use kebab-case (e.g., `iam-role-github-oidc`).
- Variables/outputs use `snake_case`; resource names follow provider conventions.
- Child modules declare `required_providers` but do not include provider blocks.
- Use the meta module for consistent naming and tag merging when applicable.

## References

Always read all references when planing.

- `01-overview-and-lifecycle.md` — lifecycle, readiness checklist, and documentation map.
- `02-module-creation-and-fundamentals.md` — root module definition and design principles.
- `03-module-structure-and-layout.md` — required files, layout, and examples structure.
- `04-module-interfaces-and-arguments.md` — input/output standards and validation.
- `05-providers-state-and-backends.md` — provider rules, state layout, and backend policy.
- `06-sources-and-distribution.md` — source selection, versioning, and upgrades.
- `07-composition-and-patterns.md` — composition patterns and root module responsibilities.
- `08-security-naming-and-tagging.md` — security baseline and naming/tagging rules.
- `09-testing-and-ci.md` — testing workflow and CI expectations.
- `10-examples.md` — example design and documentation automation.

## DO NOT DO
- DO NOT RUN `terraform appy` at any point!
- DO NOT CREATE ANY AWS resources!
- DO NOT EXPOSE ANY SECRETS OR VARIABLES!
- DO NOT COMMIT ANY CHANGES.
- DO NOT RUN AWS CLI COMMANDS.
- DO NOT USE `mkdir` command to creadte directories.
- YOU DO NOT NEED to read `scripts/*.sh` scripts.
