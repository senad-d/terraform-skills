---
page_title: Infrastructure Architecture Guidelines
description: >-
  Actionable baseline for AWS root module architecture: decision order, security,
  networking, compute, observability, DR, and cost expectations.
---

# Infrastructure Architecture Guidelines

## Audience

Module authors, reviewers, platform engineers, SREs, and security stakeholders.

## Purpose

Define the architecture baseline and decision order for AWS root modules in this
repository. This is the authoritative guide for org-level architecture guardrails.

## Org Guardrails (Non-Negotiable)

- AWS-only scope for root modules in this repo.
- Root modules own providers/backends; child modules must not define providers.
- Default to least privilege, private networking, and encryption at rest and in
  transit.
- Tagging is mandatory and consistent across stacks.
- Exceptions require explicit documentation and approval.

Security, naming, and tagging rules are defined in
`08-security-naming-and-tagging.md`.

## Org Foundation Guardrails

Identity and Access:

- MUST use centralized identity (SSO or external IdP) with short-lived
  credentials for human access.
- MUST define standard role naming and session duration limits for all accounts.
- SHOULD require MFA for privileged roles and break-glass access.

Account and OU Strategy:

- MUST define account vending and ownership for each environment and product
  boundary.
- MUST use OU-level SCPs to enforce baseline restrictions and region policy.
- SHOULD maintain a documented account lifecycle (create, migrate, retire).

Central Security and Logging:

- MUST centralize CloudTrail, Config, and security findings in a dedicated
  security account.
- MUST centralize log aggregation in a dedicated logging account with defined
  retention and access controls.
- SHOULD enable GuardDuty and Security Hub org-wide where supported.

Shared Services Baseline:

- MUST define a shared networking baseline (hub VPC or transit architecture)
  and cross-account connectivity pattern.
- MUST standardize internal DNS and service discovery ownership.
- SHOULD document shared service ownership and cost allocation.

## Architecture Decision Order

Make decisions in order, document rationale, and keep stack boundaries explicit:

1. Account and environment boundaries
2. Network topology and data ownership
3. Compute placement and service selection
4. Observability and telemetry wiring
5. DR strategy and cost management

## Providers and Backends

Remote state and backend configuration must follow shared conventions so
multi-environment and multi-account usage remains predictable.

- Remote state must be stored in S3 with state locking enabled.
- State keys must match folder structure and be environment-prefixed.
- Preferred bucket naming pattern: `${owner}-${env}-tf-state`.
- Enable S3 versioning and server-side encryption (SSE-KMS preferred).

Backend config fields: `bucket`, `key`, `region`, `encrypt`, `use_lockfile`.

Example backend variables (e.g. dev.tfvars):

```hcl
bucket  = "myproject-dev-tf-state"
key     = "dev/vpc/terraform.tfstate"
region  = "us-east-1"
encrypt = true

use_lockfile = true
```

Example key patterns:

- VPC: `${var.env}/vpc/terraform.tfstate`
- Cloud Map: `${var.env}/cloud-map/terraform.tfstate`
- S3: `${var.env}/s3-hdn-files/terraform.tfstate`
- SQS: `${var.env}/sqs-hdn-inbound/terraform.tfstate`

### Backend Configuration Example

```hcl
terraform {
  backend "s3" {}
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}
```

### Remote State Wiring

Reference other stacks in this repo via `terraform_remote_state`; avoid
hardcoded ARNs. For external or AWS-managed resources, prefer data sources.

## Security Defaults

- Enforce least-privilege IAM roles and scoped policies.
- Use short-lived credentials and `assume_role`; never embed static secrets.
- Store secrets in AWS Secrets Manager or SSM Parameter Store, not in variables.
- Encrypt data at rest and in transit; prefer KMS where supported.
- Avoid public exposure by default; document and review any exceptions.

## Networking

- Define VPC segmentation early (public, private, isolated tiers as needed).
- Default workloads to private subnets; expose public endpoints only when
  required.
- Prefer VPC endpoints for AWS services to reduce public egress.
- Control ingress and egress with security groups and NACLs as guardrails.
- Standardize DNS and service discovery via Route 53 and internal naming.

## Compute and Deployment

- Prefer managed services before self-managed compute where feasible.
- Use autoscaling and health checks for workloads.
- Favor immutable deployments and golden images over in-place mutation.
- Keep environment parity across dev, staging, and production.

## Observability and Logging

- Enable CloudTrail for API auditing and account-level visibility.
- Use CloudWatch Logs and metrics for service and application telemetry.
- Define alarms for availability, latency, error rate, and saturation thresholds.
- Centralize logs with controlled access and retention policies.
- Use tracing (X-Ray or OpenTelemetry) for critical request paths.

## Operational Readiness and Runbooks

Ownership and Support:

- MUST define an operational owner and on-call escalation path for each root stack.
- SHOULD document service dependencies and upstream/downstream impact.

Monitoring and Alerting:

- MUST define SLO/SLI targets or explicit alert thresholds for availability, latency, error rate, and saturation.
- MUST link dashboards and alarm locations used for incident triage.

Change Management:

- MUST document rollout and rollback steps for each critical stack change.
- SHOULD define change windows and patching cadence for long-lived services.

Backup and DR Verification:

- MUST define RPO/RTO targets and the cadence for restore tests.
- MUST document where restore test evidence lives (runbook or ticket link).

Runbooks:

- MUST link to runbooks for incident response and recovery actions.
- SHOULD include a "first 15 minutes" triage procedure and owner contacts.

## DR, Retention, and Backups

- Align log retention with data classification and audit expectations.
- Automate backups for stateful services and critical data stores.
- Use multi-region strategies only when required by availability needs.

## Cost and FinOps

- Require standard tags for owner, environment, and cost allocation.
- Set budgets and alerts for key services and environments.
- Right-size compute and storage defaults; avoid over-provisioning.
- Use schedules or automation to scale down non-prod environments when possible.

## Related Guides

- `01-overview-and-lifecycle.md` — documentation map and lifecycle overview.
- `02-module-creation-and-fundamentals.md` — when to create vs extend modules.
- `03-module-structure-and-layout.md` — required layout and structure.
- `04-module-interfaces-and-arguments.md` — variables, validation, outputs.
- `07-composition-and-patterns.md` — composition patterns and dependency wiring.
- `08-security-naming-and-tagging.md` — security baseline and tags.
- `09-testing-and-ci.md` — validation workflow and CI gates.
- `10-examples.md` — examples and documentation expectations.
