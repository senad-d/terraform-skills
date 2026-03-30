---
name: tf-child-modules
description: Workflow and standards for updating the Terraform AWS Modules repository. Use when adding, modifying, or reviewing Terraform modules, variables, outputs, documentation, or validation in this repo, especially when planning changes or enforcing security, reliability, and cost-aware defaults.
---

# Terraform AWS Modules

## Overview

Follow the repository workflow for planning, implementing, validating, and documenting Terraform module changes with secure, reliable, and cost-aware defaults.

## Scripts

- Run the [read_script](./scripts/read.sh) to read files.
- Run the [plan_script](./scripts/plan.sh) to create the plan.
- Run the [child_script](./scripts/child-module.sh) to create a new child module template directories and files.
- Run the [root_script](./scripts/root-module.sh) to create a new root module directories and files.
- Run the [test_script](./scripts/test.sh) for any change, add or update an example under `<module_directory>/`.
- Run the [document_script](./scripts/document.sh) to create the child module documentation
- Run the [clean_script](./scripts/cleanup.sh) to clean up `<module_directory>/` terraform state after testing.

### Examples:
```bash
./scripts/read.sh -d <directory> [-n <name-pattern>]
./scripts/plan.sh -m <module_name> [-g <short_goal>]
./scripts/child-module.sh -m <module_name> [-rv <tf_required_version>] [-av <aws_provider_version>]
./scripts/root-module.sh -m <module1,module2> -t <root-module-name[,another-name]> [-n <stack-name>] [-e <examples-root>] [-r <modules-root>] [-T <tf-required-version>] [-P <aws-provider-version>] [-f]
./scripts/test.sh -m <module_directory> [--plan <true|false>]
./scripts/document.sh -m <module_name>
./scripts/cleanup.sh --quiet <module_directory>
```

User-scoped skills install under `$CODEX_HOME/skills` (default: `skills`).

## Required Workflow

1. Investigate first via [read_script](./scripts/read.sh)

   - Read `Rules/` and [./references](./references) standards and review existing patterns before changing code.

2. Plan before code (hard gate)

   - Request clarification on the module name, its scope, and examples to create using the [question_template](./templates/QUESTION_TEMPLATE.md).
   - Provide clear choices for all questions based on investigation.
   - Create a plan file in the `Plan/` directory using the provided information along with the [plan_script](./scripts/plan.sh).
   - Confirm behavior against official Terraform and AWS documentation; capture links and findings in the plan.
   - Stop-gate: Do not edit Terraform until the plan exists.

3. Prepare files

   - Use the [child_script](./scripts/child-module.sh) and [root_script](./scripts/root-module.sh) to create files and directories for new module and example for testing the module.
   - You may create files like `.tftpl`, `.tfvars`, and `.json` manually if they are missing from the automation scripts.

4. Implement in small, focused steps
   - Follow the plan.
   - Keep changes scoped and intentional; avoid unrelated refactors.

5. Validate (hard gate)

   - Use the [test_script](./scripts/test.sh) for running tests.
   - Correct any issues found in the test, then run it again until fully resolved.
   - If the issue cannot be resolved, ask the user for input using the following [resolve_template](./templates/RESOLVE_TEMPLATE.md).
   - Note assumptions or workarounds in the plan and docs.
   - Stop-gate: Do not proceed to the next step until the validation passes successfully.

6. Document

   - Create module documentation using the [document_script](./scripts/document.sh), after development is done and tests pass.
   - Use the `terraform-docs` command to compleate documentation.

7. Cleanup

   - Use the [clean_script](./scripts/cleanup.sh) to clean up after testing and documentation is done.

7. Close out.

   - Update completed tasks in Plan.
   - Utilize the [response_template](./templates/RESPONSE_TEMPLATE.md) to formulate ouput and fill in the variables with the appropriate information.

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

- [01-overview-and-lifecycle.md](./references/01-overview-and-lifecycle.md): Navigation, lifecycle, and sources of truth.
- [02-module-creation-and-fundamentals.md](./references/02-module-creation-and-fundamentals.md): When to create a module, what a module is, and how it relates to root modules.
- [03-module-structure-and-layout.md](./references/03-module-structure-and-layout.md): Required files, layout, and module and example directory structure.
- [04-module-interfaces-and-arguments.md](./references/04-module-interfaces-and-arguments.md): Inputs, outputs, types, and meta-argument usage.
- [05-providers-state-and-backends.md](./references/05-providers-state-and-backends.md): Provider rules, backends, and state topology.
- [06-sources-and-distribution.md](./references/06-sources-and-distribution.md): Module source types and distribution strategy.
- [07-composition-and-patterns.md](./references/07-composition-and-patterns.md): Composition, shallow hierarchies, and data-only modules.
- [08-security-naming-and-tagging.md](./references/08-security-naming-and-tagging.md): Security baseline, naming, tagging, and meta module conventions.
- [09-testing-and-ci.md](./references/09-testing-and-ci.md): Local testing workflow and CI gates.
- [10-examples-and-docs-automation.md](./references/10-examples-and-docs-automation.md): Example design and documentation automation scripts.

## DO NOT DO

- DO NOT RUN `terraform apply` at any point!
- DO NOT CREATE ANY AWS resources!
- DO NOT EXPOSE ANY SECRETS OR VARIABLES!
- DO NOT COMMIT ANY CHANGES.
- DO NOT RUN AWS CLI COMMANDS.
- DO NOT use any fluff to increase the word count.
- DO NOT create directories manually with `mkdir`.
- YOU DO NOT NEED to read `scripts/*.sh` scripts.
