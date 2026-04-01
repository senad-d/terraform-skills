# New-module sub-workflows

1. Confirm new module requirements (hard gate).

   - Extract the module purpose, target AWS services, scope, constraints, and success criteria from the user prompt.
   - Identify expected inputs/outputs, environments, and integration points with existing stacks.
   - If anything is missing or ambiguous, stop and request clarification before proceeding.

2. Inventory existing patterns and dependencies.

   - Use the [find_script](./scripts/find.sh) to locate the similar modules.
   - Read for similar modules using the [read_script](./scripts/read.sh) and note conventions for naming, providers, tags, and structure.
   - Identify shared modules, policies, and standards the new module must align with.

3. Define the module interface and resources.

   - Specify variables, outputs, required providers, and resource inventory at a concrete level.
   - Call out any required data sources, IAM roles, encryption, logging, and monitoring expectations.

4. Gather evidence and constraints.

   - Check AWS and Terraform provider docs for required arguments, limits, and constraints relevant to the module.
   - Capture evidence for assumptions that affect behavior, security, reliability, or cost.

5. Update the plan and risk assessment (hard gate).

   - Fill the plan template with the module design mapped to AWS Well-Architected pillars.
   - Document impact, backward compatibility expectations, rollout strategy, risks, and rollback.
   - Stop-gate: do not proceed until risks and rollback are explicitly captured.

6. Close out.

   - Create output using the following response [template](./templates/RESPONSE_TEMPLATE.md)
