#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 -m <module1,module2> -t <root-module-name[,another-name]> [-n <stack-name>] [-e <work-dir>] [-r <modules-root>] [-T <tf-required-version>] [-P <aws-provider-version>] [-f]" >&2
  echo "Example: $0 -m sqs,sns -t messaging-root -n messaging -T ${default_tf_required_version} -P ${default_aws_provider_version}" >&2
}

MODULES_RAW=""
ROOT_NAMES_RAW=""
MODULE_NAME=""
WORK_DIR="examples"
MODULES_ROOT="modules"
FORCE=false

default_tf_required_version=">= 1.14.3"
default_aws_provider_version=">= 6.14.1"

TF_REQUIRED_VERSION="$default_tf_required_version"
AWS_PROVIDER_VERSION="$default_aws_provider_version"

while getopts "m:t:n:e:r:T:P:fh" opt; do
  case "${opt}" in
    m)
      MODULES_RAW="${OPTARG}"
      ;;
    t)
      ROOT_NAMES_RAW="${OPTARG}"
      ;;
    n)
      MODULE_NAME="${OPTARG}"
      ;;
    e)
      WORK_DIR="${OPTARG}"
      ;;
    r)
      MODULES_ROOT="${OPTARG}"
      ;;
    T)
      TF_REQUIRED_VERSION="${OPTARG}"
      ;;
    P)
      AWS_PROVIDER_VERSION="${OPTARG}"
      ;;
    f)
      FORCE=true
      ;;
    h)
      usage
      exit 0
      ;;
    *)
      usage
      exit 1
      ;;
  esac
done

if [[ -z "${MODULES_RAW}" ]]; then
  echo "Error: -m <module1,module2> is required" >&2
  usage
  exit 1
fi

if [[ -z "${ROOT_NAMES_RAW}" ]]; then
  echo "Error: -t <root-module-name[,another-name]> is required" >&2
  usage
  exit 1
fi

IFS=',' read -r -a modules <<< "${MODULES_RAW}"
IFS=',' read -r -a root_names <<< "${ROOT_NAMES_RAW}"

trim() {
  local value="${1}"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "${value}"
}

for i in "${!modules[@]}"; do
  modules[i]="$(trim "${modules[i]}")"
  if [[ -z "${modules[i]}" ]]; then
    echo "Error: empty module name in -m list" >&2
    exit 1
  fi
  if [[ ! -d "${MODULES_ROOT}/${modules[i]}" ]]; then
    echo "Error: module '${modules[i]}' not found under ${MODULES_ROOT}/" >&2
    echo "Create it first with the module creation skill, then rerun." >&2
    exit 1
  fi
done

if [[ -z "${MODULE_NAME}" ]]; then
  MODULE_NAME="$(IFS=-; echo "${modules[*]}")"
fi

valid_root_name() {
  if [[ -z "${1}" ]]; then
    return 1
  fi
  return 0
}

for i in "${!root_names[@]}"; do
  root_names[i]="$(trim "${root_names[i]}")"
  if ! valid_root_name "${root_names[i]}"; then
    echo "Error: empty root module name in -t list" >&2
    exit 1
  fi
done

mkdir -p "${WORK_DIR}"

for root_name in "${root_names[@]}"; do
  stack_dir="${WORK_DIR}/${MODULE_NAME}/${root_name}"

  if [[ -d "${stack_dir}" && "${FORCE}" != true ]]; then
    echo "Error: ${stack_dir} already exists. Use -f to overwrite." >&2
    exit 1
  fi

  rm -rf "${stack_dir}"
  mkdir -p "${stack_dir}"

  cat <<EOF_MAIN > "${stack_dir}/main.tf"
module "meta" {
  source = "../../../modules/meta"

  ...
}
EOF_MAIN

  for mod in "${modules[@]}"; do
    module_label="${mod//-/_}"
    cat <<EOF_MODULE >> "${stack_dir}/main.tf"

module "${module_label}" {
  source = "../../../modules/${mod}"

  # TODO: configure required inputs for ${mod}
  # Example: tags_from_meta = module.naming.tags
}
EOF_MODULE
  done

    cat <<'EOF_LOCALS' > "${stack_dir}/locals.tf"
locals {
  # TODO: add locals and shared settings
}
EOF_LOCALS
    cat <<'EOF_ADV_NOTE' >> "${stack_dir}/main.tf"

# TODO: add advanced wiring between modules and optional features
EOF_ADV_NOTE

  cat <<'EOF_VARIABLES' > "${stack_dir}/variables.tf"
variable "aws_region" {
  description = "AWS region for the example"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}(-[a-z]+)+-\\d$", var.aws_region))
    error_message = "aws_region must be a valid AWS region identifier like 'us-east-1' or 'eu-central-1'."
  }
}
EOF_VARIABLES

  cat <<'EOF_OUTPUTS' > "${stack_dir}/outputs.tf"
# TODO: add outputs as needed
EOF_OUTPUTS

  cat <<EOF_VERSIONS > "${stack_dir}/versions.tf"
terraform {
  required_version = "${TF_REQUIRED_VERSION}"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "${AWS_PROVIDER_VERSION}"
    }
  }

  ### Add after tests are passing: backend "s3" {}
}

provider "aws" {
  region = local.region
  default_tags {
    tags = local.tags
  }
}
EOF_VERSIONS

  modules_list="$(IFS=, ; echo "${modules[*]}")"
  cat <<EOF_README > "${stack_dir}/README.md"
# ${MODULE_NAME} (${root_name})

## Modules
- ${modules_list}

## Notes
- This example uses local modules from modules/.
- Configure module inputs in main.tf.

## Localstack Usage
Set the profile and run Terraform locally. 
Add provider configuration if required by your environment:

export AWS_PROFILE=localstack
terraform -chdir=${stack_dir} init -input=false -no-color
terraform -chdir=${stack_dir} plan -input=false -refresh=false -lock=false -no-color

EOF_README

  echo "Created ${stack_dir}" >&2
done
