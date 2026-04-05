---
name: memory-bank-bootstrap
description: >-
   Use when asked to add or bootstrap a memory-bank.
metadata:
  category: terraform-skills
  source:
    repository: 'https://github.com/senad-d/terraform-skills'
    path: memory-bank-bootstrap
---

# Memory Bank Bootstrap

Use when asked to add or `bootstrap memory-bank`, create the base files with the bundled create-memory script, and replace TODO placeholders using project instructions and user input.

## Scripts

- Run the [memory_script](./scripts/create-memory.sh) to create the memory-bank files.
- Run the [agents_script](./scripts/add-agents.sh) to add the AGENTS.md rules for memory-bank.

User-scoped skills install under `$CODEX_HOME/skills` (default: `skills`).

```bash
./scripts/create-memory.sh [TARGET_DIR]
./scripts/add-agents.sh [TARGET_PATH]
```

## Memory Bootstrap Workflow

1. Confirm `memory-bank/` does not exist.
   - If it exists, STOP and report that no changes were made. Do not edit anything.
2. Learn about the project.
3. Create the scaffold with the [memory_script](./scripts/create-memory.sh).
4. Replace all TODO sections with project-specific content.
5. Add or update the `AGENTS.md` file in the designated `TARGET_PATH` using [agents_script](./scripts/add-agents.sh).
6. Create expected output ussing [output_template](./templates/OUTPUT_TEMPLATE.md).

---

## Step Details

### 1. Confirm `memory-bank/` does not exist

Run one of these checks from the repo root:

- `rg --files -g 'memory-bank/**'`
- `ls memory-bank`

If the directory exists, stop and report that you skipped all steps.

### 2. Read project instructions

Find and read all project guidance before writing content.

- Locate `README.md` with `rg --files -g 'README*.md'`.
- If not mentioned in README.md, list all files in the root directory and identify the underlying framework it is using.
- Locate `AGENT.md` or `AGENTS.md` with `rg --files -g 'AGENT*.md' -g 'AGENTS*.md'`.
- Locate rules files with `rg --files -g 'Rules/**'`.
- Review all the available files to determine the project's objectives.
- If there is no documentation, you can review the current file structure and content to determine the basic project information.
- Summarize constraints or wording requirements that must be reflected in memory-bank content.

### 3. Create the scaffold with the bundled script

Run the [memory_script](./scripts/create-memory.sh) against the target repository root.

### 4. Replace all TODO sections

- Open each file under `memory-bank/` and remove the `TODO:` guidance blocks.
- Fill every section with project-specific content derived from the ivestigation and user answers.
- If required details are missing, ask the user targeted questions before editing.

### 5. Add or update AGENTS.md

- Always inquire where the user prefers to save `AGENTS.md` and correspondingly assign their choice to `TARGET_PATH` using the [question_template](./templates/QUESTION_TEMPLATE.md).
- Use [agents_script](./scripts/add-agents.sh) to add the `AGENTS.md` file.

### 6. Expected output

- Use [output_template](./templates/OUTPUT_TEMPLATE.md) once all other tasks are done.

## Question Set

- Project brief: purpose, scope, goals, non-goals, workflow requirements.
- Product context: why it exists, problems it solves, expected behavior, UX goals.
- System patterns: module structure, naming/tagging, validation, composition, versioning.
- Tech context: stack, tooling, repository structure, constraints.
- Active context: current focus, recent changes, next steps, decisions/constraints.
- Progress: what works, remaining work, current status, known issues.
- Tasks index: in-progress, pending, completed, abandoned.

## DO NOT DO

- DO NOT USE `mkdir` command to creadte directories.
- DO NOT USE any commands other than those specified in this guide.
- YOU DO NOT NEED to read `scripts/*.sh` scripts.
