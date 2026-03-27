---
page_title: Remediation and Evidence Standards
description: >-
  Guidance for investigating Terraform review findings, evaluating remediation
  options, and documenting evidence and verification steps.
---

# Remediation and Evidence Standards

## Audience

Module authors, reviewers, security stakeholders, and tooling maintainers.

## Purpose

Provide a strict, consistent approach for investigating findings, selecting
viable remediations, and documenting evidence and verification steps. The goal
is to challenge unsafe assumptions and require proof that fixes resolve the
underlying risk.

## Investigation Workflow

1. Reproduce the issue by locating the exact resource or module block.
2. Identify the root cause and the guardrail that was violated.
3. Enumerate remediation options and note tradeoffs.
4. Select the least disruptive fix that satisfies the baseline.
5. Define verification steps that prove the fix works.

## Evaluation Criteria

- Blast radius and potential downtime.
- Compatibility with existing interfaces and consumers.
- Drift risk or behavioral regressions.
- Cost impact and operational overhead.
- Security and compliance requirements.
- Risk of silent failure or partial implementation.
- Time-to-detect and time-to-recover impact.

## Remediation Patterns

### IAM Tightening

- Replace wildcard actions with scoped actions and resources.
- Use condition keys to restrict access by VPC, source IP, or tags.
- Split broad policies into role-specific policies.
- Prefer managed policies only when reviewed and approved.

### Encryption Improvements

- Enable SSE-KMS or service-managed KMS where supported.
- Ensure TLS is required for data in transit.
- Avoid disabling encryption without an explicit exception.
- Require key rotation and key policy scoping where supported.

### Network Exposure

- Prefer private subnets and private endpoints by default.
- Restrict security group ingress to required ports and sources.
- Remove public IPs unless the service is internet-facing by design.
- Use NACLs or additional segmentation only with a clear threat model.

### Lifecycle and Drift Control

- Add `prevent_destroy` to critical resources where appropriate.
- Use `ignore_changes` only for known, accepted drift.
- Set explicit `create_before_destroy` when replacement would cause downtime.
- Document any lifecycle exception and expected operational impact.

### Logging and Monitoring

- Enable access logs and audit trails where services support them.
- Define log retention and avoid indefinite retention defaults.
- Add alarms or metrics for high-risk services.
- Ensure logs are centralized and protected against tampering.

### Tagging and Naming

- Ensure `meta` tags are merged with resource-specific tags.
- Use consistent naming conventions across modules.
- Avoid hard-coded names when outputs or inputs are required.

## Example Finding Template

```markdown
### [Severity] Short finding title

**Summary:** One-sentence description of the issue.
**Impact:** Describe the risk or operational impact.
**Evidence:** `path/to/file.tf:line` or plan output snippet.
**Recommendation:** Concrete HCL change or policy edit.
**Verification:** terraform plan/validate/test steps and expected result.
**Assumptions:** Any known constraints or required approvals.
```

## Recommendation Format

Use a short, direct remediation statement followed by the exact change:

```markdown
**Recommendation:** Restrict the policy to the required actions only.
Change:
- actions = ["*"]
To:
- actions = ["s3:GetObject", "s3:PutObject"]
```

## Improvement Path Template

Use this structure to turn findings into a prioritized improvement plan:

```markdown
### Improvement Path

**Top 3 fixes (priority order):**
1. [Finding ID] - short reason for priority
2. [Finding ID] - short reason for priority
3. [Finding ID] - short reason for priority

**Per finding:**
- Fastest safe fix: [short, concrete change]
- Preferred fix: [best-practice change, if different]
- Verification: [terraform plan/validate/test + expected result]
```

## Evidence and Reference Requirements

- Every recommendation must include line-level evidence or tool output.
- Include MCP reference citations when recommending Terraform arguments or AWS
  service behavior changes.

## Critical Review Prompts

Use these prompts to challenge the remediation:

- Does this fix remove the risk or only mask it?
- Are we relying on human processes instead of code controls?
- Will this change break consumers or require coordinated updates?
- What new permissions or costs are introduced by the fix?
- How will we detect if the fix regresses later?
