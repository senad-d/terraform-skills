#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<EOF
Usage: $0 -d <directory> [-n <name-pattern>]

Options:
  -d, --directory <dir>     Root directory to search (required)
  -n, --name-pattern <pat>  ripgrep pattern to filter file paths
  -h, --help                Show this help and exit

Notes:
  - Uses fd/fdfind when available, otherwise falls back to 'rg --files'.
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

list_files_cmd=("rg" "--files" "${root_dir}")

if command -v fd >/dev/null 2>&1; then
  list_files_cmd=("fd" "-t" "f" "." "${root_dir}")
elif command -v fdfind >/dev/null 2>&1; then
  list_files_cmd=("fdfind" "-t" "f" "." "${root_dir}")
else
  if ! command -v rg >/dev/null 2>&1; then
    echo "Error: neither fd/fdfind nor rg is available for file discovery" >&2
    exit 1
  fi
  list_files_cmd=("rg" "--files" "${root_dir}")
fi

file_list=""
if [[ -n "${name_pattern}" ]]; then
  if ! command -v rg >/dev/null 2>&1; then
    echo "Error: ripgrep (rg) is required for --name-pattern filtering" >&2
    exit 1
  fi
  file_list="$("${list_files_cmd[@]}" | rg "${name_pattern}" || true)"
else
  file_list="$("${list_files_cmd[@]}" || true)"
fi

files_json_tmp="$(mktemp)"
trap 'rm -f "${files_json_tmp}"' EXIT

file_count=0

root_abs="$(cd "${root_dir}" && pwd)"

if [[ -n "${file_list}" ]]; then
  while IFS= read -r file_path; do
    [[ -z "${file_path}" ]] && continue

    if [[ ! -f "${file_path}" ]]; then
      continue
    fi

    if [[ "${file_path}" == "${root_dir}"* ]]; then
      rel_path="${file_path#"${root_dir%/}"/}"
    else
      rel_path="${file_path}"
    fi

    jq -n \
      --arg path "${rel_path}" \
      --arg content "$(cat "${file_path}")" \
      '{path: $path, content: $content}' >> "${files_json_tmp}"
    echo >> "${files_json_tmp}"

    file_count=$((file_count + 1))
  done <<< "${file_list}"
fi

json_output=$(jq -n \
  --arg root "${root_abs}" \
  --arg generated_at "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
  --argjson file_count "${file_count}" \
  --slurpfile files "${files_json_tmp}" \
  '{root: $root, generated_at: $generated_at, file_count: $file_count, files: $files}')

echo "${json_output}"
