---
page_title: Terraform Review Methodology
description: How to execute Terraform module reviews, capture evidence, assign severity, and produce consistent findings.
---

# Terraform Review Methodology

Define the end-to-end review workflow, evidence standards, severity rubric, and
required outputs so reviews are repeatable, defensible, and strict enough to
challenge assumptions and uncover hidden risk.

## Scope

Applies to Terraform child modules and root modules in this repository,
including shared patterns used across modules.

## Review Phases

1. Intake and scope
2. Module inventory and context gathering
3. Evidence collection and risk identification
4. Finding synthesis and severity assignment
5. Remediation options and recommendations
6. Verification and challenge pass
7. Publish review with sources and next steps

## Evidence Rules

Evidence types allowed:

- File path + line reference.

Rules:

- Every finding must cite at least one evidence source.
- If evidence is missing, label the item as a hypothesis and request
  confirmation.
- Avoid conclusions based solely on assumed intent or style preferences.
- If a module claims a behavior in README but the code contradicts it, treat the
  mismatch as a finding with evidence.
- If a security control is partially implemented, it is not compliant.

## Critical Thinking Gates

Use these gates to challenge the code, not just read it:

- What is the worst-case failure if this input is malformed or missing?
- What happens if a dependency is removed, changed, or renamed?
- Which resources are exposed publicly and why is that unavoidable?
- Are defaults safe for a production environment with no extra input?
- What happens in multi-account or multi-region use?
- Which controls rely on humans to behave correctly rather than code?
- Where can cost scale unbounded or silently?
- Are lifecycle or ignore rules hiding drift or security changes?

## Severity Rubric

| Severity | Definition | Typical Triggers | Required Action |
| --- | --- | --- | --- |
| Critical | Immediate risk of compromise or data loss | Public data exposure, privilege escalation | Block merge/deploy until fixed |
| High | Material security or reliability impact | Weak IAM controls, encryption gaps | Fix before release |
| Medium | Impactful but bounded issue | Missing validation, noisy logging | Fix before next release |
| Low | Minor improvement opportunity | Naming drift, minor refactor | Track and schedule |

Escalation rules:

- If a finding affects data confidentiality or integrity, severity cannot be
  lower than High.
- If a default enables public access or admin privileges, severity is Critical.
- If a remediation is unclear, keep severity but add a "Verification required"
  note.

## Required Outputs Per Finding

- Title and short summary.
- Severity and impact statement.
- Evidence references.
- Recommended remediation with concrete HCL changes.
- Expected outcome.
- Assumptions or constraints (if any).

## Well-Architected Pillar Mapping

- Map each finding to at least one AWS Well-Architected pillar.
- Use the pillar mapping [guide](./05-pillar-mapping.md) to keep
  labeling consistent.

## Constructive Feedback Rules

- Be specific: tie every statement to evidence.
- Be actionable: recommend exact HCL or policy changes.
- Avoid vague guidance; every item must include a clear next step.
- Highlight safe defaults and good patterns to reinforce what to keep.

## Review Checklists

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

## Review Boundaries

- Do not modify Terraform code or documentation as part of the review.
- Do not run Terraform commands or tests (plan, validate, apply, fmt, etc.).
- If module path or scope is ambiguous, stop and request clarification.
