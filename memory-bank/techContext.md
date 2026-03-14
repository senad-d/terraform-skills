# Tech Context

## Stack

- Terraform (module design and validation)
- AWS (target platform for modules)
- Shell scripts (skill automation)
- Markdown (documentation and memory bank)
- CODEX CLI with MCP servers (context7, terraform-mcp-server, aws-knowledge-mcp-server)

## Tooling

- `codex` for skill-driven workflows
- `terraform` for module validation and execution
- `tflint`, `tfsec` for linting and security checks
- `rg` for search, `jq` for JSON processing
- Optional `localstack` for local AWS emulation

## Repository Structure

- `memory-bank-bootstrap/` skill for bootstrapping memory-bank and AGENTS rules
- `terraform-aws-modules/` skill with module scaffolding, docs, and tests
- `memory-bank/` stores project context for this repo
- `Rules/` added after memory-bank bootstrap to store additional rules
- Top-level `README.md`, `LICENSE`, and contribution docs

## Constraints

- Follow skill workflows and do not bypass scripted bootstrap steps.
- Use `rg` for searches (avoid `grep`).
- Use `jq` for JSON parsing and transformations.
- Update memory-bank after significant decisions or changes.
