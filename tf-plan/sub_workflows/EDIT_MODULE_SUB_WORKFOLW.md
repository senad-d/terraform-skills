# Edit-module sub-workflows

1. Confirm edit requirements (hard gate).

   - Extract the target module name, the explicit change goal, constraints, and success criteria from the user prompt.
   - Verify the module exists in the repo and identify its root path; stop and ask if unclear.

2. Inspect the current module.

   - Read module README, variables, outputs, main resources, and examples to understand intent and interface.
   - Note current dependencies, providers, and resource inventory that will be touched.

3. Define the change set.

   - Translate the requested changes into concrete edits (inputs/outputs/resources/behavior).
   - Identify in-scope and out-of-scope paths, and any interface or state impact.

4. Gather evidence and constraints.

   - Check AWS and Terraform provider docs for required arguments, limits, and constraints relevant to the change.
   - Capture evidence for assumptions that affect behavior, security, reliability, or cost.

5. Update the plan and risk assessment (hard gate).

   - Fill the plan template with the change list mapped to AWS Well-Architected pillars.
   - Document impact, backward compatibility, migrations, rollout strategy, risks, and rollback.
   - Stop-gate: do not proceed until risks and rollback are explicitly captured.


6. Close out.

   - Create output using the following response [template](./templates/RESPONSE_TEMPLATE.md)
