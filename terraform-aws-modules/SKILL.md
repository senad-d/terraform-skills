---
name: terraform-aws-modules
description: Workflow and standards for updating the Terraform AWS Modules repository. Use when adding, modifying, or reviewing Terraform modules, variables, outputs, documentation, or validation in this repo, especially when planning changes or enforcing security, reliability, and cost-aware defaults.
---

# Terraform AWS Modules

## Overview

Follow the repository workflow for planning, implementing, validating, and documenting Terraform module changes with secure, reliable, and cost-aware defaults.


## Skill path (set once)

Automation scripts:
```bash
export CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
export READ="$CODEX_HOME/skills/terraform-aws-modules/scripts/read.sh"
export PLAN="$CODEX_HOME/skills/terraform-aws-modules/scripts/create-plan.sh"
export CREATE="$CODEX_HOME/skills/terraform-aws-modules/scripts/create-module.sh"
export TEST="$CODEX_HOME/skills/terraform-aws-modules/scripts/test-module.sh"
export EXAMPLE="$CODEX_HOME/skills/terraform-aws-modules/scripts/create-examples.sh"
export DOCUMENT="$CODEX_HOME/skills/terraform-aws-modules/scripts/create-documentation.sh"
export CLEAN_TF="$CODEX_HOME/skills/terraform-aws-modules/scripts/cleanup.sh"
```

User-scoped skills install under `$CODEX_HOME/skills` (default: `skills`).

## Reading files
- Use `read.sh` to read files by selecting a directory and optionally specifying the file name:
```bash
"$READ" -d <directory> [-n <name-pattern>]
```

## Planning Template
- Use `create-plan.sh` to create the plan for new module:
```bash
"$PLAN" -m <module_name> [-g <short_goal>]
```
- `Plan/` holds required change plans before any Terraform edits.
- `memory-bank/` stores project context and task history; read for background when needed.

## Module Organization & Structure
- To create a new module template directories and files, use the automation script:
```bash
"$CREATE" -m <module_name> [-rv <tf_required_version>] [-av <aws_provider_version>]
```
- To create a new module example directories and files, use the automation script:
```bash
"$EXAMPLE" -m <module1,module2> [-t <basic,advanced>] [-n <example-name>] [-e <examples-root>] [-r <modules-root>] [-f]
```

## Testing Guidelines
- For any change, add or update an example under `modules/<module_name>/` and `examples/<module_name>/<example_type>/` run tests for that example only using `test-module.sh`, e.g.:
```bash
"$TEST" -m <module_name> [-t <example_type> ...]
```

## Terraform Module Documentation Rule
- Create the <module_name> documentation by running this command:
```bash
"$DOCUMENT" -m <module_name>
```
After the file is cretaed, update the file folowing rules:
- Read the module tf files to understand module purpes and features.
- Read the new README.md file.
- Update sections containing `<!-- TODO: ... -->` commnets with clear and concise documentation based on the requirements from that comment.
- Title must use capital letters when appropriate. (e.g. Athena Module, API-Gateway Module...)
- DO NOT use any fluff to increase the word count.
- After the editing is done, run the `terraform-docs` command to compleate the file:
```bash
terraform-docs markdown table modules/<module_name> >> modules/<module_name>/README.md
```

## Terraform state cleanup
- Use `cleanup.sh` to clean up terraform state after testing.
```bash
"$CLEAN_TF" --quiet modules/<module_name>
"$CLEAN_TF" --quiet examples/<module_name>
```

## Required Workflow

1. Investigate first via `$READ`
   - Read `Rules/` and `$CODEX_HOME/skills/terraform-aws-modules/references` standards and review existing patterns before changing code.
   - Confirm behavior against official Terraform and AWS documentation; capture links and findings in the plan.

2. Plan before code (hard gate)
   - Ask the user to clarify the module name, the scope for the module, and the types of examples to create. Provide clear choices for all questions based on investigation, e.g.:
     ```markdown
     1. Name:
          A) ...
          B) ...
          C) ...
          D) Custom name.
     2. Scope:
          A) ... (A wrapper module around terraform-aws-modules when available, extended with additional resources where required.)
          B) ... (A module built entirely from Terraform resources, without relying on a community module.)
          C) ... (Use a module from terraform-aws-modules organization when available, without modification.)
          D) Describe custom requirements.
     3. Examples:
          A) basic only
          B) basic + advanced
          C) ... (basic + advanced + iclude any edge cases or complex setups.)
          D) Describe custom requirements.
      Reply with your picks (e.g., “1A, 2B, 3A”) and any extra constraints.
     ```
   - Create a plan file in the `Plan/` directory using the provided information along with the `$PLAN` automation script.
   - Do not edit Terraform until the plan exists.

3. Prepare files
   - Use automation scripts from this skill to create files and directories for new module and only basic example for testing the module.
   - You may create files like `.tftpl`, `.tfvars`, and `.json` manually only if they are missing from the automation script.

4. Implement in small, focused steps
   - Follow the plan.
   - Keep changes scoped and intentional; avoid unrelated refactors.

5. Validate
   - Use automation scripts from skill for running tests.
   - Note assumptions or workarounds in the plan and docs.

6. Document
   - Create module documentation using the `$DOCUMENT`.
   - Update completed tasks in Plan and memory.

7. Cleanup
   - Use `$CLEAN_TF` to clean up after testing and documentation is done.
---

## Best-Practice Expectations

- Pin Terraform and provider versions to stable releases; avoid floating constraints.
- Prefer logging, metrics, and sensible retention where supported.
- Surface cost-impacting knobs clearly and keep defaults conservative.

## Security & Configuration Notes
- Default to least privilege, encryption at rest/in transit, and no public exposure.
- Avoid hard-coded account IDs, regions, or environment names in module defaults.

## Coding Style & Naming Conventions
- Module directories use kebab-case (e.g., `iam-role-github-oidc`).
- Variables/outputs use `snake_case`; resource names follow provider conventions.
- Child modules declare `required_providers` but do not include provider blocks.
- Use the meta module for consistent naming and tag merging when applicable.

## References

Always read all references when planing.

- `references/01-overview-and-lifecycle.md`: Navigation, lifecycle, and sources of truth.
- `references/02-module-creation-and-fundamentals.md`: When to create a module, what a module is, and how it relates to root modules.
- `references/03-module-structure-and-layout.md`: Required files, layout, and module and example directory structure.
- `references/04-module-interfaces-and-arguments.md`: Inputs, outputs, types, and meta-argument usage.
- `references/05-providers-state-and-backends.md`: Provider rules, backends, and state topology.
- `references/06-sources-and-distribution.md`: Module source types and distribution strategy.
- `references/07-composition-and-patterns.md`: Composition, shallow hierarchies, and data-only modules.
- `references/08-security-naming-and-tagging.md`: Security baseline, naming, tagging, and meta module conventions.
- `references/09-testing-and-ci.md`: Local testing workflow and CI gates.
- `references/10-examples-and-docs-automation.md`: Example design and documentation automation scripts.
- `references/11-versioning-refactors-and-upgrades.md`: Semantic versioning, moved blocks, and upgrade playbooks.
- `references/12-dynamic-blocks-and-conditional-sections.md`: Dynamic block usage and conditional nested configuration.
- `references/13-variables-and-validation.md`: Variable standards, validation rules, and error messages.

## DO NOT DO
- DO NOT RUN `terraform appy` at any point!
- DO NOT CREATE ANY AWS resources!
- DO NOT EXPOSE ANY SECRETS OR VARIABLES!
- DO NOT COMMIT ANY CHANGES.
- DO NOT RUN AWS CLI COMMANDS.
- DO NOT USE `mkdir` command to creadte directories.
- YOU DO NOT NEED to read `scripts/*.sh` scripts.
