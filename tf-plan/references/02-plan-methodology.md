---
page_title: Terraform Planning Methodology
description: How to execute Terraform planning, capture evidence, and produce consistent code.
---

# Terraform Planning Methodology

Use this methodology to produce consistent, defensible Terraform plans. The goal is to identify impacts, risks, and required approvals without modifying code or running Terraform. Plans should be repeatable by a second reviewer and result in clear evidence, decisions, and next actions.

## Scope

Define the precise boundaries of the plan before review work begins. Scope must be explicit enough that a second reviewer would reach the same conclusions.

- In scope: target modules, environments, accounts, regions, and versions.
- Out of scope: resources or environments not impacted by the change set.
- Inputs: request context, constraints, dependencies, and required approvals.
- Outputs: expected plan artifacts, evidence, and decision criteria.
- Assumptions: any missing data or defaults that affect the analysis.

## Planning Phases

1. Intake and context: capture the request, target environment, constraints, and success criteria.
2. Inventory and baseline: enumerate impacted modules, state, dependencies, and existing resources.
3. Change analysis: map proposed changes to concrete resources, inputs, and outputs.
4. Risk and safety checks: identify destructive actions, data loss risks, and blast radius.
5. Evidence capture: document assumptions, expected diffs, and required approvals.
6. Review and feedback: provide findings, required fixes, and readiness decision.

## Critical Thinking Gates

Use these gates to challenge the code, not just read it:

1. Intent gate: can you restate the change goal and confirm the code actually achieves it?
2. Delta gate: what resources, inputs, outputs, and dependencies change compared to baseline?
3. Safety gate: any destructive actions, data loss risk, or irreversible changes?
4. Exposure gate: does the change widen access, public surface, or trust boundaries?
5. Operability gate: are logs, metrics, alarms, and runbook updates required?
6. Approval gate: do any changes trigger policy, compliance, or cost approvals?

## Well-Architected Pillar Mapping

- Map each planning step to at least one AWS Well-Architected pillar.
- Use the pillar mapping [guide](./references/05-pillar-mapping.md) to keep
  labeling consistent.

## Constructive Feedback Rules

- Start with the most impactful risk or gap, not minor style issues.
- Be specific: cite the exact file, resource, or block you are referencing.
- Explain the consequence (security, reliability, cost, or operability impact).
- Offer a concrete fix or an acceptable alternative.
- Separate facts from opinions; label assumptions explicitly.
- Keep feedback concise and actionable; avoid broad re-architecture unless required.
- When a change is optional, say why and note the tradeoff.

## Planning Checklists

### Security Checklist

- IAM policies are least privilege and scoped to required actions.
- Network access is minimized and uses private endpoints by default.
- Encryption at rest and in transit is enabled where supported.
- Secrets are sourced from AWS Secrets Manager or SSM Parameter Store.
- Sensitive outputs and variables are marked `sensitive = true`.
- No public S3 access or permissive ACLs without explicit exception.
- KMS keys and policies are scoped to required principals and services.
- Default security group rules do not allow broad ingress or egress.

### Reliability Checklist

- Resource lifecycles are explicit and safe (`prevent_destroy`, `create_before_destroy`).
- Timeouts, retries, and health checks are configured where applicable.
- Dependencies are explicit and avoid hidden ordering issues.
- Observability is configured (logs, metrics, alarms).
- Deletions and replacements will not cause data loss without explicit approval.
- Failover and recovery expectations are documented for stateful services.

### Cost Checklist

- Autoscaling has bounds and sensible defaults.
- Log retention is defined and not infinite by default.
- High-cost resources are justified and sized appropriately.
- Duplicate or redundant resources are avoided.
- Data transfer, NAT, and cross-AZ costs are considered and minimized.
- Storage growth and retention are bounded.

### Compliance Checklist

- Tagging includes required ownership and environment metadata.
- Data residency or regulatory constraints are documented.
- Access logging and audit trails are enabled when required.
- IAM access and administrative actions are auditable.
- Encryption and retention settings meet stated policy requirements.

### Style and Maintainability Checklist

- Module intent is clear: modules are small, opinionated, and reusable building
  blocks aligned with README claims and expected usage.
- Variables, locals, and outputs use `snake_case`.
- Repeated logic is factored into locals or modules.
- File layout follows repo conventions.
- Examples and README match current module inputs and outputs.
- No unused variables, outputs, or locals remain.
- Conditional logic is explicit and does not rely on null magic defaults.

## Anti-Patterns to Flag

- Overly broad IAM actions or resources.
- Hard-coded ARNs, regions, or account IDs without input overrides.
- Public endpoints created without clear justification.
- `ignore_changes` or lifecycle rules used to hide drift.
- Defaulting to larger instance sizes or high-cost resources without need.
- Outputs that leak secrets or sensitive identifiers.

## Planning Boundaries

- Do not modify Terraform code or documentation as part of the plan.
- Do not run Terraform commands or tests (plan, validate, apply, fmt, etc.).
