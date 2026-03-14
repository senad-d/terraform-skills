---
page_title: Infrastructure Architecture Guidelines
description: >-
  Actionable baseline for AWS root module architecture: decisions, security,
  networking, compute, observability, DR, and cost expectations.
---

# Providers, State, Backends, and Environments

## Audience

Module authors, reviewers, platform engineers, SREs, and security stakeholders.

## Purpose

Define the architecture baseline and decision order for AWS root modules in this
repository, covering providers/state, security, networking, compute,
observability, disaster recovery, and cost management.

## Rules

- AWS-only scope for root modules in this repo.
- Make decisions in order: account/env boundaries, network topology, data
  ownership, compute placement, observability, then DR.
- Root modules own providers/backends; wire dependencies explicitly using
  inputs/outputs, `terraform_remote_state` for internal stacks, and data sources
  for external services.
- Prefer internal modules and shared patterns before introducing new resources
  or thin wrappers.
- Default to secure, private, and encrypted configurations; document exceptions.

## Security

- Enforce least-privilege IAM roles and scoped policies.
- Use short-lived credentials and `assume_role`; never embed static secrets.
- Store secrets in AWS Secrets Manager or SSM Parameter Store, not in variables.
- Encrypt data at rest and in transit; prefer KMS where supported.
- Avoid public exposure by default; document and review any exceptions.

Security baseline details live in `08-security-naming-and-tagging.md`.

## Networking

- Define VPC segmentation early (public, private, isolated tiers as needed).
- Default workloads to private subnets; expose public endpoints only when required.
- Prefer VPC endpoints for AWS services to reduce public egress.
- Control ingress and egress with security groups and NACLs as guardrails.
- Standardize DNS and service discovery via Route 53 and internal naming.

## Compute & Deployment

- Prefer managed services before self-managed compute where feasible.
- Use autoscaling and health checks for workloads.
- Favor immutable deployments and golden images over in-place mutation.
- Define rollout, rollback, and patching cadence for long-lived compute.
- Keep environment parity across dev, staging, and production.

## Logging, Monitoring & Observability

- Enable CloudTrail for API auditing and account-level visibility.
- Use CloudWatch Logs and metrics for service and application telemetry.
- Define alarms for availability, latency, error rate, and saturation thresholds.
- Centralize logs with controlled access and retention policies.
- Use tracing (X-Ray or OpenTelemetry) for critical request paths.

## Logging Retention, Backups & DR

- Align log retention with data classification and audit expectations.
- Automate backups for stateful services and critical data stores.
- Define target RPO/RTO and validate them with scheduled restore tests.
- Document DR workflows and required runbooks for critical stacks.
- Use multi-region strategies only when required by availability needs.

## Cost Management & Tagging

- Require standard tags for owner, environment, and cost allocation.
- Apply shared naming and tag merging consistently across modules.
- Set budgets and alerts for key services and environments.
- Right-size compute and storage defaults; avoid over-provisioning.
- Use schedules or automation to scale down non-prod environments when possible.

## Minimal policy & tooling requirements (must‑have)

- `terraform fmt -recursive` must pass for all modules and examples.
- `terraform validate` must pass for all examples.
- `tfsec` and `tflint` must run in CI (or be explicitly waived with justification).
- CI must fail on formatting, validation, or high-severity security findings.
- Changes require review to confirm security, tagging, and architecture alignment.

## Remote State and Backends
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

Remote state wiring patterns affect how modules are composed. See
`07-composition-and-patterns.md` for composition guidance.

## Multi-Account and Multi-Environment Providers
Use aliased providers with `assume_role` to operate in member accounts or
multiple environments.

Example:
```hcl
provider "aws" {
  alias = "target_account"
  assume_role {
    role_arn     = var.target_account_role_arn
    session_name = "terraform"
  }
  region = var.target_account_region
}
```

Typical patterns:
- One default provider for the management account plus one or more aliased
  providers for member accounts.
- Environment-specific workspaces or state keys that include the environment
  name or prefix.

Security expectations for provider credentials and cross-account roles follow
the baseline in `08-security-naming-and-tagging.md`.

## Security Considerations for Providers and State
Provider and backend configuration is security-sensitive:
- Ensure provider credentials are short-lived where possible and not embedded in
  configuration files.
- Restrict access to state buckets and lock tables to the minimal set of
  principals.
- Treat state files as sensitive; they may contain resource identifiers and
  embedded data.

For the full security baseline, naming conventions, and tagging requirements,
see `08-security-naming-and-tagging.md`.

## Related Guides

- `07-composition-and-patterns.md`
- `08-security-naming-and-tagging.md`
- `09-testing-and-ci.md`
- `04-module-interfaces-and-arguments.md`
- `03-module-structure-and-layout.md`
- `10-examples.md`
