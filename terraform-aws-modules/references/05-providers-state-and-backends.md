---
page_title: Providers, State, and Backends
description: >-
  Defines how modules in this repo declare providers and backends, manage remote state, and support multi-account and aliased provider scenarios.
---

# Providers, State, and Backends

## Audience
Engineers responsible for provider configuration, state topology, and multi-account patterns.

## Purpose
Centralize provider usage rules, backend conventions, and state layout patterns for modules in this repository.

## Provider Rules
- Provider configurations are global to a Terraform configuration and must be defined only in the root module.
- Reusable modules must not contain `provider` blocks. They should only declare provider requirements in `required_providers`.
- Each module must declare its own provider requirements in `versions.tf`.
- Removing a provider configuration before all resources using it are destroyed will cause planning errors because state still references that configuration.

### Required Providers in Modules
Declare provider requirements in a `terraform` block inside `versions.tf` at the root of each module (including nested modules under `modules/`).

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
If a module needs multiple provider configurations, declare `configuration_aliases` and use explicit provider mapping in the calling module.

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
- Aliased provider configurations are never inherited and must be passed via the `providers` map in the `module` block.

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
- Remote state must be stored in S3 with DynamoDB locking.
- State keys must match folder structure and be environment-prefixed.
- Preferred bucket and table naming pattern: `${owner}-${env}-tf-state` and `${owner}-${env}-tf-locks`.
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

## Remote State Wiring
Reference other stacks in this repo via `terraform_remote_state`; avoid hardcoded ARNs. For external or AWS-managed resources, prefer data sources.

## Multi-Account Providers
Use aliased providers with `assume_role` to operate in member accounts.

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

## Related Guides
- `07-composition-and-patterns.md` for how state layout impacts composition.
- `11-versioning-refactors-and-upgrades.md` for refactor and state-migration considerations.

