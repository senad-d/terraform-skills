# Terraform Skills

Skill bundle for [CODEX CLI](https://github.com/topics/codex-cli) that packages five Terraform workflows: bootstrap a reusable memory bank, plan changes, create child modules, compose root modules, and run evidence-based reviews. Each skill comes with strict gates, templates, and scripts that drive consistent planning, validation, and documentation. The benefit is faster, more reliable Terraform AWS delivery with shared context and guardrails that reduce rework and keep standards consistent across teams.

```mermaid
flowchart LR
    %% TF skills memory bank workflow

    A([Repo]) --> B[Bootstrap shared memory]
    A --> P[Plan Terraform work]
    A --> R[Review Terraform code]
    B --> C[Create reusable modules]
    C --> D[Create root modules]

    subgraph TF Module Skills
        C
        D
    end

    subgraph TF Planning Skill
        P
        R
    end

    MB((Shared memory bank and rules))

    B --> MB
    C --> MB
    D --> MB
    P -. optional .-> C
    P -. optional .-> D

```

## Features

- **MCP-aware Terraform workspace**  
  Use Model Context Protocol (MCP) servers to stream in AWS, Terraform, and code-search context directly into your CODEX tasks.

- **Persistent memory bank**  
  One-time bootstrap initializes a `memory-bank/` directory with agents and project-specific context so future tasks can reuse past plans, decisions, and constraints.

- **Terraform child module workflows**  
  Guided flows for planning, scaffolding, testing, and documenting Terraform AWS child modules, aligned with the popular `terraform-aws-modules` conventions.

- **Terraform root module workflows**  
  Standards and scripts for planning, composing, validating, and documenting Terraform root modules that integrate child modules with secure defaults.

- **Terraform planning workflows**  
  Structured planning for new modules, edits, or AWS architecture changes without touching code, with clear inputs and plan outputs.

- **Terraform review workflows**  
  Structured Terraform code review guidance focused on security, reliability, cost, and correctness with strict evidence requirements.

- **Ready-to-run scripts**  
  Shell scripts for creating modules, examples, plans, tests, and documentation so you can focus on design and correctness instead of boilerplate.

- **Opinionated, repeatable process**  
  Encourages consistent patterns across modules (structure, interfaces, testing, docs) that are easy to scale across teams.

## Repository Structure

This repository contains multiple skills that are meant to be used together as a bundle:

- [`memory-bank-bootstrap`](memory-bank-bootstrap/SKILL.md)  
  Bootstrap scripts and agent definitions for creating and maintaining a project-specific memory bank. This seeds the workspace with context that CODEX can reuse across all Terraform module tasks.
  - Key files:
    - [`memory-bank-bootstrap/SKILL.md`](memory-bank-bootstrap/SKILL.md) – high-level description of the skill
    - [`memory-bank-bootstrap/scripts/create-memory.sh`](memory-bank-bootstrap/scripts/create-memory.sh) – initializes the memory bank for this repo
    - [`memory-bank-bootstrap/scripts/add-agents.sh`](memory-bank-bootstrap/scripts/add-agents.sh) – registers AGENTS rules for this project

- [`tf-child-modules`](tf-child-modules/SKILL.md)  
  Opinionated workflows and scripts that help you plan, scaffold, test, and document Terraform AWS child modules.
  - Key files:
    - [`tf-child-modules/SKILL.md`](tf-child-modules/SKILL.md) – skill overview and usage details
    - [`tf-child-modules/references/`](tf-child-modules/references/) – reference docs on module lifecycle, structure, testing, versioning, etc.
    - [`tf-child-modules/scripts/create-module.sh`](tf-child-modules/scripts/create-module.sh) – scaffold a new module
    - [`tf-child-modules/scripts/create-examples.sh`](tf-child-modules/scripts/create-examples.sh) – generate examples for a module
    - [`tf-child-modules/scripts/create-documentation.sh`](tf-child-modules/scripts/create-documentation.sh) – generate documentation
    - [`tf-child-modules/scripts/test-module.sh`](tf-child-modules/scripts/test-module.sh) – run tests for a module

- [`tf-root-module`](tf-root-module/SKILL.md)  
  Standards and scripts for planning, composing, validating, and documenting Terraform root modules that integrate child modules with secure defaults.
  - Key files:
    - [`tf-root-module/SKILL.md`](tf-root-module/SKILL.md) – skill overview and usage details
    - [`tf-root-module/references/`](tf-root-module/references/) – reference docs on root module design, structure, and testing
    - [`tf-root-module/scripts/root-module.sh`](tf-root-module/scripts/root-module.sh) – scaffold a new root module
    - [`tf-root-module/scripts/plan.sh`](tf-root-module/scripts/plan.sh) – create a required change plan
    - [`tf-root-module/scripts/test.sh`](tf-root-module/scripts/test.sh) – test root module examples

- [`tf-review`](tf-review/SKILL.md)  
  Structured workflows and references for Terraform module reviews with strict evidence and remediation guidance.
  - Key files:
    - [`tf-review/SKILL.md`](tf-review/SKILL.md) – skill overview and usage details
    - [`tf-review/references/`](tf-review/references/) – review lifecycle, methodology, remediation, and investigation guides
    - [`tf-review/scripts/review.sh`](tf-review/scripts/review.sh) – generate a review template
    - [`tf-review/scripts/plan.sh`](tf-review/scripts/plan.sh) – create a required review plan
    - [`tf-review/scripts/find.sh`](tf-review/scripts/find.sh) – locate module directories for review

- [`tf-plan`](tf-plan/SKILL.md)  
  Planning workflows for Terraform module changes or AWS architecture updates without changing code.
  - Key files:
    - [`tf-plan/SKILL.md`](tf-plan/SKILL.md) – skill overview and usage details
    - [`tf-plan/references/`](tf-plan/references/) – planning guides, methodology, and architecture references
    - [`tf-plan/scripts/find.sh`](tf-plan/scripts/find.sh) – locate modules for planning context
    - [`tf-plan/scripts/read.sh`](tf-plan/scripts/read.sh) – read files into planning context
    - [`tf-plan/scripts/plan.sh`](tf-plan/scripts/plan.sh) – create a plan output

The top-level [`LICENSE`](LICENSE) applies to the content in this repository.

## Prerequisites

Before using these skills, ensure you have:

- **Terraform** (compatible with the AWS modules you intend to use)
- **AWS account** with credentials configured locally (e.g., via `aws configure` or environment variables)
- **CODEX CLI** installed and available on your `PATH`
- **MCP-capable environment** (CODEX configured to talk to MCP servers)
- **Tooling** installed `tflint`, `tfsec`, `rg`, `yq` (It is optional, but it is recommended to use loclastack.)

You should be comfortable with:

- Basic Terraform usage (init/plan/apply)
- AWS IAM and resource management
- Running shell scripts on your platform (macOS, Linux, or WSL)

## Installation

### Obtain this skill bundle

Clone this repository into a location where you manage your CODEX skills:

```bash
git clone https://github.com/senad-d/terraform-skills.git 

cd terraform-skills && [ -d "$HOME/.codex" ] && \
cp -R memory-bank-bootstrap tf-child-modules tf-root-module tf-plan "$HOME/.codex"/ || echo '$HOME/.codex does not exist'
```

To include the review skill as well:

```bash
cp -R memory-bank-bootstrap tf-child-modules tf-root-module tf-review tf-plan "$HOME/.codex"/ || echo '$HOME/.codex does not exist'
```

## Configuration

To get the most out of this bundle, configure your tooling and CODEX MCP servers so tasks can leverage rich context.

### Recommended tools

- Localstack for testing:

```bash
docker run \
  --rm -it \
  -p 127.0.0.1:4566:4566 \
  -p 127.0.0.1:4510-4559:4510-4559 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  localstack/localstack
```

- AWS credentials:

```bash
[localstack]
region = us-east-1
output = json
aws_access_key_id = AKIATESTKEY1234567890
aws_secret_access_key = ABCDEFGHIJKLMNOPQRSTUVWX
endpoint_url = http://localhost:4566
```

### Recommended MCP servers

- **terraform-mcp-server** – Terraform-specific knowledge and helpers: <https://github.com/hashicorp/terraform-mcp-server>
- **aws-knowledge-mcp-server** – AWS documentation and service knowledge: <https://awslabs.github.io/mcp/servers/aws-knowledge-mcp-server/>

### Example CODEX MCP configuration

Add the following MCP configuration to your CODEX CLI configuration file (commonly `config.toml`):

```toml
[mcp_servers.terraform-mcp-server]
command = "uvx"
args = ["awslabs.terraform-mcp-server@latest"]
startup_timeout_sec = 20.0

[mcp_servers.aws-knowledge-mcp-server]
command = "uvx"
args = ["fastmcp", "run", "https://knowledge-mcp.global.api.aws"]
```

Notes:

- Ensure `npx` and `uvx` (from [uv](https://github.com/astral-sh/uv)) are available on your `PATH`.
- Restart CODEX CLI or reload its configuration after updating the file.

## Usage

Typical workflow for a new Terraform/AWS module project:

### 1. Bootstrap the memory bank

Run the memory bank bootstrap skill once per repository/workspace to seed project-specific context.

```bash
$memory-bank-bootstrap
```

This sets up the `memory-bank/` directory and AGENTS rules that CODEX can reuse across subsequent tasks.

After the memory bank is created, a `Rules/` directory is added at the root of this repository. The skills automatically read any files in this directory as additional, project-specific rules, in addition to the default rules they ship with.

> Note: The memory bank is optional, but recommended for larger projects.

> Recommendation: To ensure the memory bank is used, start your prompt with `new task ->`.

### 2. Create Terraform AWS child modules

Use the `tf-child-modules` skill to plan, scaffold, and refine child modules. For example, in CODEX you might start a task like:

```text
Create aws module for vpc using $tf-child-modules
```

These workflows encourage consistent module structure, testing, and documentation aligned with `terraform-aws-modules` best practices.

### 3. Compose Terraform root modules

Use the `tf-root-module` skill to plan and assemble root modules that compose multiple child modules. For example:

```text
Create module for shared networking using $tf-root-module
```

### 4. Plan Terraform work

Use the `tf-plan` skill to create a structured plan for new modules, edits, or architecture updates without changing code. For example:

```text
$tf-plan
```

### 5. Iterate with memory-backed context

As you create modules, the memory bank accumulates:

- Architectural decisions
- Constraints and non-functional requirements
- Naming and tagging conventions
- Testing and rollout strategies

Subsequent CODEX tasks (for example, refactoring an existing module or adding a new one) can reuse this context automatically, reducing duplication and helping maintain consistency across your Terraform codebase.

### 6. Perform Terraform reviews

Use the `tf-review` skill to run structured reviews that require evidence and remediation steps. For example:

```text
Review module for iam policies using $tf-review
```

## Contributing

Contributions are welcome. Common contribution paths include:

- Improving documentation and examples
- Adding new workflows or scripts for common Terraform/AWS patterns
- Enhancing support for additional MCP servers or context sources

Please open an issue or pull request in this repository with a clear description of the change and rationale.

## License

This project is licensed under the terms described in [`LICENSE`](LICENSE).
