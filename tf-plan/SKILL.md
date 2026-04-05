---
name: tf-plan
description: >-
  Use when the user asks for a Terraform plan, planning workflow, or architecture plan without changing code, including requests to create a new module plan, edit an existing module plan, or draft AWS architecture planning based on goals.
metadata:
  category: terraform-skills
  source:
    repository: 'https://github.com/senad-d/terraform-skills'
    path: tf-plan
---

# Terraform Planning

Use this Terraform Planning skill to produce a structured plan for Terraform module work or AWS architecture planning based on the user's goals, without changing code.

## Planning options

- Create a new module with `new-module` when user mentiones `new`.
- Update existing module with `edit-module` when user mentiones `edit`.
- Architecture ideas with `architecture` when user mentiones `architecture` and `designe`.

## Scripts

- Run the [find_script](./scripts/find.sh) to search for modules in the repository.
- Run the [read_script](./scripts/read.sh) to read files.
- Run the [plan_script](./scripts/plan.sh) to create the plan.

### Examples:
```bash
./scripts/find.sh -d <directory> [-n <name-pattern>]
./scripts/read.sh -d <directory> [-n <name-pattern>]
./scripts/plan.sh -t <type> [-m <module_name>] [-g <short_goal>]
```

User-goald skills install under `$CODEX_HOME/skills` (default: `skills`).

---

## Terraform Planning Workflow

1. Prepare context.
   
   - Read `Rules/` and [./references](./references).

2. Type and goal confirmation (hard gate).

   - Validate inputs first: confirm from the original user prompt that you can deduce the plan type (new, edit, architecture), a short goal, and the module name when the type is new or edit; if any are missing or unclear, stop and request clarification.
   - Stop-gate: if goal is ambiguous, halt and ask to clarify using the [template](./templates/IMPUTS_TEMPLATE.md).

3. Create the plan based on the type.

   - Generate the plan file using [plan_script](./scripts/plan.sh) based on the user request.

4. Follow one of the sub-workflows based on the type (select one file to read and follow):

   - Follow the [New-module](./sub_workflows/NEW_MODULE_SUB_WOTKFLOW.md) sub-workflows to update a plan for creating a new module based on the user requirements.
   - Follow the [Edit-module](./sub_workflows/EDIT_MODULE_SUB_WORKFOLW.md) sub-workflows to update a plan to modify the existing module according to user requirements.
   - Follow the [Architecture](./sub_workflows/ARHITECTURE_SUB_WORKFLOW.md) sub-workflows to update AWS architecture designe plan based on user requirements.

---

## References and guides

Always read all guides.

- [01-overview-and-lifecycle.md](./references/01-overview-and-lifecycle.md) for overview, lifecycle, and map of the planning guides.
- [02-plan-methodology.md](./references/02-plan-methodology.md) planning phases, evidence rules, severity rubric, and checklists.
- [03-composition-and-patterns](./references/03-composition-and-patterns.md) for composition patterns, root module design, flat hierarchy rules, dependency inversion, and data-only/remote-state wiring.
- [04-investigation-procedure.md](./references/04-investigation-procedure.md) for file discovery, automation scripts, and MCP reference gathering.
- [05-pillar-mapping.md](./references/05-pillar-mapping.md) for mapping findings to AWS Well-Architected pillars.
- [06-arhitecture.md](./references/06-arhitecture.md) for architecture planning guidelines, core rules, security/IAM, and validation checklist.


## DO NOT DO

- DO NOT proceed without confirming the plan type, a short goal, and the module name when required.
- DO NOT give vague or subjective feedback.
- DO NOT create and modify Terraform code.
- DO NOT run Terraform commands in this skill.
- DO NOT use any fluff to increase the word count.
- YOU DO NOT NEED to read `./scripts/*.sh` scripts.
- DO NOT infer intent without evidence; halt if goal is ambiguous.
