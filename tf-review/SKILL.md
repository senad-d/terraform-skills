---
name: tf-review
description: Performs structured Terraform code reviews to identify security risks, infrastructure issues, and deviations from AWS and IaC best practices, with actionable recommendations.
---

# Terraform Review

- Provides a repeatable Terraform review workflow focused on security,
  reliability, cost, and IaC best practices with actionable findings.

## Inputs and Outputs

Inputs (required unless marked optional):

- Module name.
- Review scope (child module, root module, or custom).
- Review goal.
- Plan path (optional).
- Output directory (optional).

Outputs:

- Review plan file in `Plan/`.
- Review document in the output directory.
- Evidence log entries embedded in the review.
- Reference list for Terraform, AWS, and repository standards.

## Skill path (set once)

- Export all variables needed for running scripts.

Automation scripts:

```bash
export CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
export FIND="$CODEX_HOME/skills/tf-review/scripts/find.sh"
export READ="$CODEX_HOME/skills/tf-review/scripts/read.sh"
export PLAN="$CODEX_HOME/skills/tf-review/scripts/plan.sh"
export REVIEW="$CODEX_HOME/skills/tf-review/scripts/review.sh"
```

User-scoped skills install under `$CODEX_HOME/skills` (default: `skills`).

## List modules

- Use `find.sh` to search for modules in the repository:

```bash
"$FIND" -d <directory> [-n <name-pattern>]
```

## Reading files

- Use `read.sh` to read files by selecting a directory and optionally specifying the file name:

```bash
"$READ" -d <directory> [-n <name-pattern>]
```

## Planning Template

- Use `plan.sh` to create the plan:

```bash
"$PLAN" -m <module_name> [-g <short_goal>]
```

- `Plan/` holds required change plans before review begin.
- `memory-bank/` stores project context and task history; read for background when needed.

## Review Template

- To create a new review template, use the automation script `review.sh`:

```bash
"$REVIEW" -m <module_name> [-g <short_goal>] [-p <plan_path>] [-o <output_dir>]
```

## Required Workflow

1. Intake and scope confirmation
   - Validate inputs first (module name, scope, goal, plan path).
   - Read `Rules/` and `$CODEX_HOME/skills/tf-review/references` standards.
   - Fail fast if scope is unclear or inputs are missing.
2. Inventory (modules/resources/providers)
   - Use `$FIND` and `$READ` to locate module paths and read core files.
   - Build a resource, provider, and module inventory before reviewing details.
3. Evidence collection (files + tool output)
   - Capture file paths + line references, plan output, or tool output.
   - Confirm behavior against Terraform and AWS documentation and note references.
4. Findings and severity assignment
   - Use the severity rubric and evidence rules from the references.
   - Prioritize security, reliability, and correctness before style.
5. Remediation options and recommendation
   - Offer a concrete HCL change or policy edit per finding.
   - Include tradeoffs when the least-disruptive fix differs from best practice.
6. Verification and challenge pass
   - Add a verification step for each finding with expected outcome.
   - Try to falsify each finding and remove non-issues.
7. Publish review and references
   - Provide the review output with evidence log, improvement path, and sources.
   - Keep the workflow deterministic and minimal-input per
     `Rules/Commandments.md`.

## Constructive Review Format

Each finding must include:

- Summary
- Impact
- Evidence
- Recommendation
- Verification
- Assumptions

Also include a "What's working" section that highlights safe defaults or
effective patterns already present.

## Clear Improvement Path

- Provide a "Top 3 fixes" list ordered by severity and risk reduction.
- For each finding, identify the "fastest safe fix" and the "preferred fix"
  when they differ.
- Require an explicit verification step to close each item.

---

## Best-Practice Expectations

- Verify module intent and scope match the README and variables: resources, outputs, and behavior should align with declared purpose.
- Check provider and Terraform version constraints for clarity, compatibility, and minimum required versions.
- Confirm required inputs are validated (types, defaults, `validation` blocks) and optional inputs have safe defaults.
- Review IAM, networking, encryption, and logging settings for least privilege and secure-by-default posture.
- Validate resource naming/tagging is consistent and tags include required ownership/environment fields.
- Look for hard-coded regions, account IDs, or ARNs that should be inputs.
- Ensure lifecycle settings (`prevent_destroy`, `ignore_changes`, `create_before_destroy`) are justified and not masking drift.
- Scan for cost traps: unbounded scaling, high-cost defaults, missing log retention, or redundant resources.
- Confirm outputs expose only necessary data and avoid leaking sensitive values.
- Check that examples/tests (if present) still match the module interface and produce a clean plan.

## Security & Configuration Notes

- When a security issue or misconfiguration is found, record severity (Critical/High/Medium/Low), cite exact evidence (file + line or plan output), and describe concrete impact.
- Provide a direct, implementable remediation (exact Terraform argument/value or policy change) and cite the authoritative source or `Rules/`.
- For Critical/High issues, recommend blocking merge/deploy until fixed and call out the required validation step (plan, policy check, or test).

## Coding Style

- Compare against Terraform style conventions and `terraform fmt` output. Any formatting drift is a concrete fix: cite the exact file and note that formatting should match `terraform fmt` for that file.
- Enforce consistent naming conventions: `snake_case` for variables, locals, and outputs; descriptive, stable resource names (avoid single-letter or ambiguous names). Provide rename suggestions with the exact references that must be updated.
- Keep expressions readable and consistent: prefer locals for repeated or complex expressions; split long interpolations across lines; use consistent quoting and list/map formatting. Recommend a specific refactor with an explicit HCL change or snippet.
- File organization should be predictable: group variables in `variables.tf`, outputs in `outputs.tf`, locals in `locals.tf`, and resources in purpose-specific files. When a block is misplaced, suggest the target file and block move.
- Comments should be minimal and purposeful: add short comments only where logic is non-obvious, and remove redundant comments. Point to the exact lines to edit.
- Avoid vague style advice. Every suggestion must be a concrete, actionable fix tied to a file path and line reference, with the exact change required.

## Quick Reference

- Purpose: Structured Terraform code reviews with actionable findings and remediation guidance.
- Scope: Child modules, root modules, and shared patterns in this repository.
- Inputs: Module name, review goal, optional plan path, optional output directory.
- Outputs: Review template with findings, plan link, and source references.
- Required tools: `bash`, `rg`, `jq`, Terraform CLI.
- Artifacts: `Plan/` entry, review file (from `$REVIEW` output), cited standards links.
- Success criteria: Findings include file references, severity, impact, and concrete remediation steps.

## References

Always read all references when planning.

- `references/01-overview-and-lifecycle.md` — Overview, lifecycle, and map of the review guides.
- `references/02-review-methodology.md` — Review phases, evidence rules, severity rubric, and checklists.
- `references/03-remediation-and-evidence.md` — Investigation workflow, remediation patterns, and verification steps.
- `references/04-investigation-procedure.md` — File discovery, automation scripts, and MCP reference gathering.

## DO NOT DO

- DO NOT attempt to resolve the potential problems found in the review yourself.
- DO NOT give vague or subjective feedback. Every finding must include a file path, line reference, and the exact change to make.
- DO NOT invent issues or assume intent. Base every finding on the code and the plan/output provided.
- DO NOT skip security or correctness issues in favor of style nits. Prioritize by severity and impact.
- DO NOT suggest breaking changes without calling out the blast radius and required updates across references.
- DO NOT hand-wave fixes like "run terraform fmt" without identifying the drifted file and the specific block.
- DO NOT propose changes outside the requested scope or rewrite modules wholesale.
- YOU DO NOT NEED to read `scripts/*.sh` scripts.
