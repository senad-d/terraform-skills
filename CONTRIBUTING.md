# Contributing to terraform-skills

Thank you for your interest in improving this Terraform skills bundle. Contributions are welcome for documentation, scripts, and skill improvements of all sizes.

## Project scope

This repository hosts skills for the CODEX CLI focused on:

- Working with Terraform and common Terraform/AWS modules
- Interacting with the memory bank and related bootstrap scripts
- Helper workflows, references, and examples that make it easier to use Terraform effectively

Please keep contributions aligned with this focus.

## Ways to contribute

- Improve or clarify documentation (including SKILL docs and references)
- Report bugs in scripts or workflows
- Add new helper workflows, scripts, or checks
- Enhance existing skills, including new examples or better defaults
- Refine error messages, logging, and inline help for scripts

## Development workflow

1. **Fork and clone** this repository.
2. **Create a feature branch** for your change:
   - Example: `git checkout -b feat/improve-terraform-module-docs`
3. **Make small, focused commits** with clear messages.
4. **Run basic checks** before opening a pull request:
   - For Terraform code: `terraform fmt` in the relevant directories.
   - For shell scripts: run a quick sanity check (e.g. `./script.sh --help`).
5. **Open a pull request** against the default branch and fill out the PR template.

## Coding guidelines

- **Shell scripts**
  - Favor POSIX/Bash best practices.
  - Where possible, run [`shellcheck`](https://www.shellcheck.net/) on changed scripts.
  - Keep scripts **idempotent** where it is reasonable and safe (re-running should not corrupt state).
  - Prefer `set -euo pipefail` and explicit error handling where appropriate.

- **General**
  - Keep changes minimal and focused on a single concern.
  - Prefer readability and explicitness over cleverness.
  - Avoid introducing external dependencies unless clearly justified.

## Testing & verification

Before you submit a PR, you should:

- Run modified scripts with `--help` (if supported) to ensure usage text still makes sense.
- For scripts that operate on Terraform modules, test against a sample module when practical.
- Ensure README and SKILL documentation stay in sync with behavior changes.
- Skim the diff to confirm no accidental changes (whitespace-only changes should generally be intentional).

## Pull request checklist

When opening a pull request, please confirm that:

- [ ] You followed the development workflow above.
- [ ] You ran basic checks on any scripts you touched (e.g. `--help` or a dry-run mode, if available).
- [ ] You updated documentation where needed (e.g. `README.md`, `SKILL.md`, or reference docs).
- [ ] You avoided breaking changes, or clearly documented them in the PR description.
- [ ] Your changes are within the scope of this repository (Terraform skills, modules, and related tooling).
