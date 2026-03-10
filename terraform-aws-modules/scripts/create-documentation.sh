#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 -m <module_name>" >&2
  echo "Example: $0 -m iam-user" >&2
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

if ! command -v terraform-docs >/dev/null 2>&1; then
  echo "Error: terraform-docs is not installed or not on PATH" >&2
  echo "Install terraform-docs and try again: https://terraform-docs.io/" >&2
  exit 1
fi

module_dir="modules/${module_name}"
readme_path="${module_dir}/README.md"

if [[ ! -d "${module_dir}" ]]; then
  echo "Error: module '${module_name}' not found at '${module_dir}'" >&2
  echo "Create the module first (for example with create-module.sh), then rerun." >&2
  exit 1
fi

# Overwrite README.md with a fresh template
cat > "${readme_path}" <<EOF
# ${module_name} Module

## Metadata
- Owner:
- Last verified:
- Terraform version:
- AWS provider version:

<!-- TODO: Replace this comment with a concise description of what this module manages -->

## When to use it

<!-- TODO: Replace this comment and the bullet points below with concrete scenarios where this module should be used -->
- ...

## Usage Example

```hcl
<!-- TODO: Replace this comment and provide a minimal but complete HCL example for using this module -->
```

## Architecture Notes

<!-- TODO: Replace this comment with key architectural decisions and relationships to other modules or AWS services -->

## Security and Operational Considerations

<!-- TODO: Replace this comment and highlight IAM, encryption, logging, monitoring, and operational practices for this module -->

## Limitations

<!-- TODO: Replace this comment and describe known limitations, edge cases, and non-goals for this module -->

EOF

echo "Created documentation for module '${module_name}' at '${readme_path}'"
