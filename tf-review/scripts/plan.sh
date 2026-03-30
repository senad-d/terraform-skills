#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 -m <module_name> [-g <short_goal>]" >&2
  echo "Example: $0 -m iam-role -g 'Review IAM role module'" >&2
}

module_name=""
goal=""

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

plan_dir="Plan"
install -d "${plan_dir}"

slug="${module_name//[^a-zA-Z0-9-]/-}"
plan_date="$(date +%Y%m%d)"
plan_path="${plan_dir}/${plan_date}-${slug}.md"

cat > "${plan_path}" <<EOF
# Summary

- [ ] Module: ${module_name}
- [ ] Review goal: ${goal}

# Review Scope

- In-scope paths:
  - <!-- TODO: list module paths/files -->
- Out-of-scope paths:
  - <!-- TODO: list exclusions -->
- Terraform version / provider constraints:
  - <!-- TODO: capture versions from versions.tf or required_providers -->

# Review Workflow (Step by Step)

1. [ ] Gather context.

   - Read files for ${module_name}.
   - Identify intended use cases and expected behaviors.

2. [ ] Inspect module structure.

   - Check for standard files: main.tf, variables.tf, outputs.tf, versions.tf, locals.tf.
   - Verify naming conventions and consistent formatting.

3. [ ] Investigate documentation.

   - AWS docs: <!-- TODO: include MCP-derived AWS doc URLs and summarize key findings -->

4. [ ] Review inputs and validations.

   - Confirm variable types, defaults, descriptions, and validation blocks.
   - Flag ambiguous or missing variable documentation.

5. [ ] Review outputs.

   - Ensure outputs are necessary, well-described, and marked sensitive when needed.
   - Check output stability (no unintended breaking changes).

6. [ ] Review providers, resources, and data sources.

   - Confirm provider constraints and usage are explicit.
   - Validate resource composition, dependencies, and lifecycle rules.

7. [ ] Security and compliance review.

   - Check encryption, least privilege, network exposure, logging, and tagging.
   - Note any exceptions and required compensating controls.
   
8. [ ] Review module composition and reuse.

   - Identify child modules used and assess interface compatibility.
   - Verify inputs/outputs mapping and passthrough correctness.

9. [ ] Review documentation alignment.

   - Verify docs match actual behavior and constraints.

10. [ ] Capture findings and decisions.

   - List issues with severity and recommended fixes.
   - Record accepted tradeoffs and follow-up actions.

# Notes

- <!-- TODO: add any noteworthy observations -->

# Review Evidence

- Rules/standards reviewed:
  - <!-- TODO: list applicable repo rules or standards -->
- Docs consulted:
  - <!-- TODO: include URLs or internal docs referenced -->
- Reasoning scope and decisions:
  - <!-- TODO: include reasoning behind the decisions -->

EOF

echo "Created plan at ${plan_path}" >&2
