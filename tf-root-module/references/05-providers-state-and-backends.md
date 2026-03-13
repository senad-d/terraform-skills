---
page_title: Providers, State, Backends, and Environments
description: >-
  Defines how modules in this repo declare providers and backends, manage remote
  state, and support multi-account and multi-environment provider configurations.
---

# Providers, State, Backends, and Environments

## Audience
Engineers responsible for provider configuration, state topology, and
multi-account or multi-environment patterns.

## Purpose
Centralize provider usage rules, backend conventions, and state layout patterns
for modules in this repository, including how they are applied across accounts
and environments.

## Provider Rules
- Provider configurations are global to a Terraform configuration and must be
  defined only in the root module.
- Reusable modules must not contain `provider` blocks. They should only declare
  provider requirements in `required_providers`.
- Each module must declare its own provider requirements in `versions.tf`.
- Removing a provider configuration before all resources using it are destroyed
  will cause planning errors because state still references that configuration.

### Required Providers in Modules
Declare provider requirements in a `terraform` block inside `versions.tf` at the
root of each module (including nested modules under `modules/`).

Example:
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.7.0"
    }
  }
}
```

### Provider Aliases
If a module needs multiple provider configurations, declare
`configuration_aliases` and use explicit provider mapping in the calling module.

Example:
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.7.0"
      configuration_aliases = [aws.src, aws.dst]
    }
  }
}
```

### Implicit Inheritance vs Explicit Passing
- Default provider configurations are inherited by child modules.
- Aliased provider configurations are never inherited and must be passed via
the `providers` map in the `module` block.

Example:
```hcl
provider "aws" {
  region = "us-west-1"
}

provider "aws" {
  alias  = "usw2"
  region = "us-west-2"
}

module "example" {
  source = "./example"
  providers = {
    aws = aws.usw2
  }
}
```

## Remote State and Backends
Remote state and backend configuration must follow shared conventions so
multi-environment and multi-account usage remains predictable.

- Remote state must be stored in S3 with DynamoDB locking.
- State keys must match folder structure and be environment-prefixed.
- Preferred bucket and table naming pattern: `${owner}-${env}-tf-state` and
  `${owner}-${env}-tf-locks`.
- Enable S3 versioning and server-side encryption (SSE-KMS preferred).

Backend config fields: `bucket`, `key`, `region`, `encrypt`, `dynamodb_table`.

Example backend variables:
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
`07-composition-patterns-and-root-module-design.md` for composition guidance.

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
the baseline in `08-security-naming-and-tagging-guidelines.md`.

## Security Considerations for Providers and State
Provider and backend configuration is security-sensitive:
- Ensure provider credentials are short-lived where possible and not embedded in
  configuration files.
- Restrict access to state buckets and lock tables to the minimal set of
  principals.
- Treat state files as sensitive; they may contain resource identifiers and
  embedded data.

For the full security baseline, naming conventions, and tagging requirements,
see `08-security-naming-and-tagging-guidelines.md`.

## Related Guides
- `07-composition-patterns-and-root-module-design.md` for how state layout
  impacts composition.
- `06-module-distribution-versioning-and-upgrades.md` for refactor and
  state-migration considerations.
- `08-security-naming-and-tagging-guidelines.md` for repository-wide security,
  naming, and tagging policy.
