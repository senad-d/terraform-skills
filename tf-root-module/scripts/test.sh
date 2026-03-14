#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 -m <module_directory> [--plan <true|false>]" >&2
  echo "Example: $0 -m networking --plan false" >&2
}

module_dir=""
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
      module_dir="$2"
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

if [[ -z "${module_dir}" ]]; then
  echo "Error: module directory is required" >&2
  usage
  exit 1
fi

if [[ ! -d "${module_dir}" ]]; then
  echo "Error: module directory '${module_dir}' does not exist" >&2
  exit 1
fi

if command -v tflint >/dev/null 2>&1; then
  tflint_available="true"
else
  echo "Warning: tflint not found. Skipping tflint checks. Install it with: brew install tflint" >&2
fi

if command -v tfsec >/dev/null 2>&1; then
  tfsec_available="true"
else
  echo "Warning: tfsec not found. Skipping tfsec checks. Install it with: brew install tfsec" >&2
fi

echo "# Terraform test for module directory \`${module_dir}\`"
echo

echo "Module directory: \`${module_dir}\`"
echo

echo "## Setting AWS Profile for localstack"

export AWS_PROFILE=localstack

echo

echo '## Running: terraform fmt -recursive'

echo '```text'
terraform fmt -recursive

echo '```'

echo

echo "## Running: terraform -chdir=${module_dir} init -backend=false"
echo '```text'
terraform -chdir="${module_dir}" init -backend=false
echo '```'

echo

echo "## Running: terraform -chdir=${module_dir} validate -no-color"
echo '```text'
terraform -chdir="${module_dir}" validate -no-color
echo '```'

echo

if [[ "${tfsec_available}" == "true" ]]; then
  echo "## Running: tfsec (in ${module_dir})"
  echo '```text'
  (
    cd "${module_dir}"
    tfsec .
  )
  echo '```'
  echo
else
  echo "## Skipping: tfsec (not installed)"
  echo
fi

if [[ "${tflint_available}" == "true" ]]; then
  echo "## Running: tflint (in ${module_dir})"
  echo '```text'
  (
    cd "${module_dir}"
    tflint --recursive
  )
  echo '```'
  echo
else
  echo "## Skipping: tflint (not installed)"
  echo
fi

if [[ "${plan_enabled}" == "true" ]]; then
  echo "## Running: terraform -chdir=${module_dir} plan -input=false -refresh=false -lock=false"
  echo '```text'
  terraform -chdir="${module_dir}" plan -input=false -refresh=false -lock=false
  echo '```'
  echo
else
  echo "## Skipping: terraform plan (disabled via --plan=false)"
  echo
fi
