---
page_title: Arhitecture Planning
description: Arhitecture guidelines for agents to use when creating plan files.
---

Provide a consistent, strict way to design AWS infrastructure and Terraform plans so outputs are clear, minimal, secure, and deployable.

## Planning Mindset

- Start with requirements, not services. Translate objectives into constraints.
- Think in layers: account and org, network, compute, data, security, observability, delivery.
- Design for change: assume future scaling, regional expansion, and policy evolution.
- Prefer managed services when they meet requirements and reduce ops burden.

## Inputs Checklist

- Business goals and success metrics.
- Users, traffic patterns, latency, and availability targets.
- Data types, sensitivity, residency, and retention.
- Compliance obligations and audit needs.
- Budget boundaries and cost model.
- Operational model: on-call, deployment frequency, and team skills.

## Core Architecture Rules

- Use multiple accounts for separation: shared services, security, production, non-prod.
- Choose regions intentionally and document rationale.
- Define network boundaries first: VPCs, subnets, routing, and egress.
- Default to private subnets for workloads; expose only what must be public.
- Assume zero trust inside the VPC. Minimize lateral access.
- Make dependencies explicit and avoid hidden coupling between stacks.

## Security and IAM

- Least privilege by default. Use roles with explicit trust and scoped policies.
- Centralize identity with IAM Identity Center when possible.
- Encrypt data in transit and at rest with KMS keys defined per domain.
- Log and alert on access changes, privileged actions, and policy drift.
- Use S3 block public access and enforce encryption and TLS.

## Reliability and Availability

- Map availability requirements to multi-AZ or multi-region designs.
- Define failure domains and acceptable blast radius.
- Plan backups, restores, and DR tests with RPO and RTO targets.
- Avoid single points of failure in network, compute, and control planes.

## Performance and Scalability

- Identify bottlenecks early: network, storage IOPS, concurrency limits.
- Prefer autoscaling and serverless where predictable.
- Set explicit service quotas and request increases before launch.

## Cost and Sustainability

- Tag every resource with owner, environment, and cost center.
- Use budgets and alerts from day one.
- Choose right-sized services and consider savings plans and reserved capacity.

## Observability

- Define logs, metrics, and traces per service.
- Create alert thresholds tied to user impact, not just system metrics.
- Centralize logs with retention and search requirements stated.

## Terraform Design Rules
- Modules must have clear inputs, outputs, and versioning.
- Use a remote state backend with locking and encryption.
- Separate stacks by lifecycle and blast radius.
- Do not mix manual changes with Terraform-managed resources.
- Pin provider versions and document upgrade cadence.
- Prefer data sources over duplicated config where possible.

## How to reason about evidence and verify decisions

- Treat every design choice as a hypothesis: state the requirement it satisfies, the evidence (docs, quotas, or measurements) that supports it, and the specific verification step (query, test, or checklist) that will confirm it before build.
- Prefer primary sources: AWS docs for service behavior, quotas, and regional availability; provider docs for Terraform limitations.
- Flag assumptions explicitly with dates and owners, and require a follow-up validation step if any assumption is high risk or time-sensitive.

## Critical thinking steps

- Restate the primary requirement and top 3 constraints in one sentence.
- List assumptions and unknowns; mark which are high risk or time-sensitive.
- Generate 2-3 viable architectures; note why each does or does not satisfy constraints.
- Choose the simplest option that meets requirements and justify with evidence.
- Run failure-mode checks: scaling limits, single points of failure, data loss, and security gaps.
- Validate regional availability, quotas, and Terraform/provider support for every critical service.
- Define the minimum verification plan (queries, tests, or PoC) needed before build.

## Quality Gates

- Every plan must include security, reliability, cost, and observability checks.
- Validate against requirements before proposing services.
- Reject designs that lack explicit networking, IAM, and data handling decisions.
