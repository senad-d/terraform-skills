---
page_title: Module Sources and Distribution
description: >-
  Defines how to use the module source argument, when to use local paths vs registries, and how modules are versioned and distributed internally and externally.
---

# Module Sources and Distribution

## Audience
Engineers composing stacks from modules and deciding how to distribute modules.

## Purpose
Normalize guidance on the `source` argument, registry usage, and internal module distribution.

## Source Selection Guidance
- Use local relative paths (`./` or `../`) for closely related modules within the same repository.
- Use a Terraform module registry for modules intended to be shared across multiple configurations.
- Avoid absolute filesystem paths because they are treated like remote packages and couple configs to a specific machine layout.

## Supported Source Types
Terraform supports the following source types:
- Local paths
- Terraform Registry (public and private)
- GitHub
- Bitbucket
- Generic Git repositories (`git::` prefix)
- Generic Mercurial repositories (`hg::` prefix)
- HTTP URLs (archive downloads)
- S3 buckets (`s3::` prefix)
- GCS buckets (`gcs::` prefix)
- Modules in package subdirectories (`//` syntax)

## Local Paths
Local paths allow factoring within the same repository.

Example:
```hcl
module "consul" {
  source = "./consul"
}
```

A local path must begin with `./` or `../`. Absolute filesystem paths are treated as remote packages and are not recommended.

## Terraform Registry
Registry sources are the preferred distribution mechanism for reusable modules. The standard format is `<NAMESPACE>/<NAME>/<PROVIDER>`.

Example:
```hcl
module "consul" {
  source  = "hashicorp/consul/aws"
  version = "0.1.0"
}
```

Private registries use a hostname prefix:
```hcl
module "consul" {
  source  = "app.terraform.io/example-corp/k8s-cluster/azurerm"
  version = "1.1.0"
}
```

Registry modules support version constraints and require appropriate credentials for private registries.

## GitHub
GitHub shorthand is supported:
```hcl
module "consul" {
  source = "github.com/hashicorp/example"
}
```

To use SSH:
```hcl
module "consul" {
  source = "git@github.com:hashicorp/example.git"
}
```

## Bitbucket
Bitbucket shorthand is supported for public repositories:
```hcl
module "consul" {
  source = "bitbucket.org/hashicorp/terraform-consul-aws"
}
```

Terraform auto-detects Git vs Mercurial for Bitbucket repositories.

## Generic Git Repository
Use `git::` to specify any Git URL and `ref` to pin a revision:
```hcl
module "vpc" {
  source = "git::https://example.com/vpc.git?ref=v1.2.0"
}
```

`ref` may be a branch, tag, or commit SHA.

## Generic Mercurial Repository
Use `hg::` with `ref` to select revisions:
```hcl
module "vpc" {
  source = "hg::http://example.com/vpc.hg?ref=v1.2.0"
}
```

## S3 Bucket
Use `s3::` with an S3 object URL:
```hcl
module "consul" {
  source = "s3::https://s3-eu-west-1.amazonaws.com/examplecorp-terraform-modules/vpc.zip"
}
```

Note: Buckets in `us-east-1` must use `s3.amazonaws.com` as the hostname.

## GCS Bucket
Use `gcs::` with a GCS object URL:
```hcl
module "consul" {
  source = "gcs::https://www.googleapis.com/storage/v1/modules/foomodule.zip"
}
```

## Modules in Package Subdirectories
If a module lives in a subdirectory of a package, use the `//` syntax:
```hcl
module "vpc" {
  source = "git::https://example.com/network.git//modules/vpc?ref=v1.2.0"
}
```

The module installer downloads the entire package but reads the module from the subdirectory. Submodules can safely use local paths to other modules in the same package.

## Related Guides
- `10-examples-and-docs-automation.md` for example-specific source guidance.
- `11-versioning-refactors-and-upgrades.md` for versioning policy and upgrade strategy.

