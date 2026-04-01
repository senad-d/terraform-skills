---
page_title: Terraform Planning Methodology
description: How to execute Terraform planning, capture evidence, and produce consistent code.
---

# Terraform Planning Methodology

<!-- TODO: -->

## Scope

<!-- TODO: -->

## Planning Phases

<!-- TODO: -->

## Critical Thinking Gates

Use these gates to challenge the code, not just read it:

<!-- TODO: -->

## Well-Architected Pillar Mapping

- Map each planning step to at least one AWS Well-Architected pillar.
- Use the pillar mapping [guide](./05-pillar-mapping.md) to keep
  labeling consistent.

## Constructive Feedback Rules

<!-- TODO: -->

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
