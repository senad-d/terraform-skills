#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<EOF
Usage: $0 -d <directory> [-n <name-pattern>]

Options:
  -d, --directory <dir>     Root directory to scan for modules (required)
  -n, --name-pattern <pat>  ripgrep pattern to filter module paths
  -h, --help                Show this help and exit

Notes:
  - Treats each immediate subdirectory of the root directory as a module.
  - Uses fd/fdfind when available, otherwise falls back to 'find'.
  - Uses jq for JSON construction; output is a single JSON document on stdout.
EOF
}

root_dir=""
name_pattern=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--directory)
      if [[ $# -lt 2 ]]; then
        echo "Error: -d|--directory requires a value" >&2
        usage
        exit 1
      fi
      root_dir="$2"
      shift 2
      ;;
    -n|--name-pattern)
      if [[ $# -lt 2 ]]; then
        echo "Error: -n|--name-pattern requires a value" >&2
        usage
        exit 1
      fi
      name_pattern="$2"
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

if [[ -z "${root_dir}" ]]; then
  echo "Error: directory is required" >&2
  usage
  exit 1
fi

if [[ ! -d "${root_dir}" ]]; then
  echo "Error: directory does not exist or is not a directory: ${root_dir}" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required but not found in PATH" >&2
  exit 1
fi

list_dirs_cmd=("find" "${root_dir}" "-mindepth" "1" "-maxdepth" "1" "-type" "d")

if command -v fd >/dev/null 2>&1; then
  list_dirs_cmd=("fd" "-t" "d" "." "${root_dir}" "--max-depth" "1")
elif command -v fdfind >/dev/null 2>&1; then
  list_dirs_cmd=("fdfind" "-t" "d" "." "${root_dir}" "--max-depth" "1")
fi

module_list=""
if [[ -n "${name_pattern}" ]]; then
  if ! command -v rg >/dev/null 2>&1; then
    echo "Error: ripgrep (rg) is required for --name-pattern filtering" >&2
    exit 1
  fi
  module_list="$("${list_dirs_cmd[@]}" | rg "${name_pattern}" || true)"
else
  module_list="$("${list_dirs_cmd[@]}" || true)"
fi

modules_json_tmp="$(mktemp)"
trap 'rm -f "${modules_json_tmp}"' EXIT

module_count=0

root_abs="$(cd "${root_dir}" && pwd)"
root_dir_norm="${root_dir%/}"

if [[ -n "${module_list}" ]]; then
  while IFS= read -r module_path; do
    [[ -z "${module_path}" ]] && continue

    if [[ ! -d "${module_path}" ]]; then
      continue
    fi

    if [[ "${module_path%/}" == "${root_dir_norm}" ]]; then
      continue
    fi

    if [[ "${module_path}" == "${root_dir_norm}"* ]]; then
      rel_path="${module_path#"${root_dir_norm}/"}"
    else
      rel_path="${module_path}"
    fi

    module_files_json=$(
      cd "${module_path}" || exit 1
      if command -v fd >/dev/null 2>&1; then
        fd -t f . || true
      elif command -v fdfind >/dev/null 2>&1; then
        fdfind -t f . || true
      else
        find . -type f -print | sed 's|^\./||' || true
      fi | jq -R -s 'split("\n") - [""]'
    )

    jq -n \
      --arg path "${rel_path}" \
      --argjson files "${module_files_json}" \
      '{path: $path, files: $files}' >> "${modules_json_tmp}"
    echo >> "${modules_json_tmp}"

    module_count=$((module_count + 1))
  done <<< "${module_list}"
fi

json_output=$(jq -n \
  --arg root "${root_abs}" \
  --arg generated_at "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
  --argjson module_count "${module_count}" \
  --slurpfile modules "${modules_json_tmp}" \
  '{root: $root, generated_at: $generated_at, module_count: $module_count, modules: $modules}')

echo "${json_output}"
