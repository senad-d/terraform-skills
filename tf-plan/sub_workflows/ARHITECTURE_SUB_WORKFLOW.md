# Architecture sub-workflows

1. Confirm architecture requirements (hard gate).

   - Extract AWS infrastructure goals, constraints, and non-functional requirements from the user prompt.
   - Identify workload scope, regions, accounts, compliance needs, availability targets, RTO/RPO, latency, and budget.
   - If any of these are missing or ambiguous, stop and request clarification before proceeding.

2. Investigate documentation and evidence.

   - Review AWS documentation for service capabilities, regional availability, limits/quotas, and best practices.
   - Review Terraform AWS provider documentation for required resources, arguments, and constraints.
   - Capture evidence that supports the intended architecture choices and assumptions.

3. Translate architecture into Terraform design.

   - Define the target AWS services, network topology, security boundaries, IAM model, and data flows.
   - Decide module boundaries, state layout, environments, and provider configuration strategy.
   - Identify dependencies, sequencing, and operational components (logging, monitoring, backups, DR).

4. Update the plan file.

   - Add concrete architecture decisions, Terraform module structure, and resource inventory.
   - Document assumptions, constraints, and evidence sources used for each decision.
   - Record open questions and required follow-ups.

5. Reason about potential problems and address them (hard gate).

   - Evaluate the plan for single points of failure, security gaps, quota risks, cost hotspots, and regional constraints.
   - Identify mismatches between requirements and the proposed design.
   - Update the plan with mitigations, alternatives, or explicit tradeoffs.
   - Stop-gate: not done until risks are surfaced and addressed in the plan.


6. Close out.

   - Create output using the following response [template](./templates/RESPONSE_TEMPLATE.md)
