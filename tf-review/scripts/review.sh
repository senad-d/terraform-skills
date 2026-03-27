#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<EOF
Usage: $0 -m <module_name> [-g <short_goal>] [-p <plan_path>] [-o <output_dir>]

Options:
  -m, --module <name>      Module name being reviewed (required)
  -g, --goal <goal>        Short review goal summary
  -p, --plan <path>        Path to the review plan file
  -o, --output-dir <dir>   Directory to place the review template (default: Review)
  -h, --help               Show this help and exit

Example:
  $0 -m iam-role -g "Review IAM role module" -p Plan/20260327-iam-role.md
EOF
}

module_name=""
goal=""
plan_path=""
output_dir="Review"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -m|--module)
      if [[ $# -lt 2 ]]; then
        echo "Error: -m|--module requires a value" >&2
        usage
        exit 1
      fi
      module_name="$2"
      shift 2
      ;;
    -g|--goal)
      if [[ $# -lt 2 ]]; then
        echo "Error: -g|--goal requires a value" >&2
        usage
        exit 1
      fi
      goal="$2"
      shift 2
      ;;
    -p|--plan)
      if [[ $# -lt 2 ]]; then
        echo "Error: -p|--plan requires a value" >&2
        usage
        exit 1
      fi
      plan_path="$2"
      shift 2
      ;;
    -o|--output-dir)
      if [[ $# -lt 2 ]]; then
        echo "Error: -o|--output-dir requires a value" >&2
        usage
        exit 1
      fi
      output_dir="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "${module_name}" ]]; then
  echo "Error: module name is required" >&2
  usage
  exit 1
fi

if [[ -n "${plan_path}" && ! -f "${plan_path}" ]]; then
  echo "Error: plan path does not exist: ${plan_path}" >&2
  exit 1
fi

install -d "${output_dir}"

slug="${module_name//[^a-zA-Z0-9-]/-}"
review_date="$(date +%Y%m%d)"
review_path="${output_dir}/${review_date}-${slug}.md"

goal_display="${goal:-<!-- TODO: add review goal -->}"
plan_display="${plan_path:-<!-- TODO: add plan path -->}"

cat > "${review_path}" <<EOF
# Review Summary
- Module: ${module_name}
- Review goal: ${goal_display}
- Plan reference: ${plan_display}

# Review Scope
- In-scope paths: <!-- TODO -->
- Out-of-scope paths: <!-- TODO -->
- Terraform version / provider constraints: <!-- TODO -->
- Target AWS accounts/regions: <!-- TODO -->

# Resource Inventory
- Resources: <!-- TODO -->
- Data sources: <!-- TODO -->
- Modules: <!-- TODO -->
- Providers: <!-- TODO -->
- External dependencies: <!-- TODO -->

# Findings Overview
Severity scale: Critical, High, Medium, Low, Informational

| ID | Severity | Pillar | Area | File | Description | Recommendation | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| <!-- TODO --> | <!-- TODO --> | <!-- TODO --> | <!-- TODO --> | <!-- TODO --> | <!-- TODO --> | <!-- TODO --> | <!-- TODO --> |

# Detailed Findings
## [F-001] <!-- TODO: title -->
- Severity: <!-- TODO -->
- Area: <!-- TODO -->
- Files: <!-- TODO -->
- Evidence: <!-- TODO -->
- Impact: <!-- TODO -->
- Recommendation: <!-- TODO -->
- Verification: <!-- TODO -->
- Assumptions: <!-- TODO -->
- Reference links: <!-- TODO -->
- Status: <!-- TODO -->

# Positive Observations
- <!-- TODO: note good patterns or safeguards -->

# Security Review
- <!-- TODO: encryption, IAM, network exposure, logging -->

# Reliability & Operations
- <!-- TODO: timeouts, retries, dependencies, lifecycle rules -->

# Cost & Efficiency
- <!-- TODO: sizing, scaling, data transfer, unused resources -->

# Documentation Gaps
- <!-- TODO: missing or outdated docs/examples -->

# Evidence Log
- Evidence item: <!-- file:line, plan output, or tool output -->
- MCP reference: <!-- TODO -->

# Verification Plan
| Finding ID | Verification Step | Expected Outcome |
| --- | --- | --- |
| <!-- TODO --> | <!-- TODO --> | <!-- TODO --> |

# Improvement Path
**Top 3 fixes (priority order):**
1. <!-- TODO: finding ID + reason -->
2. <!-- TODO: finding ID + reason -->
3. <!-- TODO: finding ID + reason -->

**Per finding:**
- Fastest safe fix: <!-- TODO -->
- Preferred fix: <!-- TODO -->

# Handoff
## Action Queue
| Finding ID | Priority | Pillar | File:Line | Exact change | Rationale | Verification |
| --- | --- | --- | --- | --- | --- | --- |
| <!-- TODO --> | <!-- TODO --> | <!-- TODO --> | <!-- TODO --> | <!-- TODO --> | <!-- TODO --> | <!-- TODO --> |

## Next Steps
1. <!-- TODO: next action -->
2. <!-- TODO: next action -->
3. <!-- TODO: next action -->

## Dependencies / Blocks (optional)
- <!-- TODO: cross-module impacts, prerequisites, or approvals -->

# Assumptions & Decisions
- <!-- TODO: document review assumptions and accepted tradeoffs -->

# Follow-up Actions
| ID | Action | Owner |
| --- | --- | --- |
| <!-- TODO --> | <!-- TODO --> | <!-- TODO --> |

# References
- <!-- TODO: link AWS/Terraform docs and internal standards -->

EOF

cat << EOF_PROMPT > "${output_dir}/${slug}-prompt.md"
**Context**
- Module: ${module_name}
- Review file: ${review_path}

**Task**
- Use the review findings to update Terraform code safely and precisely.
- Implement the "Exact change" steps from the Action Queue.
- Follow verification steps for each finding.

**Scope Guardrails**
- Stay within the module scope listed in Review Scope.
- Do not expand scope without explicit approval.
- Prefer the fastest safe fix unless the preferred fix is approved.

**Inputs to Fill**
- Module path: <!-- TODO: exact path -->
- In-scope files: <!-- TODO -->
- Out-of-scope files: <!-- TODO -->
- Findings to address (IDs): <!-- TODO -->
- References to consult: <!-- TODO -->

**Execution Guide**
1. Read the ${review_path}.
2. Confirm scope and files listed above.
3. Investigate solutions and reason about implementation.
4. For each finding ID:
   - Apply the exact change described in the Action Queue.
   - Update related variables, outputs, or docs only if required by the change.
5. Run the verification steps.
6. Summarize changes and link back to each finding ID.

**Output Expectations**
- A short change summary mapped to finding IDs.
- A verification result per finding.
- A list of any blockers or follow-up items.

EOF_PROMPT

echo "Created review template at ${review_path}" >&2
