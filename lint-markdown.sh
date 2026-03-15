#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<"EOF"
Usage: lint-markdown.sh [--fix] [DIRECTORY]

Lint Markdown files in the repository using markdownlint-cli2.

If DIRECTORY is provided, lint Markdown files under that directory.
If not provided, defaults to the current directory (.).

Options:
  --fix        Run markdownlint-cli2 with auto-fix enabled.
  -h, --help   Show this help message and exit.

Examples:
  lint-markdown.sh
  lint-markdown.sh ./tf-root-module
  lint-markdown.sh --fix
  lint-markdown.sh --fix ./tf-child-modules
EOF
}

TARGET_DIR="."
FIX_MODE="false"

# Parse arguments
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --fix)
      if [[ "$FIX_MODE" == "true" ]]; then
        echo "Error: --fix specified more than once." >&2
        usage
        exit 1
      fi
      FIX_MODE="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "Error: Unknown option '$1'." >&2
      usage
      exit 1
      ;;
    *)
      if [[ "$TARGET_DIR" != "." ]]; then
        echo "Error: Multiple directory arguments provided." >&2
        usage
        exit 1
      fi
      TARGET_DIR="$1"
      shift
      ;;
  esac
done

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "Error: Directory '$TARGET_DIR' does not exist or is not a directory." >&2
  exit 1
fi

# Ensure markdownlint-cli2 is available
if ! command -v markdownlint-cli2 >/dev/null 2>&1; then
  echo "Error: markdownlint-cli2 is not installed or not in PATH. Install it and try again." >&2
  exit 1
fi

echo "Using markdownlint-cli2"

if [[ "$FIX_MODE" == "true" ]]; then
  echo "Running in auto-fix mode (--fix)"
fi

run_linter() {
  if [[ "$FIX_MODE" == "true" ]]; then
    # Read null-delimited file list from stdin and pass as arguments with auto-fix
    xargs -0 markdownlint-cli2 --fix
  else
    # Read null-delimited file list from stdin and pass as arguments
    xargs -0 markdownlint-cli2
  fi
}

# Check if there are any Markdown files to lint
if ! find "$TARGET_DIR" \
  \( -name .git -o -name node_modules -o -name .terraform \) -prune -o \
  -type f \( -iname '*.md' \) -print -quit | grep -q .; then
  echo "No Markdown files found to lint in $TARGET_DIR"
  exit 0
fi

# Discover Markdown files and run the linter
find "$TARGET_DIR" \
  \( -name .git -o -name node_modules -o -name .terraform \) -prune -o \
  -type f \( -iname '*.md' \) -print0 | \
  run_linter
