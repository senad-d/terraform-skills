---
name: memory-bank-bootstrap
description: Initialize a repository memory-bank directory and fill TODO sections. Use when asked to add or bootstrap `memory-bank/`, create the base files with the bundled create-memory script, or replace TODO placeholders using project AGENT/RULES instructions and user input.
---

# Memory Bank Bootstrap


## Skill path (set once)

Automation scripts:
```bash
export CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
export RULE="$CODEX_HOME/skills/memory-bank-bootstrap/scripts/add-agents.sh"
export MEMORY="$CODEX_HOME/skills/memory-bank-bootstrap/scripts/create-memory.sh"
```

User-scoped skills install under `$CODEX_HOME/skills` (default: `skills`).

## Agent gide
- Use `add-agents.sh` to add the AGENTS.md rules for memory-bank:
```bash
"$RULE" [TARGET_PATH]
```

## Memory Template
- Use `create-memory.sh` to create the memory-bank files:
```bash
"$MEMORYN" [TARGET_DIR]
```

## Workflow

1. Confirm `memory-bank/` does not exist. 
   - If it exists, STOP and report that no changes were made. Do not edit anything.
2. Read project instructions.
3. Create the scaffold with the `$MEMORY` script.
4. Replace all TODO sections with project-specific content.
5. Add or update the `AGENTS.md` file in the designated `TARGET_PATH`.

## Step Details

### 1. Confirm `memory-bank/` does not exist

Run one of these checks from the repo root:

- `rg --files -g 'memory-bank/**'`
- `ls memory-bank`

If the directory exists, stop and report that you skipped all steps.

### 2. Read project instructions

Find and read all project guidance before writing content.

- Locate `README.md` with `rg --files -g 'README*.md'`.
- If not mentioned in README.md, list all files in the root directory and identify the underlying framework we are using.
- Locate `AGENT.md` or `AGENTS.md` with `rg --files -g 'AGENT*.md' -g 'AGENTS*.md'`.
- Locate rules files with `rg --files -g 'RULES*.md' -g 'rules*.md'`.
- Summarize constraints or wording requirements that must be reflected in memory-bank content.

### 3. Create the scaffold with the bundled script

Run the script from this skill against the target repository root.

- Default target is `memory-bank/`.
- If the user specifies another directory, pass it as the script argument.

### 4. Replace all TODO sections

- Open each file under `memory-bank/` and remove the `> TODO:` guidance blocks.
- Fill every section with project-specific content derived from the instructions and user answers.
- If required details are missing, ask the user targeted questions before editing.

### 5. Add or update AGENTS.md

- Use `$RULE` to add the AGENTS.md rules file.
- Always ask the user where they want to store `AGENTS.md` and map their choice to `TARGET_PATH`.

Ask the user:

> Where should AGENTS.md live?
> 1. Repository root for this project (AGENTS.md in the current repo root)
> 2. User-wide CODEX_HOME (AGENTS.md under `$CODEX_HOME`)
> 3. Custom path (you specify the path)

Map the answer to `TARGET_PATH`:

- If the user chooses **1** (repository root):
  - `TARGET_PATH="AGENTS.md"`
- If the user chooses **2** (user-wide CODEX_HOME):
  - `TARGET_PATH="$CODEX_HOME/AGENTS.md"`
- If the user chooses **3** (custom path):
  - Ask: "Provide the full path (absolute or relative to the repo root) for AGENTS.md."
  - Use the user answer as `TARGET_PATH`.

Then run the script:

```bash
"$RULE" "$TARGET_PATH"
```

## Question Set (use only as needed)

- Project brief: purpose, scope, goals, non-goals, workflow requirements.
- Product context: why it exists, problems it solves, expected behavior, UX goals.
- System patterns: module structure, naming/tagging, validation, composition, versioning.
- Tech context: stack, tooling, repository structure, constraints.
- Active context: current focus, recent changes, next steps, decisions/constraints.
- Progress: what works, remaining work, current status, known issues.
- Tasks index: in-progress, pending, completed, abandoned.

## Resources

- `$MEMORYN` scaffolds the memory-bank structure with TODO placeholders.
- `$RULE` add or update the desired AGENTS.md file according to the specified rules.

## DO NOT DO
- DO NOT USE `mkdir` command to creadte directories.
- DO NOT USE any commands other than those specified in this guide.
- YOU DO NOT NEED to read `scripts/*.sh` scripts.