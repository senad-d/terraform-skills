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
export PLAN="$CODEX_HOME/skills/terraform-aws-modules/scripts/create-plan.sh"
export CREATE="$CODEX_HOME/skills/terraform-aws-modules/scripts/create-module.sh"
export TEST="$CODEX_HOME/skills/terraform-aws-modules/scripts/test-module.sh"
export EXAMPLE="$CODEX_HOME/skills/terraform-aws-modules/scripts/create-examples.sh"
export DOCUMENT="$CODEX_HOME/skills/terraform-aws-modules/scripts/create-documentation.sh"
export CLEAN_TF="$CODEX_HOME/skills/terraform-aws-modules/scripts/cleanup.sh"
```

User-scoped skills install under `$CODEX_HOME/skills` (default: `skills`).

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

1. Investigate first
   - Read `Rules/` and `$CODEX_HOME/skills/terraform-aws-modules/references` standards and review existing patterns before changing code.
   - Confirm behavior against official Terraform and AWS documentation; capture links and findings in the plan.

2. Plan before code (hard gate)
   - Ask the user to clarify the module name, the scope for the module, and the types of examples to create. Provide clear choices for all questions based on investigation, e.g.:
     ```markdown
     1. Name:
          A) ...
          B) ...
          C) ...
          D) ...
     2. Scope:
          A) ...
          B) ...
          C) ...
          D) ...
     3. Examples:
          A) basic only
          B) basic + advanced
          C) ...
          D) ...
      Reply with your picks (e.g., “1A, 2B, 3A”) and any extra constraints.
     ```
   - Create a plan file in the `Plan/` directory using the provided information along with the `$PLAN` automation script.
   - Do not edit Terraform until the plan exists.

3. Prepare files
   - Use automation scripts from this skill to create files and directories for new module and only basic example for testing the module.
   - You may create files like `.tpl`, `.tfvars`, and `.json` manually only if they are missing from the automation script.

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

Always read all references when planning module changes.

- `references/01-overview-and-lifecycle.md`: Navigation, lifecycle, and documentation map (sources of truth by topic).
- `references/02-module-creation-and-fundamentals.md`: Module fundamentals, design principles, and when to create modules.
- `references/03-module-structure-and-layout.md`: Module structure and repository layout, including modules/ and examples/.
- `references/04-module-interfaces-and-arguments.md`: Module interfaces, variables, validation rules, outputs, meta-arguments, and dynamic/conditional patterns.
- `references/05-providers-state-and-backends.md`: Provider rules, remote state/backends, and multi-account/environment provider usage.
- `references/06-sources-and-distribution.md`: Module distribution, semantic versioning, refactors using moved blocks, and upgrade strategy.
- `references/07-composition-and-patterns.md`: Composition patterns and root module design (flat composition, data-only modules, dependency inversion).
- `references/08-security-naming-and-tagging.md`: Security baseline, naming conventions, tagging standards, and secure module checklist.
- `references/09-testing-and-ci.md`: Local testing workflow, examples as tests, test-module.sh behavior, and CI gates.
- `references/10-examples-and-docs-automation.md`: Example design, documentation structure, and automation scripts for examples and READMEs.

## DO NOT DO
- DO NOT RUN `terraform appy` at any point!
- DO NOT CREATE ANY AWS resources!
- DO NOT EXPOSE ANY SECRETS OR VARIABLES!
- DO NOT COMMIT ANY CHANGES.
- DO NOT RUN AWS CLI COMMANDS.
- DO NOT USE `mkdir` command to creadte directories.
- YOU DO NOT NEED to read `scripts/*.sh` scripts.
