#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 -m <module_name> [-g <short_goal>]" >&2
  echo "Example: $0 -m iam-role -g 'Create reusable IAM role module'" >&2
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
- [ ] Goal: ${goal}

# Investigation Notes
- Rules reviewed: <!-- TODO: list specific rules or standards reviewed -->
- Docs consulted:
  - AWS docs: <!-- TODO: include MCP-derived AWS doc URLs and summarize key findings -->
    - Key findings:
  - Terraform provider docs: <!-- TODO: include MCP-derived provider doc URLs and summarize key findings -->
    - Key findings:
  - Upstream modules (if any): <!-- TODO: include module URLs and summarize key findings -->
    - Key findings:

# Interface Contract
## Inputs
| Name | Type | Required | Default | Sensitive | Validation | Description |
| --- | --- | --- | --- | --- | --- | --- |
| <!-- TODO --> | <!-- TODO --> | <!-- TODO --> | <!-- TODO --> | <!-- TODO --> | <!-- TODO --> | <!-- TODO --> |

## Outputs
| Name | Type | Sensitive | Description |
| --- | --- | --- | --- |
| <!-- TODO --> | <!-- TODO --> | <!-- TODO --> | <!-- TODO --> |

# Security Defaults and Exceptions
- Defaults: <!-- TODO: list secure defaults (encryption, least privilege, private by default, etc.) -->
- Exceptions (if any): <!-- TODO: list any deviations and why -->
- Compensating controls: <!-- TODO: list additional controls applied -->

# Plan
1. [ ] Scaffold module via "\$CREATE" and update reqired fealds.
2. [ ] Implement module logic and interface. 
    - <!-- TODO: describe major implementation steps -->
3. [ ] Define outputs. 
    - <!-- TODO: list key outputs to expose -->
4. [ ] Create examples via "\$EXAMPLE" and update reqired fealds. 
    - <!-- TODO: describe example scenarios -->
5. [ ] Generate README via "\$DOCUMENT" and fill template sections. 
    - Create documentation once all validations are successfully completed and development is finished.
    - <!-- TODO: list sections to complete -->

# Example usage
1. Use existing modules from the repository in examples (e.g. iam-role, kms, s3...):
   - <!-- TODO: list modules to compose with -->
2. Types of examples to create:
   - <!-- TODO: basic / advanced -->

# Validation
- [ ] terraform fmt -recursive
- [ ] "\$TEST" -m ${module_name} [-t <basic,advanced>] [-n <example-name>] [-e <examples-root>] [-r <modules-root>]

# Cleanup
- [ ] "\$CLEAN_TF" --quiet modules/${module_name}

# Documentation
- [ ] "\$DOCUMENT" -m ${module_name}
- [ ] Update README.md
- [ ] Update memory-bank
- Notes: <!-- TODO: list any potential problems if any -->

# Risks / Rollback
- Risks: <!-- TODO: list key risks or uncertainties -->
- Rollback plan: <!-- TODO: describe rollback or mitigation steps -->

# Investigation information
Plan is based on investigation for ${module_name}:
<!-- TODO: Summarize findings from investigation steps where you used AWS documentation to find information related to the module. -->
Steps taken and tools used for ${module_name} investigation:
<!-- TODO: List of investigation steps and MCP tools that you used. -->
EOF

echo "Created plan at ${plan_path}" >&2
