#!/usr/bin/env bash
set -euo pipefail

# Default versions (can be overridden via CLI flags)
DEFAULT_TF_REQUIRED_VERSION=">= 1.14.3"
DEFAULT_AWS_PROVIDER_VERSION=">= 6.14.1"

tf_required_version="$DEFAULT_TF_REQUIRED_VERSION"
aws_provider_version="$DEFAULT_AWS_PROVIDER_VERSION"

usage() {
  echo "Usage: $0 -m <module_name> [-rv <tf_required_version>] [-av <aws_provider_version>]" >&2
  echo "Example: $0 -m iam-user" >&2
  echo "Example: $0 -m iam-user -rv '>= 1.6.0' -av '>= 6.20.0'" >&2
}

module_name=""

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
    -rv|--required-version)
      if [[ $# -lt 2 ]]; then
        echo "Error: -rv|--required-version requires a value" >&2
        usage
        exit 1
      fi
      tf_required_version="$2"
      shift 2
      ;;
    -av|--aws-version)
      if [[ $# -lt 2 ]]; then
        echo "Error: -av|--aws-version requires a value" >&2
        usage
        exit 1
      fi
      aws_provider_version="$2"
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

module_dir="modules/${module_name}"

# If module directory already exists, skip creation and stop
if [[ -d "${module_dir}" ]]; then
  echo "Module '${module_name}' already exists at '${module_dir}'. Skipping creation." >&2
  exit 0
fi

# Create module skeleton directory
mkdir -p "${module_dir}"

# TODO comments in non-versions files
todo_comment="# TODO: configure required inputs for ${module_name}"

# main.tf
printf '%s\n\n' "${todo_comment}" > "${module_dir}/main.tf"

# variables.tf
printf '%s\n\n' "${todo_comment}" > "${module_dir}/variables.tf"

# outputs.tf
printf '%s\n\n' "${todo_comment}" > "${module_dir}/outputs.tf"

# versions.tf with overridable versions
cat > "${module_dir}/versions.tf" <<EOF
terraform {
  required_version = "${tf_required_version}"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "${aws_provider_version}"
    }
  }
}
EOF

echo "Created ${module_dir}"
