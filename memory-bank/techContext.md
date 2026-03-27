# Tech Context

## Stack

- Terraform (module design and validation)
- AWS (target platform for modules)
- Shell scripts (skill automation)
- Markdown (documentation and memory bank)
- CODEX CLI with MCP servers (terraform-mcp-server, aws-knowledge-mcp-server)

## Tooling

- VS Code (Markdown preview) + markdownlint extension for editing `SKILL.md`
- `cookiecutter` for skill scaffolding
- `bash`, `make`, `task` for local skill testing
- `markdownlint-cli2` for markdown validation
- `shellcheck` for shell script linting
- Git for version control
- GitHub Actions for CI validation/testing
- MkDocs + Material for documentation site generation

## Repository Structure

- `memory-bank-bootstrap/` skill for bootstrapping the memory bank
- `tf-child-modules/` skill for Terraform AWS child modules
- `tf-root-module/` skill for Terraform root modules
- `memory-bank/` stores project context for this repo
- `Rules/` stores custom rule sets that skills load to change behavior or add features without editing core scripts
- `Plan/` stores skill-generated execution plans and decision logs for reuse and review
- Top-level `README.md`, `LICENSE`, and contribution docs

## Constraints

- Follow skill workflows and do not bypass scripted bootstrap steps.
- Use `rg` for searches (avoid `grep`).
- Use `jq` for JSON parsing and transformations.
- Update memory-bank after significant decisions or changes.
