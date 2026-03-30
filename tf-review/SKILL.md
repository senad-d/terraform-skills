---
name: tf-review
description: Review Terraform code.
---

# Terraform Review

Use this Terraform Review skill to respond to user when they enter the phrase `review terraform`. Provides a repeatable Terraform review workflow focused on security, reliability, cost, and IaC best practices with actionable findings.

## Scripts

- Run the [find_script](./scripts/find.sh) to search for modules in the repository.
- Run the [read_script](./scripts/read.sh) to read files.
- Run the [plan_script](./scripts/plan.sh) to create the plan.
- Run the [review_script](./scripts/review.sh) to create a new review file.

### Examples:
```bash
./scripts/find.sh -d <directory> [-n <name-pattern>]
./scripts/read.sh -d <directory> [-n <name-pattern>]
./scripts/plan.sh -m <module_name> [-g <short_goal>]
./scripts/review.sh -m <module_name> [-g <short_goal>]
```

User-scoped skills install under `$CODEX_HOME/skills` (default: `skills`).

---

## Terraform Review Workflow

1. Start new task and prepare context.
   
   - Update memory-bank files.
   - Read `Rules/` and skill [./references](./references).


2. Intake and scope confirmation (hard gate).

   - Validate inputs first: (module name, scope, goal, plan path).
   - Stop-gate: if module path or scope is ambiguous, halt and ask to clarify.

3. Find related files.

   - Use [find_script](./scripts/find.sh) to locate candidate paths.

4. Read files.

   - Use [read_script](./scripts/read.sh) to collect files needed for inventory and evidence.

5. Investigate documentation.

   - Gather Terraform and AWS references for each resource type.

6. Create the plan.

   - Generate the plan file using [plan_script](./scripts/plan.sh).

7. Reason about evidence and verify decisions (hard gate).

   - Capture file paths + line references, plan output, or tool output.
   - Use the severity rubric and evidence rules from the references.
   - Try to falsify each finding and remove non-issues.
   - Fill in the plan with details from the investigation context and reasoning decisions before continuing. 
   - Stop-gate: do not create or update the review until the plan is complete.

8. Create and update the review document.

   - Use the [review_script](./scripts/review.sh) after the planning and reasoning are complete.
   - Read the plan file and folow it.
   - Provide findings, evidence log, improvement path, and sources.

9. Close out.

   - Update completed tasks in Plan and memory-bank.
   - Create output using the following response [template](./templates/RESPONSE_TEMPLATE.md)
   - Use the prompt [template](./templates/PROMPT_TEMPLATE.md) only if the user decides to work on the findings from the review.

---

## References and guides

Always read all guides.

- [./references/01-overview-and-lifecycle.md](./references/01-overview-and-lifecycle.md) for overview, lifecycle, and map of the review guides.
- [./references/02-review-methodology.md](./references/02-review-methodology.md) Review phases, evidence rules, severity rubric, and checklists.
- [./references/03-remediation-and-evidence.md](./references/03-remediation-and-evidence.md) for investigation workflow, remediation patterns, and verification steps.
- [./references/04-investigation-procedure.md](./references/04-investigation-procedure.md) for file discovery, automation scripts, and MCP reference gathering.
- [./references/05-pillar-mapping.md](./references/05-pillar-mapping.md) for mapping findings to AWS Well-Architected pillars.


## DO NOT DO

- DO NOT attempt to resolve the potential problems found in the review yourself.
- DO NOT give vague or subjective feedback.
- DO NOT invent issues or assume intent.
- DO NOT skip security or correctness issues in favor of style nits.
- DO NOT suggest breaking changes without calling out the blast radius and required updates across references.
- DO NOT hand-wave fixes like "run terraform fmt" without identifying the drifted file and the specific block.
- DO NOT propose changes outside the requested scope or rewrite modules wholesale.
- DO NOT modify Terraform code or run Terraform commands/tests in this skill.
- YOU DO NOT NEED to read `./scripts/*.sh` scripts.
- DO NOT modify Terraform code or documentation with this skill.
- DO NOT run Terraform commands or tests (plan, validate, apply, fmt, etc.).
- DO NOT infer intent without evidence; halt if scope is ambiguous.
