# Terraform Skills for CODEX CLI

Skill bundle for [CODEX CLI](https://github.com/topics/codex-cli) that turns a blank Terraform/AWS repository into a guided, MCP-aware workspace. It provides a reusable memory bank, opinionated workflows, and ready-to-run scripts for designing, testing, and documenting high-quality Terraform AWS modules with minimal boilerplate.

## Features

- **MCP-aware Terraform workspace**  
  Use Model Context Protocol (MCP) servers to stream in AWS, Terraform, and code-search context directly into your CODEX tasks.

- **Persistent memory bank**  
  One-time bootstrap initializes a `memory-bank/` directory with agents and project-specific context so future tasks can reuse past plans, decisions, and constraints.

- **Terraform AWS module workflows**  
  Guided flows for planning, scaffolding, testing, and documenting Terraform AWS modules, aligned with the popular `terraform-aws-modules` conventions.

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

- [`terraform-aws-modules`](terraform-aws-modules/SKILL.md)  
  Opinionated workflows and scripts that help you plan, scaffold, test, and document Terraform AWS modules.
  - Key files:
    - [`terraform-aws-modules/SKILL.md`](terraform-aws-modules/SKILL.md) – skill overview and usage details
    - [`terraform-aws-modules/references/`](terraform-aws-modules/references/) – reference docs on module lifecycle, structure, testing, versioning, etc.
    - [`terraform-aws-modules/scripts/create-module.sh`](terraform-aws-modules/scripts/create-module.sh) – scaffold a new module
    - [`terraform-aws-modules/scripts/create-examples.sh`](terraform-aws-modules/scripts/create-examples.sh) – generate examples for a module
    - [`terraform-aws-modules/scripts/create-documentation.sh`](terraform-aws-modules/scripts/create-documentation.sh) – generate documentation
    - [`terraform-aws-modules/scripts/test-module.sh`](terraform-aws-modules/scripts/test-module.sh) – run tests for a module

The top-level [`LICENSE`](LICENSE) applies to the content in this repository.


## Prerequisites

Before using these skills, ensure you have:

- **Terraform** (compatible with the AWS modules you intend to use)
- **AWS account** with credentials configured locally (e.g., via `aws configure` or environment variables)
- **CODEX CLI** installed and available on your `PATH`
- **MCP-capable environment** (CODEX configured to talk to MCP servers)

You should be comfortable with:

- Basic Terraform usage (init/plan/apply)
- AWS IAM and resource management
- Running shell scripts on your platform (macOS, Linux, or WSL)


## Installation

### 1. Install CODEX CLI

Follow the official CODEX CLI installation documentation for your platform and verify it is available:

```bash
codex --help
```

If the command prints help output, CODEX is correctly installed and on your `PATH`.

### 2. Obtain this skill bundle

Clone this repository into a location where you manage your CODEX skills:

```bash
git clone https://github.com/senad-d/terraform-skills.git && \
cd terraform-skills && \
[ -d "$HOME/.codex" ] && \
cp -R memory-bank-bootstrap terraform-aws-modules "$HOME/.codex"/ || echo 'Error: $HOME/.codex does not exist or clone failed'
```

### 3. Register the skills with CODEX

Follow the CODEX CLI documentation for registering local skills. In most setups, you will:

- Point CODEX to this repository as a skill bundle
- Reference the skills by name (for example, `$memory-bank-bootstrap` and `$terraform-aws-modules`) in your tasks

Refer to [`memory-bank-bootstrap/SKILL.md`](memory-bank-bootstrap/SKILL.md) and [`terraform-aws-modules/SKILL.md`](terraform-aws-modules/SKILL.md) for skill-specific integration details.


## Configuration

To get the most out of this bundle, configure your CODEX MCP servers so tasks can leverage rich context from AWS, Terraform, and external documentation.

### Recommended MCP servers

- **context7** – general-purpose context and code search: <https://context7.com/>
- **terraform-mcp-server** – Terraform-specific knowledge and helpers: <https://github.com/hashicorp/terraform-mcp-server>
- **aws-knowledge-mcp-server** – AWS documentation and service knowledge: <https://awslabs.github.io/mcp/servers/aws-knowledge-mcp-server/>

### Example CODEX MCP configuration

Add the following MCP configuration to your CODEX CLI configuration file (commonly `config.toml`):

```toml
[mcp_servers.context7]
command = "npx"
args = ["-y", "@upstash/context7-mcp", "--api-key", "API_KEY_HERE"]
startup_timeout_sec = 20.0

[mcp_servers.terraform-mcp-server]
command = "uvx"
args = ["awslabs.terraform-mcp-server@latest"]
startup_timeout_sec = 20.0

[mcp_servers.aws-knowledge-mcp-server]
command = "uvx"
args = ["fastmcp", "run", "https://knowledge-mcp.global.api.aws"]
```

Notes:

- Replace `API_KEY_HERE` with your actual Context7 API key.
- Ensure `npx` and `uvx` (from [uv](https://github.com/astral-sh/uv)) are available on your `PATH`.
- Restart CODEX CLI or reload its configuration after updating the file.


## Usage

Typical workflow for a new Terraform/AWS module project:

### 1. Bootstrap the memory bank

Run the memory bank bootstrap skill once per repository/workspace to seed project-specific context.

```bash
codex
```
Use skill: `$memory-bank-bootstrap`

This sets up the `memory-bank/` directory and AGENTS rules that CODEX can reuse across subsequent tasks.

After the memory bank is created, a `Rules/` directory is added at the root of this repository. The `$terraform-aws-modules` skill automatically reads any files in this directory as additional, project-specific rules, in addition to the default rules it ships with.

### 2. Create and evolve Terraform AWS modules

Use the `terraform-aws-modules` skill to plan, scaffold, and refine modules. For example, in CODEX you might start a task like:

```text
new task -> create aws module for cloud-map using $terraform-aws-modules
```

Behind the scenes, CODEX can leverage scripts such as:

- [`terraform-aws-modules/scripts/create-module.sh`](terraform-aws-modules/scripts/create-module.sh)
- [`terraform-aws-modules/scripts/create-examples.sh`](terraform-aws-modules/scripts/create-examples.sh)
- [`terraform-aws-modules/scripts/create-plan.sh`](terraform-aws-modules/scripts/create-plan.sh)
- [`terraform-aws-modules/scripts/test-module.sh`](terraform-aws-modules/scripts/test-module.sh)
- [`terraform-aws-modules/scripts/create-documentation.sh`](terraform-aws-modules/scripts/create-documentation.sh)

These workflows encourage consistent module structure, testing, and documentation aligned with `terraform-aws-modules` best practices.

### 3. Iterate with memory-backed context

As you create modules, the memory bank accumulates:

- Architectural decisions
- Constraints and non-functional requirements
- Naming and tagging conventions
- Testing and rollout strategies

Subsequent CODEX tasks (for example, refactoring an existing module or adding a new one) can reuse this context automatically, reducing duplication and helping maintain consistency across your Terraform codebase.


## Development

If you want to extend or customize these skills:

1. Clone this repository and create a new branch.
2. Modify the relevant skill definitions and scripts under `memory-bank-bootstrap/` or `terraform-aws-modules/`.
3. Test locally by pointing your CODEX workspace at your modified checkout.

Refer to the individual [`SKILL.md`](memory-bank-bootstrap/SKILL.md) files for implementation details and conventions.


## Contributing

Contributions are welcome. Common contribution paths include:

- Improving documentation and examples
- Adding new workflows or scripts for common Terraform/AWS patterns
- Enhancing support for additional MCP servers or context sources

Please open an issue or pull request in this repository with a clear description of the change and rationale.


## License

This project is licensed under the terms described in [`LICENSE`](LICENSE).
