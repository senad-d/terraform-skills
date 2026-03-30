---
name: tf-root-module
description: Standards and workflow for planning, composing, validating, and documenting Terraform root modules that integrate child modules with secure defaults.
---

# Terraform Root module Generator

- Provides a repeatable root-module workflow with enterprise-grade guardrails for planning, composition, and validation.

## Scripts

- Run the [find_script](./scripts/find.sh) to search for modules in the repository.
- Run the [read_script](./scripts/read.sh) to read files.
- Run the [plan_script](./scripts/plan.sh) to create the plan.
- Run the [create_script](./scripts/root-module.sh) to create a new root module directories and files.
- Run the [test_script](./scripts/test.sh) for any change, add or update an example under `<module_directory>/`.
- Run the [clean_script](./scripts/cleanup.sh) to clean up `<module_directory>/` terraform state after testing.

### Examples:
```bash
./scripts/find.sh -d <directory> [-n <name-pattern>]
./scripts/read.sh -d <directory> [-n <name-pattern>]
./scripts/plan.sh -m <module_name> [-g <short_goal>]
./scripts/root-module.sh -m <module1,module2> -t <root-module-name[,another-name]> [-n <stack-name>] [-e <examples-root>] [-r <modules-root>] [-T <tf-required-version>] [-P <aws-provider-version>] [-f]
./scripts/test.sh -m <module_directory> [--plan <true|false>]
./scripts/cleanup.sh --quiet <module_directory>
```

User-scoped skills install under `$CODEX_HOME/skills` (default: `skills`).

## Required Workflow

1. Investigate first via [read_script](./scripts/read.sh)

   - Read `Rules/` and [./references](./references) standards and review existing patterns before changing code.
   - Examine the `modules/` directory to locate appropriate child and wrapper modules for constructing the root module via [find_script](./scripts/find.sh).
   - Confirm behavior against official Terraform and AWS documentation; capture links and findings in the plan.

2. Plan before code (hard gate)

   - Request the user to specify the root module name, the module scope, and the overall purpose or use case. 
   - Provide clear choices for all questions based on investigation.
   - Utilize the [question_template](./templates/QUESTION_TEMPLATE.md) to formulate inquiries and fill in the data sections with the appropriate information.
   - Create a plan file using the [plan_script](./scripts/plan.sh) and the provided information from the investigation context.
   - Stop-gate: Do not edit Terraform until the plan exists.

3. Prepare files

   - Utilize the [create_script](./scripts/root-module.sh) to generate files and directories for a new root module, and make updates to these files.
   - You may create files like `.tftpl`, `.tfvars`, and `.json` manually if they are missing from the create_script.

4. Implement in small, focused steps

   - Follow the plan.
   - Keep changes scoped and intentional; avoid unrelated refactors.

5. Validate

   - Use the [test_script](./scripts/test.sh) for running tests.
   - Note assumptions or workarounds in the plan.
   - Address any issues identified by the tests and rerun them until resolved.
   - If you encounter problems that you cannot resolve independently, seek guidance from the user.

6. Cleanup

   - Use the [clean_script](./scripts/cleanup.sh) to clean up after testing and documentation is done.

7. Close out.

   - Update completed tasks in Plan.
   - Utilize the [response_template](./templates/RESPONSE_TEMPLATE.md) to formulate ouput and fill in the variables with the appropriate information.

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

Always read all references when planning.

- [01-overview-and-lifecycle.md](./references/01-overview-and-lifecycle.md) for lifecycle, readiness checklist, and documentation map.
- [02-module-creation-and-fundamentals.md](./references/02-module-creation-and-fundamentals.md) for root module definition and design principles.
- [03-module-structure-and-layout.md](./references/03-module-structure-and-layout.md) for required files, layout, and examples structure.
- [04-module-interfaces-and-arguments.md](./references/04-module-interfaces-and-arguments.md) for input/output standards and validation.
- [05-infrastructure-architecture-guidelines.md](./references/05-infrastructure-architecture-guidelines.md) for provider rules, state layout, and backend policy.
- [06-sources-and-distribution.md](./references/06-sources-and-distribution.md) for source selection, versioning, and upgrades.
- [07-composition-and-patterns.md](./references/07-composition-and-patterns.md) for composition patterns and root module responsibilities.
- [08-security-naming-and-tagging.md](./references/08-security-naming-and-tagging.md) for security baseline and naming/tagging rules.
- [09-testing-and-ci.md](./references/09-testing-and-ci.md) for testing workflow and CI expectations.
- [10-examples.md](./references/10-examples.md) for example design.

## DO NOT DO

- DO NOT RUN `terraform apply` at any point!
- DO NOT CREATE ANY AWS resources!
- DO NOT EXPOSE ANY SECRETS OR VARIABLES!
- DO NOT RUN AWS CLI COMMANDS.
- DO NOT create directories manually with `mkdir`; use `$CREATE`.
- YOU DO NOT NEED to read `scripts/*.sh` scripts.
