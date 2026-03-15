---
page_title: Composition Patterns and Root Module Design
description: >-
  Defines how to compose modules into larger systems, design root modules from a
  consumer perspective, enforce shallow hierarchies, and use data-only modules
  and remote state for wiring.
---

# Composition Patterns and Root Module Design

## Audience

Engineers designing larger systems by composing modules and shaping root modules
for specific stacks or environments.

## Purpose

Capture composition patterns, flat hierarchy rules, data-only module usage, and
root module responsibilities from a consumer perspective.

## Root Module Responsibilities

Root modules represent concrete stacks or environments. They are responsible for:

- Configuring providers and backends (see
  `05-infrastructure-architecture-guidelines.md`).
- Composing reusable modules into a coherent topology.
- Supplying environment- and account-specific values to child modules.
- Wiring data-only modules and remote state to share information between stacks.

Root modules should avoid embedding complex, reusable logic that would be better
served as a dedicated module. When a root module’s internal wiring becomes
repetitive across stacks, extract a reusable module and keep the root focused on
composition.

## Infrastructure Architecture Flow

- Start with network boundaries (VPC, subnets, routing) and attach security
  controls.
- Choose compute and orchestration, then wire services through explicit
  inputs/outputs.
- Place shared dependencies behind module interfaces and pass them in.
- Add logging and monitoring wiring as first-class module outputs and inputs.

## Flat Composition

Prefer a flat module tree with a single level of child modules. Compose modules
in the root module by passing outputs from one module into inputs of another.

Example:

```hcl
module "network" {
  source = "./modules/aws-network"
  base_cidr_block = "10.0.0.0/8"
}

module "consul_cluster" {
  source = "./modules/aws-consul-cluster"
  vpc_id     = module.network.vpc_id
  subnet_ids = module.network.subnet_ids
}
```

This keeps modules small and reusable and avoids deep module trees.

## Dependency Inversion

Pass dependencies into modules rather than having modules create their own
supporting infrastructure. This improves flexibility and allows refactors where
dependencies are satisfied via data sources instead of managed resources.

Example:

```hcl
data "aws_vpc" "main" {
  tags = { Environment = "production" }
}

data "aws_subnet_ids" "main" {
  vpc_id = data.aws_vpc.main.id
}

module "consul_cluster" {
  source     = "./modules/aws-consul-cluster"
  vpc_id     = data.aws_vpc.main.id
  subnet_ids = data.aws_subnet_ids.main.ids
}
```

Why this matters:

- Modules that accept dependencies can be reused in different topologies.
- Refactors can swap resource creation for data lookups without changing the
  module interface.
- It becomes easier for multiple systems to share common infrastructure without
  forcing a specific topology.

## Conditional Creation Through Inputs

Avoid complex conditional branches inside modules. Accept inputs that can be
sourced either from resources or data sources and let the caller decide what
exists.

Example pattern:

- Define an input object with only the attributes the module needs.
- Allow the caller to pass either a managed resource or a data source that
  matches that shape.

```hcl
variable "ami" {
  type = object({
    id           = string
    architecture = string
  })
}
```

Caller examples:

```hcl
# Managed resource
resource "aws_ami_copy" "example" {
  name              = "local-copy-of-ami"
  source_ami_id     = "ami-abc123"
  source_ami_region = "eu-west-1"
}

module "example" {
  source = "./modules/example"
  ami    = aws_ami_copy.example
}
```

```hcl
# Data source
data "aws_ami" "example" {
  owner = "9999933333"
  tags = {
    application = "example-app"
    environment = "dev"
  }
}

module "example" {
  source = "./modules/example"
  ami    = data.aws_ami.example
}
```

This keeps the module declarative and makes it clear which environments create
infrastructure and which reuse existing assets.

## Child Module Wiring Checklist

- Pass outputs from one child module directly into inputs of the next.
- Avoid re-creating shared infrastructure in multiple child modules.
- Keep module trees shallow and avoid nested child modules unless required.
- Use data sources or `terraform_remote_state` for external dependencies.

## Data-Only Modules

Data-only modules retrieve information about existing infrastructure without
creating resources. Use them when they raise the level of abstraction by
encapsulating how data is retrieved.

Example:

```hcl
module "network" {
  source = "./modules/join-network-aws"
  environment = "production"
}

module "k8s_cluster" {
  source     = "./modules/aws-k8s-cluster"
  subnet_ids = module.network.aws_subnet_ids
}
```

Data-only modules may use provider data sources or `terraform_remote_state` to
retrieve shared information. Prefer `terraform_remote_state` for wiring internal
stacks in this repo and data sources for external or AWS-managed resources.

Common retrieval patterns:

- AWS data sources such as `aws_vpc` and `aws_subnet_ids`.
- External system data sources such as `consul_keys` when configuration data is
  stored in Consul.
- `terraform_remote_state` outputs from the stack that owns the shared
  infrastructure.

When a data-only module is designed to mirror the outputs of a managed module,
you can swap between the two during refactors with minimal changes to callers.

## Related Guides

- `01-overview-and-lifecycle.md` — documentation map and lifecycle overview.
- `02-module-creation-and-fundamentals.md` — when to create vs extend modules.
- `03-module-structure-and-layout.md` — required layout and structure.
- `04-module-interfaces-and-arguments.md` — variables, validation, outputs.
- `05-infrastructure-architecture-guidelines.md` — architecture baseline.
- `06-sources-and-distribution.md` — versioning and upgrade guidance.
- `08-security-naming-and-tagging.md` — security and tagging baseline.
- `09-testing-and-ci.md` — validation workflow and CI gates.
- `10-examples.md` — examples and documentation expectations.
