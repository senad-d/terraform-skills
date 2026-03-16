#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 -m <module1,module2> [-t <basic,advanced>] [-n <example-name>] [-e <examples-root>] [-r <modules-root>] [-t <tf-required-version>] [-p <aws-provider-version>] [-f]" >&2
  echo "Example: $0 -m sqs,sns -t basic,advanced -n messaging -t ${default_tf_required_version} -p ${default_aws_provider_version}" >&2
}

MODULES_RAW=""
TYPES_RAW="basic"
EXAMPLE_NAME=""
EXAMPLES_ROOT="examples"
MODULES_ROOT="modules"
FORCE=false

default_tf_required_version=">= 1.14.3"
default_aws_provider_version=">= 6.14.1"

TF_REQUIRED_VERSION="$default_tf_required_version"
AWS_PROVIDER_VERSION="$default_aws_provider_version"

while getopts "m:t:n:e:r:fh" opt; do
  case "${opt}" in
    m)
      MODULES_RAW="${OPTARG}"
      ;;
    t)
      TYPES_RAW="${OPTARG}"
      ;;
    n)
      EXAMPLE_NAME="${OPTARG}"
      ;;
    e)
      EXAMPLES_ROOT="${OPTARG}"
      ;;
    r)
      MODULES_ROOT="${OPTARG}"
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

IFS=',' read -r -a modules <<< "${MODULES_RAW}"
IFS=',' read -r -a types <<< "${TYPES_RAW}"

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

if [[ -z "${EXAMPLE_NAME}" ]]; then
  EXAMPLE_NAME="$(IFS=-; echo "${modules[*]}")"
fi

valid_type() {
  case "${1}" in
    basic|advanced)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

for i in "${!types[@]}"; do
  types[i]="$(trim "${types[i]}")"
  if [[ -z "${types[i]}" ]]; then
    echo "Error: empty example type in -t list" >&2
    exit 1
  fi
  if ! valid_type "${types[i]}"; then
    echo "Error: unsupported example type '${types[i]}' (use basic or advanced)" >&2
    exit 1
  fi
done

mkdir -p "${EXAMPLES_ROOT}"

for example_type in "${types[@]}"; do
  example_dir="${EXAMPLES_ROOT}/${EXAMPLE_NAME}/${example_type}"

  if [[ -d "${example_dir}" && "${FORCE}" != true ]]; then
    echo "Error: ${example_dir} already exists. Use -f to overwrite." >&2
    exit 1
  fi

  rm -rf "${example_dir}"
  mkdir -p "${example_dir}"

  cat <<EOF_MAIN > "${example_dir}/main.tf"
provider "aws" {
  region = var.aws_region
}

locals {
  meta = {
    owner       = "example"
    environment = "dev"
    basename    = "glue"
  }
}

module "meta" {
  source = "../../../modules/meta"
  meta   = local.meta
}
EOF_MAIN

  for mod in "${modules[@]}"; do
    module_label="${mod//-/_}"
    cat <<EOF_MODULE >> "${example_dir}/main.tf"

module "${module_label}" {
  source = "../../../modules/${mod}"

  # TODO: configure required inputs for ${mod}
  # Example: tags_from_meta = module.naming.tags
}
EOF_MODULE
  done

  if [[ "${example_type}" == "advanced" ]]; then
    cat <<'EOF_LOCALS' > "${example_dir}/locals.tf"
locals {
  # TODO: add advanced locals and shared settings
}
EOF_LOCALS
    cat <<'EOF_ADV_NOTE' >> "${example_dir}/main.tf"

# TODO: add advanced wiring between modules and optional features
EOF_ADV_NOTE
  fi

  cat <<'EOF_VARIABLES' > "${example_dir}/variables.tf"
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

  cat <<'EOF_OUTPUTS' > "${example_dir}/outputs.tf"
# TODO: add outputs as needed
EOF_OUTPUTS

  cat <<EOF_VERSIONS > "${example_dir}/versions.tf"
terraform {
  required_version = "${tf_required_version}"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "${aws_provider_version}"
    }
  }
}
EOF_VERSIONS

  modules_list="$(IFS=, ; echo "${modules[*]}")"
  cat <<EOF_README > "${example_dir}/README.md"
# ${EXAMPLE_NAME} (${example_type})

## Modules
- ${modules_list}

## Notes
- This example uses local modules from modules/.
- Configure module inputs in main.tf.

## Localstack Usage
Set the profile and run Terraform locally. 
Add provider configuration if required by your environment:

export AWS_PROFILE=localstack
terraform -chdir=${example_dir} init -input=false -no-color
terraform -chdir=${example_dir} plan -input=false -refresh=false -lock=false -no-color

EOF_README

  echo "Created ${example_dir}" >&2
done
