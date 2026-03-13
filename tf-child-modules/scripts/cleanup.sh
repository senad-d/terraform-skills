#!/bin/sh

# Terraform cleanup
#
# MAIN_DIR is the base directory to search under.
# Optional SUBDIR arguments are relative subdirectories under MAIN_DIR
# that restrict the cleanup. When SUBDIRs are provided, each effective
# search root is MAIN_DIR/SUBDIR.

# ---------------------------------------------------------------------------
# Logging levels
# ---------------------------------------------------------------------------
LOG_LEVEL_ERROR=0
LOG_LEVEL_INFO=1
LOG_LEVEL_DEBUG=2

CURRENT_LOG_LEVEL=$LOG_LEVEL_INFO

# ---------------------------------------------------------------------------
# Global state
# ---------------------------------------------------------------------------
DRY_RUN=0

deleted_dirs=0
deleted_files=0
failed_deletions=0
had_errors=0

# ---------------------------------------------------------------------------
# Logging helpers
# ---------------------------------------------------------------------------
log_error() {
    {
        printf '%s' "[ERROR]"
        if [ "$#" -gt 0 ]; then
            printf ' %s' "$@"
        fi
        printf '\n'
    } >&2
}

log_info() {
    if [ "$CURRENT_LOG_LEVEL" -lt "$LOG_LEVEL_INFO" ]; then
        return 0
    fi
    {
        printf '%s' "[INFO]"
        if [ "$#" -gt 0 ]; then
            printf ' %s' "$@"
        fi
        printf '\n'
    }
}

log_debug() {
    if [ "$CURRENT_LOG_LEVEL" -lt "$LOG_LEVEL_DEBUG" ]; then
        return 0
    fi
    {
        printf '%s' "[DEBUG]"
        if [ "$#" -gt 0 ]; then
            printf ' %s' "$@"
        fi
        printf '\n'
    }
}

# ---------------------------------------------------------------------------
# Usage / help
# ---------------------------------------------------------------------------
print_usage() {
    cat <<EOF
Usage: $0 [--dry-run] [--log-level LEVEL | --debug | --quiet] MAIN_DIR [SUBDIR ...]

Options:
  --dry-run          Do not delete anything, only report planned deletions
  --log-level LEVEL  One of: error, info, debug (case-insensitive). Default: info
  --debug            Shortcut for --log-level=debug
  --quiet            Shortcut for --log-level=error
  -h, --help         Show this help and exit

Arguments:
  MAIN_DIR           Base directory to scan for Terraform artifacts
  SUBDIR ...         Optional relative subdirectories under MAIN_DIR to restrict
                     cleanup. If provided, each effective root is MAIN_DIR/SUBDIR.

Examples:
  $0 --dry-run /path/to/project
  $0 --log-level debug /path/to/project cloudfront ecs lambda
  $0 --quiet /path/to/project config
EOF
}

# ---------------------------------------------------------------------------
# Log level parsing
# ---------------------------------------------------------------------------
set_log_level_from_name() {
    level_name=$1
    level_name_lc=$(printf '%s' "$level_name" | tr '[:upper:]' '[:lower:]')

    case $level_name_lc in
        error)
            CURRENT_LOG_LEVEL=$LOG_LEVEL_ERROR
            ;;
        info)
            CURRENT_LOG_LEVEL=$LOG_LEVEL_INFO
            ;;
        debug)
            CURRENT_LOG_LEVEL=$LOG_LEVEL_DEBUG
            ;;
        *)
            log_error "Invalid log level: $level_name (expected: error, info, debug)"
            print_usage >&2
            exit 1
            ;;
    esac
}

# ---------------------------------------------------------------------------
# Deletion helpers
# ---------------------------------------------------------------------------
delete_terraform_dir() {
    dir_path=$1

    if [ "$DRY_RUN" -eq 1 ]; then
        log_info "DRY-RUN would remove directory: $dir_path"
        deleted_dirs=$((deleted_dirs + 1))
        return 0
    fi

    if rm -rf -- "$dir_path"; then
        deleted_dirs=$((deleted_dirs + 1))
        log_info "Removed directory: $dir_path"
    else
        failed_deletions=$((failed_deletions + 1))
        had_errors=1
        log_error "Failed to remove directory: $dir_path"
    fi
}

delete_lock_file() {
    file_path=$1

    if [ "$DRY_RUN" -eq 1 ]; then
        log_info "DRY-RUN would remove file: $file_path"
        deleted_files=$((deleted_files + 1))
        return 0
    fi

    if rm -f -- "$file_path"; then
        deleted_files=$((deleted_files + 1))
        log_info "Removed file: $file_path"
    else
        failed_deletions=$((failed_deletions + 1))
        had_errors=1
        log_error "Failed to remove file: $file_path"
    fi
}

# ---------------------------------------------------------------------------
# Artifact processing
# ---------------------------------------------------------------------------
process_path() {
    path=$1

    base_name=$(basename -- "$path" 2>/dev/null || basename "$path")

    if [ -d "$path" ] && [ "$base_name" = ".terraform" ]; then
        log_debug "Matched Terraform directory: $path"
        delete_terraform_dir "$path"
    elif [ -f "$path" ] && [ "$base_name" = ".terraform.lock.hcl" ]; then
        log_debug "Matched Terraform lock file: $path"
        delete_lock_file "$path"
    else
        log_debug "Skipping unexpected path (not a Terraform artifact): $path"
    fi
}

# ---------------------------------------------------------------------------
# Root scanning
# ---------------------------------------------------------------------------
scan_root() {
    root=$1

    log_debug "Scanning root: $root"
    log_debug "Pruning standard directories (.git, .svn, .hg, .idea, .vscode, node_modules, venv, .venv, dist, build, target) under: $root"

    tmp_matches=$(mktemp "${TMPDIR:-/tmp}/tf_cleanup.matches.XXXXXX" 2>/dev/null || printf '%s' "")
    if [ -z "$tmp_matches" ]; then
        log_error "Failed to create temporary file for matches"
        had_errors=1
        return 1
    fi

    find "$root" \
        \( -type d \
           \( -name .git -o -name .svn -o -name .hg -o -name .idea -o -name .vscode \
              -o -name node_modules -o -name venv -o -name .venv -o -name dist -o -name build -o -name target \) \
        \) -prune -o \
        \( \( -type d -a -name .terraform \) -o \( -type f -a -name .terraform.lock.hcl \) \) \
        -print0 >"$tmp_matches"

    find_status=$?
    if [ "$find_status" -ne 0 ]; then
        had_errors=1
        log_error "find reported an error while scanning: $root (exit status $find_status)"
    fi

    if [ -s "$tmp_matches" ]; then
        while IFS= read -r -d "" path; do
            process_path "$path"
        done <"$tmp_matches"
    fi

    rm -f -- "$tmp_matches" 2>/dev/null || :

    return "$find_status"
}

# ---------------------------------------------------------------------------
# Summary reporting
# ---------------------------------------------------------------------------
print_summary() {
    if [ "$DRY_RUN" -eq 1 ]; then
        log_info "Dry run complete."
        log_info "Directories that will be removed: $deleted_dirs"
        log_info "Files that will be removed: $deleted_files"
        log_info "Failed deletions: $failed_deletions"
    else
        log_info "Cleanup complete."
        log_info "Directories removed: $deleted_dirs"
        log_info "Files removed: $deleted_files"
        log_info "Failed deletions: $failed_deletions"
    fi
}

# ---------------------------------------------------------------------------
# Main cleanup orchestration
# ---------------------------------------------------------------------------
perform_cleanup() {
    main_dir=$1
    shift

    if [ ! -d "$main_dir" ]; then
        log_error "Main project directory not found: $main_dir"
        exit 1
    fi

    if [ "$#" -eq 0 ]; then
        log_debug "No subdirectories specified; scanning entire main directory: $main_dir"
        scan_root "$main_dir" || had_errors=1
    else
        while [ "$#" -gt 0 ]; do
            subdir=$1
            shift
            root="$main_dir/$subdir"

            if [ ! -d "$root" ]; then
                log_error "Specified directory not found: $root"
                exit 1
            fi

            log_debug "Scanning specified subdirectory root: $root"
            scan_root "$root" || had_errors=1
        done
    fi
}

# ---------------------------------------------------------------------------
# Argument parsing and entrypoint
# ---------------------------------------------------------------------------
main() {
    DRY_RUN=0
    CURRENT_LOG_LEVEL=$LOG_LEVEL_INFO
    deleted_dirs=0
    deleted_files=0
    failed_deletions=0
    had_errors=0

    while [ "$#" -gt 0 ]; do
        case $1 in
            --dry-run)
                DRY_RUN=1
                ;;
            --log-level)
                if [ "$#" -lt 2 ]; then
                    log_error "Missing value for --log-level"
                    print_usage >&2
                    exit 1
                fi
                set_log_level_from_name "$2"
                shift
                ;;
            --log-level=*)
                level_value=${1#--log-level=}
                if [ -z "$level_value" ]; then
                    log_error "Missing value for --log-level"
                    print_usage >&2
                    exit 1
                fi
                set_log_level_from_name "$level_value"
                ;;
            --debug)
                set_log_level_from_name "debug"
                ;;
            --quiet)
                set_log_level_from_name "error"
                ;;
            -h|--help)
                print_usage
                exit 0
                ;;
            --)
                shift
                break
                ;;
            -*)
                log_error "Unknown option: $1"
                print_usage >&2
                exit 1
                ;;
            *)
                break
                ;;
        esac
        shift
    done

    if [ "$#" -lt 1 ]; then
        log_error "No main project directory specified."
        print_usage >&2
        exit 1
    fi

    main_dir=$1
    shift

    if [ "$DRY_RUN" -eq 1 ]; then
        log_info "Starting Terraform cleanup (dry run) in: $main_dir"
    else
        log_info "Starting Terraform cleanup in: $main_dir"
    fi

    perform_cleanup "$main_dir" "$@"

    print_summary

    if [ "$had_errors" -ne 0 ]; then
        exit 1
    fi

    exit 0
}

main "$@"
