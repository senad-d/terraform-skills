---
page_title: Security, Naming, and Tagging
description: >-
  Defines the security baseline, KMS and encryption expectations, naming and tagging conventions, and how modules must integrate the shared meta naming module.
---

# Security, Naming, and Tagging

## Audience
Module authors and security reviewers.

## Purpose
Define the security baseline, naming conventions, tagging standards, and the shared meta naming module contract.

## Security Baseline
- Pin Terraform and provider versions to stable constraints and update regularly.
- Store secrets in AWS Secrets Manager or SSM Parameter Store.
- Avoid passing secret values through variables or outputs; mark sensitive values with `sensitive = true`.
- Use least-privilege IAM roles and policies.
- Restrict network access with security groups and NACLs.
- Prefer private subnets; use public subnets only for internet-facing endpoints (for example, ALB or NAT).
- Encrypt data at rest and in transit (S3, EBS, RDS, TLS everywhere).
- Run security scans (tfsec, tflint, checkov, trivy) as part of CI.

## Naming and Tagging
- Use the shared meta naming module to enforce consistent naming and tag merging.
- Define `locals.meta` once in the calling module and pass `meta` to internal modules.

Required pattern:
```hcl
module "meta" {
  source = "../meta"
  meta   = local.meta
}
```

- Compose names using the `owner-environment-basename` convention.
- Ensure modules accept and propagate tags, and merge them with meta-derived tags.

## KMS and Encryption Defaults
- Prefer SSE-KMS where supported.
- Ensure state and sensitive data are encrypted and access-controlled.
- Use KMS keys for encryption of storage and secrets where available.

## Security Exceptions
If a module must deviate from secure defaults, document the exception explicitly in the README and in planning notes. Include:
- The exact exception and why it is required.
- The scope of impact and affected resources.
- Compensating controls applied.
- A review date or condition for removing the exception.

## Related Guides
- `05-providers-state-and-backends.md` for state encryption and backend requirements.
- `09-testing-and-ci.md` for security checks in CI.
