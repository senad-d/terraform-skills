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
  `05-providers-state-and-backends.md`).
- Composing reusable modules into a coherent topology.
- Supplying environment- and account-specific values to child modules.
- Wiring data-only modules and remote state to share information between stacks.

Root modules should avoid embedding complex, reusable logic that would be better
served as a dedicated module. When a root module’s internal wiring becomes
repetitive across stacks, extract a reusable module and keep the root focused on
composition.

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

## Assumptions and Guarantees
Every module has assumptions and guarantees. Use validations or preconditions to
document and enforce them so consumers understand expectations and failures
earlier.

Definitions:
- Assumption: A condition that must be true for the module to operate correctly.
- Guarantee: A behavior or characteristic the module ensures for its consumers.

Example:
```hcl
output "api_base_url" {
  value = "https://${aws_instance.example.private_dns}:8433/"

  precondition {
    condition     = data.aws_ebs_volume.example.encrypted
    error_message = "The server's root volume is not encrypted."
  }
}
```

Interface-level validation and output design guidelines are covered in
`04-module-interfaces-and-arguments.md`.

## Multi-Cloud Abstractions
Terraform does not abstract across providers, but you can build lightweight
multi-cloud abstractions by defining common object types and module interfaces
that map to different providers.

Example:
```hcl
variable "recordsets" {
  type = list(object({
    name    = string
    type    = string
    ttl     = number
    records = list(string)
  }))
}
```

You can then implement provider-specific modules that accept the same
`recordsets` input, allowing you to swap the underlying provider implementation
with minimal change to higher-level modules.

Example pattern:
```hcl
module "dns_records" {
  source = "./modules/route53-dns-records"
  recordsets = local.recordsets
}
```

If you later switch providers, implement a new module with the same input shape
and update only the module source.

### Example: DNS Recordsets Composition
```hcl
locals {
  fixed_recordsets = [
    {
      name = "www"
      type = "CNAME"
      ttl  = 3600
      records = [
        "webserver01",
        "webserver02",
        "webserver03",
      ]
    },
  ]
  server_recordsets = [
    for i, addr in module.webserver.public_ip_addrs : {
      name    = format("webserver%02d", i)
      type    = "A"
      records = [addr]
    }
  ]
  recordsets = concat(local.fixed_recordsets, local.server_recordsets)
}

module "dns_records" {
  source       = "./modules/route53-dns-records"
  recordsets   = local.recordsets
  route53_zone_id = var.route53_zone_id
}
```

This pattern keeps DNS logic stable while allowing the DNS provider
implementation to change.

### Example: Interchangeable Kubernetes Modules
```hcl
module "k8s_cluster" {
  source = "./modules/azurerm-k8s-cluster"
}

module "monitoring_tools" {
  source           = "./modules/monitoring_tools"
  cluster_hostname = module.k8s_cluster.hostname
}
```

If you implement a different cluster module that exposes the same `hostname`
output, the monitoring module can remain unchanged.

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
stacks in this repo and data sources for external or AWS-managed resources. See
`05-providers-state-and-backends.md` for remote state conventions.

Common retrieval patterns:
- AWS data sources such as `aws_vpc` and `aws_subnet_ids`.
- External system data sources such as `consul_keys` when configuration data is
  stored in Consul.
- `terraform_remote_state` outputs from the stack that owns the shared
  infrastructure.

When a data-only module is designed to mirror the outputs of a managed module,
you can swap between the two during refactors with minimal changes to callers.

## Related Guides
- `04-module-interfaces-and-arguments.md` for input and output design
  patterns.
- `05-providers-state-and-backends.md` for provider and state layout rules.
- `02-module-creation-and-fundamentals.md` for when composition justifies a new
  module.
- `08-security-naming-and-tagging.md` for security and tagging
  considerations that apply to composed stacks.
