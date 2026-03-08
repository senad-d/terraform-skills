#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 -m <module_name> [-t <example_type> ...] [--plan <true|false>]" >&2
  echo "Example: $0 -m iam-user -t basic -t full --plan false" >&2
}

module_name=""
example_types=()
plan_enabled="true"
tflint_available="false"
tfsec_available="false"

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
    -t|--type)
      if [[ $# -lt 2 ]]; then
        echo "Error: -t|--type requires a value" >&2
        usage
        exit 1
      fi
      example_types+=("$2")
      shift 2
      ;;
    -p|--plan)
      if [[ $# -lt 2 ]]; then
        echo "Error: -p|--plan requires a value (true or false)" >&2
        usage
        exit 1
      fi
      case "$2" in
        true|false)
          plan_enabled="$2"
          ;;
        *)
          echo "Error: --plan must be 'true' or 'false'" >&2
          usage
          exit 1
          ;;
      esac
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

# Default example type if none provided
if [[ ${#example_types[@]} -eq 0 ]]; then
  example_types=("basic")
fi

# Verify all example directories exist before running any Terraform commands
for example_type in "${example_types[@]}"; do
  example_dir="examples/${module_name}/${example_type}"
  if [[ ! -d "${example_dir}" ]]; then
    echo "Error: ${example_dir} does not exist" >&2
    exit 1
  fi
done

# Detect tflint availability once and guide installation if missing
if command -v tflint >/dev/null 2>&1; then
  tflint_available="true"
else
  echo "Warning: tflint not found. Skipping tflint checks. Install it with: brew install tflint" >&2
fi

# Detect tfsec availability once and guide installation if missing
if command -v tfsec >/dev/null 2>&1; then
  tfsec_available="true"
else
  echo "Warning: tfsec not found. Skipping tfsec checks. Install it with: brew install tfsec" >&2
fi

# --- Markdown header ---

echo "# Terraform test for module \`${module_name}\`"
echo

# Join example types for display
if [[ ${#example_types[@]} -gt 0 ]]; then
  IFS=", " read -r -a _tmp <<< "${example_types[*]}"
  echo "Examples: \`$(printf "%s" "${_tmp[*]}")\`"
  unset _tmp
  echo
fi

echo "## Setting AWS Profile for localstack"

export AWS_PROFILE=localstack

echo

echo '## Running: terraform fmt -recursive'

echo '```text'
terraform fmt -recursive
# raw terraform fmt output is preserved as-is

echo '```'

echo

# Run init/validate/tfsec/tflint/plan for each example type
for example_type in "${example_types[@]}"; do
  example_dir="examples/${module_name}/${example_type}"

  echo "## Example: ${example_type}"
  echo

  echo "### Running: terraform -chdir=${example_dir} init -backend=false"
  echo '```text'
  terraform -chdir="${example_dir}" init -backend=false
  # raw terraform init output is preserved as-is
  echo '```'
  echo

  echo "### Running: terraform -chdir=${example_dir} validate -no-color"
  echo '```text'
  terraform -chdir="${example_dir}" validate -no-color
  # raw terraform validate output is preserved as-is
  echo '```'
  echo

  if [[ "${tfsec_available}" == "true" ]]; then
    echo "### Running: tfsec (in ${example_dir})"
    echo '```text'
    (
      cd "${example_dir}"
      tfsec .
    )
    echo '```'
    echo
  else
    echo "### Skipping: tfsec (not installed)"
    echo
  fi

  if [[ "${tflint_available}" == "true" ]]; then
    echo "### Running: tflint (in ${example_dir})"
    echo '```text'
    (
      cd "${example_dir}"
      tflint
    )
    echo '```'
    echo
  else
    echo "### Skipping: tflint (not installed)"
    echo
  fi

  if [[ "${plan_enabled}" == "true" ]]; then
    echo "### Running: terraform -chdir=${example_dir} plan -input=false -refresh=false -lock=false"
    echo '```text'
    terraform -chdir="${example_dir}" plan -input=false -refresh=false -lock=false
    # raw terraform plan output is preserved as-is
    echo '```'
    echo
  else
    echo "### Skipping: terraform plan (disabled via --plan=false)"
    echo
  fi

done
