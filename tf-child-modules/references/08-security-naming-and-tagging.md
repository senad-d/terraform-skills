---
page_title: Security, Naming, and Tagging Guidelines
description: Canonical guide for the security baseline, KMS and encryption expectations, naming and tagging conventions, and how modules must integrate shared metadata for consistent names and tags.
---

# Security, Naming, and Tagging Guidelines

Capture the security baseline, naming conventions, tagging standards, and shared metadata patterns in a single place. Other guides (for example providers/state, interfaces, and testing) refer here for security, naming, and tagging policy.

## Security Baseline

- Pin Terraform and provider versions to stable constraints and update regularly.
- Store secrets in AWS Secrets Manager or SSM Parameter Store.
- Avoid passing secret values through variables or outputs where possible; when required, mark outputs with `sensitive = true`.
- Use least-privilege IAM roles and policies.
- Restrict network access with security groups and NACLs.
- Prefer private subnets; use public subnets only for internet-facing endpoints (for example, ALB or NAT).
- Encrypt data at rest and in transit (S3, EBS, RDS, TLS everywhere).
- Run security scans (tfsec, tflint, checkov, trivy) as part of CI.

## Naming and Tagging

- Use the shared meta naming module (or equivalent shared metadata locals) to enforce consistent naming and tag merging.
- Define `locals.meta` once in the calling module and pass `meta` (or derived values) to internal modules.

Required pattern:

```hcl
module "meta" {
  source = "../meta"
  meta   = local.meta
}
```

- Compose names using the `owner-environment-basename` convention.
- Ensure modules accept and propagate tags, and merge them with meta-derived tags.
- Keep tag keys and values consistent across modules to support reporting, cost allocation, and security tooling.

## KMS and Encryption Defaults

- Prefer SSE-KMS where supported.
- Ensure state and sensitive data are encrypted and access-controlled.
- Use KMS keys for encryption of storage and secrets where available.
- Avoid disabling encryption or using weaker algorithms except in documented, approved exception cases.

## Security Exceptions

If a module must deviate from secure defaults, document the exception explicitly in the README and in planning notes. Include:

- The exact exception and why it is required.
- The scope of impact and affected resources.
- Compensating controls applied.
- A review date or condition for removing the exception.

## Secure Module Checklist

Use this checklist when designing or reviewing modules:

- [ ] Terraform and provider versions are pinned to supported, non-end-of-life versions.
- [ ] Secrets and sensitive configuration are stored in appropriate secret managers (for example, Secrets Manager or SSM Parameter Store), not in plain-text variables or files.
- [ ] Any outputs that could expose sensitive information are marked `sensitive = true`.
- [ ] IAM roles and policies follow least-privilege principles.
- [ ] Network exposure is minimized (private subnets by default; public endpoints only where strictly required).
- [ ] Data at rest and in transit are encrypted according to KMS and TLS expectations.
- [ ] Module names and resource names follow the `owner-environment-basename` convention.
- [ ] Tags are accepted as inputs, merged with shared metadata tags, and consistently applied to created resources.
- [ ] Security scans (tfsec, tflint, checkov, trivy as applicable) are included in CI for the module’s examples.
