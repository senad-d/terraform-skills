#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<USAGE
Usage: $0 -t <type> [-m <module_name>] [-g <short_goal>]

Types:
  new-module    Create a plan for new resources/modules
  edit-module   Create a plan for modifying existing resources/modules
  architecture  Create a plan for architecture planning

Options:
  -t, --type    Plan type (required)
  -m, --module  Module name (required for new-module/edit-module)
  -g, --goal    Short goal (optional)
  -h, --help    Show this help and exit

Examples:
  $0 -t new-module -m iam-role -g 'Create IAM role module'
  $0 -t edit-module -m vpc -g 'Adjust subnet layout'
  $0 -t architecture -g 'Shared networking baseline'
USAGE
}

plan_type=""
module_name=""
goal=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--type)
      if [[ $# -lt 2 ]]; then
        echo "Error: -t|--type requires a value" >&2
        usage
        exit 1
      fi
      plan_type="$2"
      shift 2
      ;;
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

if [[ -z "${plan_type}" ]]; then
  echo "Error: plan type is required" >&2
  usage
  exit 1
fi

case "${plan_type}" in
  new-module|edit-module|architecture)
    ;;
  *)
    echo "Error: invalid plan type '${plan_type}'" >&2
    usage
    exit 1
    ;;
esac

if [[ "${plan_type}" == "new-module" || "${plan_type}" == "edit-module" ]]; then
  if [[ -z "${module_name}" ]]; then
    echo "Error: module name is required for type '${plan_type}'" >&2
    usage
    exit 1
  fi
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
templates_dir="${script_dir}/../templates/plan"

case "${plan_type}" in
  new-module)
    template_file="${templates_dir}/PLAN_NEW_TEMPLATE.md"
    ;;
  edit-module)
    template_file="${templates_dir}/PLAN_EDIT_TEMPLATE.md"
    ;;
  architecture)
    template_file="${templates_dir}/PLAN_ARCHITECTURE_TEMPLATE.md"
    ;;
esac

if [[ ! -f "${template_file}" ]]; then
  echo "Error: template file not found: ${template_file}" >&2
  exit 1
fi

plan_dir="Plan"
install -d "${plan_dir}"

slug="architecture-$RANDOM"
if [[ "${plan_type}" == "new-module" || "${plan_type}" == "edit-module" ]]; then
  slug="${module_name//[^a-zA-Z0-9-]/-}"
fi

plan_date="$(date +%Y%m%d)"
plan_path="${plan_dir}/${plan_date}-${slug}.md"

template_content="$(cat "${template_file}")"
template_content="${template_content//\{\{plan_type\}\}/${plan_type}}"
if [[ -n "${module_name}" ]]; then
  template_content="${template_content//\{\{module_name\}\}/${module_name}}"
fi
template_content="${template_content//\{\{goal\}\}/${goal}}"

printf '%s\n' "${template_content}" > "${plan_path}"

echo "Created plan at ${plan_path}" >&2
