---
page_title: Examples, Docs, and User-Facing Documentation
description: >-
  Canonical guide for designing examples, structuring example directories,
  generating READMEs, and integrating documentation workflows with
  repository standards.
---

# Examples, Docs, and User-Facing Documentation

## Audience

Module authors writing examples and maintaining READMEs.

## Purpose

Normalize example structure and design, explain how examples act as both
user-facing documentation and test assets, and define how documentation
automation (including READMEs and terraform-docs) fits into the workflow.

## Example Design Principles

- Examples should be composed from existing internal modules where possible.
- Avoid redefining raw resources when a suitable internal module exists.
- Use examples to demonstrate realistic, secure scenarios with minimal inputs.
- Keep examples copy-paste friendly and aligned with repository naming and
  tagging conventions.
- Keep defaults environment-agnostic (no hard-coded account IDs, regions, or
  environment names).

Examples are consumed both by readers and by automation:

- As documentation: they show how to use a module safely and idiomatically.
- As test inputs: they are used by `scripts/test.sh` and CI to validate modules.
  See `09-testing-and-ci.md` for the testing workflow.

## Example Creation Workflow

1. Understand the primary module and scenario to demonstrate.
2. Identify required supporting building blocks (networking, security, IAM,
   storage, etc.).
3. Search the `modules/` directory for existing modules and prefer them over raw
   resources.
4. Read each candidate module README to confirm scope, inputs, outputs, and
   constraints.
5. Compose the example primarily from internal modules. Keep inputs minimal and
   secure.
6. If a needed capability has no suitable internal module, use raw resources as
   a temporary fallback and propose a new module to fill the gap.

## Mandatory Behaviors

When creating or updating examples, the following are required:

- Always search for and prefer existing modules in this repository for
  supporting capabilities.
- Always read the module README for any module used in an example to confirm
  scope and inputs.
- Avoid duplicating functionality that already exists as a module.
- Keep example wiring explicit and understandable; the primary module should be
  central and visible.
- If no suitable module exists for a needed capability, use a minimal
  raw-resource fallback and propose a new module to replace it later. Include a
  suggested module name and scope and note that it should follow the standard
  module creation workflow.
- Follow repository conventions: module directories use kebab-case, variables
  and outputs use snake_case, child modules do not declare provider blocks, and
  versions are pinned to stable minimums.
- Defaults must favor least privilege, encryption at rest and in transit, and
  no public exposure.

## Root Module Example Requirements

- Root module examples must wire child modules from `modules/` using relative
  sources.
- Examples must demonstrate the expected tag and naming propagation.
- Examples must show network boundaries and logging destinations when the
  module exposes them.

Security baseline and naming/tagging rules are defined in
`08-security-naming-and-tagging.md`.

## Runtime Examples (Required Defaults)

When an example needs runtime code and the user has not provided any, use the
following defaults.

### Lambda (Node.js)

Use this handler for smoke tests and validation only. Configure the runtime to a
current Node.js version (for example, Node.js 20) and set the handler to
`index.handler` when the file is named `index.js`.

```js
exports.handler = async (event) => {
  console.log(JSON.stringify({ message: "lambda invoked", event }));
  return {
    statusCode: 200,
    body: JSON.stringify({ ok: true })
  };
};
```

### EC2 (User Data with Nginx)

Use this user data to install Nginx and display the instance's current local IP
on the default page. This is intended for basic validation examples only.

```bash
#!/usr/bin/env bash
set -euo pipefail

if command -v apt-get >/dev/null 2>&1; then
  apt-get update -y
  apt-get install -y nginx curl
else
  yum install -y nginx curl
fi

# IMDSv2 token for metadata access
TOKEN="$(curl -sX PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")"
LOCAL_IP="$(curl -sH "X-aws-ec2-metadata-token: ${TOKEN}" http://169.254.169.254/latest/meta-data/local-ipv4)"

cat > /usr/share/nginx/html/index.html <<EOF_HTML
<html>
  <head><title>Instance Info</title></head>
  <body>
    <h1>Nginx is running</h1>
    <p>Local IP: ${LOCAL_IP}</p>
  </body>
</html>
EOF_HTML

systemctl enable nginx
systemctl restart nginx
```

## Additional Runtime Templates (Document Only)

Maintain guidance for these standard templates, but do not embed code in this
guide unless explicitly requested:

- ECS/Fargate: minimal container healthcheck and logging configuration
  expectations.
- EKS/Kubernetes: minimal deployment and service manifest expectations with
  probes.
- Lambda (Python): minimal handler expectations and packaging notes.
- CloudWatch Synthetics: canary structure and artifact locations.
- API Gateway: basic integration mapping and request/response shape
  expectations.
- Step Functions: simple state machine structure and IAM permissions
  checklist.
- SQS/SNS: standard message attribute conventions and DLQ wiring
  expectations.
- ALB/NLB: listener and target group baseline with TLS and health checks.
- RDS/Aurora: parameter group defaults, encryption, backups, and subnet group
  wiring.
- S3: bucket policy baseline, public access blocks, and encryption defaults.
- IAM Roles: trust policy baseline and least-privilege policy scoping
  guidance.

## Related Guides

- `01-overview-and-lifecycle.md` — documentation map and lifecycle overview.
- `02-module-creation-and-fundamentals.md` — when to create vs extend modules.
- `03-module-structure-and-layout.md` — required layout and structure.
- `04-module-interfaces-and-arguments.md` — variables, validation, outputs.
- `05-infrastructure-architecture-guidelines.md` — architecture baseline.
- `06-sources-and-distribution.md` — versioning and upgrade guidance.
- `07-composition-and-patterns.md` — composition patterns and dependency wiring.
- `08-security-naming-and-tagging.md` — security and tagging baseline.
- `09-testing-and-ci.md` — validation workflow and CI gates.
