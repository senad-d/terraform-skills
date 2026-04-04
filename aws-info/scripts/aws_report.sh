#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly VERSION="0.1.0"

readonly UNSET="__UNSET__"

LOG_LEVEL="INFO"
LOG_FILE=""
SPLIT_TSV_FIELDS=()
WARNINGS_FILE=""

log_level_rank() {
  case "$1" in
    ERROR) echo 0 ;;
    WARN) echo 1 ;;
    INFO) echo 2 ;;
    DEBUG) echo 3 ;;
    *) echo 2 ;;
  esac
}

log() {
  local level="$1"
  local section="$2"
  shift 2
  local msg="$*"
  local now
  now="$(date -u '+%Y-%m-%d %H:%M:%SZ')"
  local current_rank wanted_rank
  current_rank="$(log_level_rank "${LOG_LEVEL}")"
  wanted_rank="$(log_level_rank "${level}")"
  if [[ "${wanted_rank}" -le "${current_rank}" ]]; then
    local line="${now} ${level} [${section}] ${msg}"
    printf '%s\n' "${line}" >&2
    if [[ -n "${LOG_FILE}" ]]; then
      printf '%s\n' "${line}" >> "${LOG_FILE}"
    fi
  fi
}

die() {
  log "ERROR" "core" "$*"
  exit 1
}

usage() {
  cat <<EOF_USAGE
Usage: ${SCRIPT_NAME} [options]

Required (conditional on enabled sections):
  -i, --tls-input <file>    TLS targets file (required if TLS enabled)
  -k, --tag-key <key>       Tag key for network inventory (required if Network enabled)
  -v, --tag-value <value>   Tag value for network inventory (required if Network enabled)

AWS Context:
  -p, --profile <name>      AWS profile (default: AWS_PROFILE or default)
  -r, --region <region>     AWS region (default: AWS_REGION/AWS_DEFAULT_REGION or default)

Output:
  -o, --output <file>       Output file
  --format <markdown|json>  Output format (default: markdown)
  --overwrite               Allow overwriting output file
  --log-level <LEVEL>       ERROR|WARN|INFO|DEBUG (default: INFO)
  --log-file <file>         Log file (default: stderr only)

Cost Options:
  -n, --top-n <number>              Top N services (1-100, default: 10)
  --include-record-types <list>    Comma-separated record types to include
  --exclude-record-types <list>    Comma-separated record types to exclude

IAM Options:
  --iam-mode <fast|full>    Default: fast

TLS Options:
  --tls-timeout <seconds>   Default: 5 (1-60)
  --tls-parallel <number>   Default: 32 (1-128)

Section Selection:
  --only <list>             Comma-separated: cost,iam,tls,network
  --skip <list>             Comma-separated: cost,iam,tls,network
  --parallel-sections       Run enabled sections in parallel

Config:
  --config <file>           JSON config file

General:
  -h, --help                Show this help and exit
  --version                 Show version and exit

Examples:
  ./${SCRIPT_NAME} -i <file> -p <name> -r <region> -k <key> -v <value>  
  ./${SCRIPT_NAME} --only cost
  ./${SCRIPT_NAME} --only iam --iam-mode full
  ./${SCRIPT_NAME} --only tls -i ./tls_info/links --tls-timeout 10 --tls-parallel 64
  ./${SCRIPT_NAME} --only network -k Environment -v prod
  ./${SCRIPT_NAME} --skip tls,network
  ./${SCRIPT_NAME} --include-record-types Credit,Refund --only cost
  ./${SCRIPT_NAME} --only cost --format json --output ./aws_report.json --overwrite
  ./${SCRIPT_NAME} --output ./aws_report.md --overwrite --log-level DEBUG \
    --log-file ./aws_report.log
  ./${SCRIPT_NAME} --config ./report_config.json
EOF_USAGE
}

require_cmd() {
  local cmd="$1"
  command -v "${cmd}" >/dev/null 2>&1 || die "${cmd} not found in PATH"
}

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

md_escape() {
  local v="$1"
  v="${v//|/\\|}"
  printf '%s' "${v}"
}

split_tsv_line() {
  local line="$1"
  SPLIT_TSV_FIELDS=()
  local rest="$line"
  local field
  while true; do
    if [[ "${rest}" == *$'\t'* ]]; then
      field="${rest%%$'\t'*}"
      SPLIT_TSV_FIELDS+=("${field}")
      rest="${rest#*$'\t'}"
    else
      SPLIT_TSV_FIELDS+=("${rest}")
      break
    fi
  done
}

render_table() {
  local title="$1"
  local header_tsv="$2"
  shift 2
  local -a rows=("$@")

  printf '### %s\n\n' "${title}"
  split_tsv_line "${header_tsv}"
  local -a header_cols=("${SPLIT_TSV_FIELDS[@]}")

  local header_line="|"
  local sep_line="|"
  local idx
  for ((idx = 0; idx < ${#header_cols[@]}; idx++)); do
    header_line+=" $(md_escape "${header_cols[idx]}") |"
    sep_line+=" --- |"
  done
  printf '%s\n' "${header_line}"
  printf '%s\n' "${sep_line}"

  for row in "${rows[@]}"; do
    [[ -z "${row}" || "${row}" == "None" ]] && continue
    split_tsv_line "${row}"
    local -a cols=("${SPLIT_TSV_FIELDS[@]}")
    local line="|"
    for ((idx = 0; idx < ${#header_cols[@]}; idx++)); do
      local cell="${cols[idx]-}"
      line+=" $(md_escape "${cell}") |"
    done
    printf '%s\n' "${line}"
  done
  printf '\n'
}

render_table_body() {
  local header_tsv="$1"
  shift
  local -a rows=("$@")

  split_tsv_line "${header_tsv}"
  local -a header_cols=("${SPLIT_TSV_FIELDS[@]}")

  local header_line="|"
  local sep_line="|"
  local idx
  for ((idx = 0; idx < ${#header_cols[@]}; idx++)); do
    header_line+=" $(md_escape "${header_cols[idx]}") |"
    sep_line+=" --- |"
  done
  printf '%s\n' "${header_line}"
  printf '%s\n' "${sep_line}"

  for row in "${rows[@]}"; do
    [[ -z "${row}" || "${row}" == "None" ]] && continue
    split_tsv_line "${row}"
    local -a cols=("${SPLIT_TSV_FIELDS[@]}")
    local line="|"
    for ((idx = 0; idx < ${#header_cols[@]}; idx++)); do
      local cell="${cols[idx]-}"
      line+=" $(md_escape "${cell}") |"
    done
    printf '%s\n' "${line}"
  done
  printf '\n'
}

render_table_json() {
  local title="$1"
  local header_tsv="$2"
  shift 2
  local -a rows=("$@")
  local -a filtered_rows=()
  local row
  for row in "${rows[@]}"; do
    [[ -z "${row}" || "${row}" == "None" ]] && continue
    filtered_rows+=("${row}")
  done

  local tmp_file
  tmp_file="$(mktemp)"
  if [[ ${#filtered_rows[@]} -gt 0 ]]; then
    printf '%s\n' "${filtered_rows[@]}" > "${tmp_file}"
  fi
  jq -Rn --arg title "${title}" --arg header "${header_tsv}" '
    def split_tsv: split("\t");
    {title: $title, headers: ($header | split_tsv), rows: [inputs | split_tsv]}
  ' < "${tmp_file}"
  rm -f "${tmp_file}"
}

write_json_metadata() {
  local out_file="$1"
  local ts
  ts="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  local tag_line
  if [[ -n "${TAG_KEY}" && -n "${TAG_VALUE}" ]]; then
    tag_line="${TAG_KEY}=${TAG_VALUE}"
  else
    tag_line="none"
  fi
  jq -n \
    --arg generated "${ts}" \
    --arg profile "${PROFILE}" \
    --arg region "${AWS_REGION}" \
    --arg tag_filter "${tag_line}" \
    '{
      metadata: {
        generated: $generated,
        profile: $profile,
        region: $region,
        tag_filter: $tag_filter
      }
    }' > "${out_file}"
}

write_json_warnings() {
  local out_file="$1"
  if [[ "${#WARNINGS[@]}" -eq 0 ]]; then
    printf '%s\n' '{}' > "${out_file}"
    return 0
  fi
  local tmp_file
  tmp_file="$(mktemp)"
  local item
  for item in "${WARNINGS[@]}"; do
    local section cls msg
    IFS='|' read -r section cls msg <<< "${item}"
    section="$(trim "${section}")"
    cls="$(trim "${cls}")"
    msg="$(trim "${msg}")"
    printf '%s\t%s\t%s\n' "${section}" "${cls}" "${msg}" >> "${tmp_file}"
  done
  jq -Rn '
    [inputs | split("\t") | {section: .[0], error: .[1], message: .[2]}]
    | {warnings: .}
  ' < "${tmp_file}" > "${out_file}"
  rm -f "${tmp_file}"
}

readonly DEFAULT_TOP_N=10
readonly DEFAULT_TLS_TIMEOUT=5
readonly DEFAULT_TLS_PARALLEL=32
readonly DEFAULT_IAM_MODE="fast"
readonly DEFAULT_EXCLUDE_TYPES="Credit,Refund,Tax"

CONFIG_FILE="${UNSET}"

TLS_INPUT="${UNSET}"
TAG_KEY="${UNSET}"
TAG_VALUE="${UNSET}"

PROFILE="${UNSET}"
AWS_REGION="${UNSET}"

OUTPUT_FILE="${UNSET}"
OUTPUT_FORMAT="${UNSET}"
OVERWRITE="false"
PARALLEL_SECTIONS="false"

TOP_N="${UNSET}"
INCLUDE_RECORD_TYPES="${UNSET}"
EXCLUDE_RECORD_TYPES="${UNSET}"
IAM_MODE="${UNSET}"
TLS_TIMEOUT="${UNSET}"
TLS_PARALLEL="${UNSET}"

ONLY_SECTIONS="${UNSET}"
SKIP_SECTIONS="${UNSET}"

CONFIG_TLS_INPUT="${UNSET}"
CONFIG_TAG_KEY="${UNSET}"
CONFIG_TAG_VALUE="${UNSET}"
CONFIG_PROFILE="${UNSET}"
CONFIG_AWS_REGION="${UNSET}"
CONFIG_OUTPUT_FILE="${UNSET}"
CONFIG_OUTPUT_FORMAT="${UNSET}"
CONFIG_TOP_N="${UNSET}"
CONFIG_INCLUDE_RECORD_TYPES="${UNSET}"
CONFIG_EXCLUDE_RECORD_TYPES="${UNSET}"
CONFIG_IAM_MODE="${UNSET}"
CONFIG_TLS_TIMEOUT="${UNSET}"
CONFIG_TLS_PARALLEL="${UNSET}"
CONFIG_ONLY_SECTIONS="${UNSET}"
CONFIG_SKIP_SECTIONS="${UNSET}"
CONFIG_LOG_LEVEL="${UNSET}"
CONFIG_LOG_FILE="${UNSET}"
CONFIG_OVERWRITE="${UNSET}"
CONFIG_PARALLEL_SECTIONS="${UNSET}"

parse_config() {
  [[ "${CONFIG_FILE}" == "${UNSET}" ]] && return 0
  [[ -z "${CONFIG_FILE}" ]] && return 0
  [[ ! -f "${CONFIG_FILE}" ]] && die "Config file not found: ${CONFIG_FILE}"
  require_cmd jq

  local value
  value="$(jq -r '.tls_input // empty' "${CONFIG_FILE}")"
  [[ -n "${value}" ]] && CONFIG_TLS_INPUT="${value}"
  value="$(jq -r '.tag_key // empty' "${CONFIG_FILE}")"
  [[ -n "${value}" ]] && CONFIG_TAG_KEY="${value}"
  value="$(jq -r '.tag_value // empty' "${CONFIG_FILE}")"
  [[ -n "${value}" ]] && CONFIG_TAG_VALUE="${value}"
  value="$(jq -r '.profile // empty' "${CONFIG_FILE}")"
  [[ -n "${value}" ]] && CONFIG_PROFILE="${value}"
  value="$(jq -r '.region // empty' "${CONFIG_FILE}")"
  [[ -n "${value}" ]] && CONFIG_AWS_REGION="${value}"
  value="$(jq -r '.output // empty' "${CONFIG_FILE}")"
  [[ -n "${value}" ]] && CONFIG_OUTPUT_FILE="${value}"
  value="$(jq -r '.format // empty' "${CONFIG_FILE}")"
  [[ -n "${value}" ]] && CONFIG_OUTPUT_FORMAT="${value}"
  value="$(jq -r '.top_n // empty' "${CONFIG_FILE}")"
  [[ -n "${value}" ]] && CONFIG_TOP_N="${value}"
  value="$(jq -r '.include_record_types // empty' "${CONFIG_FILE}")"
  [[ -n "${value}" ]] && CONFIG_INCLUDE_RECORD_TYPES="${value}"
  value="$(jq -r '.exclude_record_types // empty' "${CONFIG_FILE}")"
  [[ -n "${value}" ]] && CONFIG_EXCLUDE_RECORD_TYPES="${value}"
  value="$(jq -r '.iam_mode // empty' "${CONFIG_FILE}")"
  [[ -n "${value}" ]] && CONFIG_IAM_MODE="${value}"
  value="$(jq -r '.tls_timeout // empty' "${CONFIG_FILE}")"
  [[ -n "${value}" ]] && CONFIG_TLS_TIMEOUT="${value}"
  value="$(jq -r '.tls_parallel // empty' "${CONFIG_FILE}")"
  [[ -n "${value}" ]] && CONFIG_TLS_PARALLEL="${value}"
  value="$(jq -r '.only // empty' "${CONFIG_FILE}")"
  [[ -n "${value}" ]] && CONFIG_ONLY_SECTIONS="${value}"
  value="$(jq -r '.skip // empty' "${CONFIG_FILE}")"
  [[ -n "${value}" ]] && CONFIG_SKIP_SECTIONS="${value}"
  value="$(jq -r '.log_level // empty' "${CONFIG_FILE}")"
  [[ -n "${value}" ]] && CONFIG_LOG_LEVEL="${value}"
  value="$(jq -r '.log_file // empty' "${CONFIG_FILE}")"
  [[ -n "${value}" ]] && CONFIG_LOG_FILE="${value}"
  value="$(jq -r 'if has("overwrite") then (.overwrite|tostring) else empty end' \
    "${CONFIG_FILE}")"
  [[ -n "${value}" ]] && CONFIG_OVERWRITE="${value}"
  value="$(jq -r 'if has("parallel_sections") then (.parallel_sections|tostring) else empty end' \
    "${CONFIG_FILE}")"
  [[ -n "${value}" ]] && CONFIG_PARALLEL_SECTIONS="${value}"
  return 0
}

parse_args() {
  local args=("$@")
  local i=0
  while [[ ${i} -lt ${#args[@]} ]]; do
    case "${args[i]}" in
      -i|--tls-input)
        TLS_INPUT="${args[i+1]:-}"; i=$((i+2)) ;;
      -k|--tag-key)
        TAG_KEY="${args[i+1]:-}"; i=$((i+2)) ;;
      -v|--tag-value)
        TAG_VALUE="${args[i+1]:-}"; i=$((i+2)) ;;
      -p|--profile)
        PROFILE="${args[i+1]:-}"; i=$((i+2)) ;;
      -r|--region)
        AWS_REGION="${args[i+1]:-}"; i=$((i+2)) ;;
      -o|--output)
        OUTPUT_FILE="${args[i+1]:-}"; i=$((i+2)) ;;
      --format)
        OUTPUT_FORMAT="${args[i+1]:-}"; i=$((i+2)) ;;
      --overwrite)
        OVERWRITE="true"; i=$((i+1)) ;;
      --log-level)
        LOG_LEVEL="${args[i+1]:-}"; i=$((i+2)) ;;
      --log-file)
        LOG_FILE="${args[i+1]:-}"; i=$((i+2)) ;;
      --parallel|--parallel-sections)
        PARALLEL_SECTIONS="true"; i=$((i+1)) ;;
      -n|--top-n)
        TOP_N="${args[i+1]:-}"; i=$((i+2)) ;;
      --include-record-types)
        INCLUDE_RECORD_TYPES="${args[i+1]:-}"; i=$((i+2)) ;;
      --exclude-record-types)
        EXCLUDE_RECORD_TYPES="${args[i+1]:-}"; i=$((i+2)) ;;
      --iam-mode)
        IAM_MODE="${args[i+1]:-}"; i=$((i+2)) ;;
      --tls-timeout)
        TLS_TIMEOUT="${args[i+1]:-}"; i=$((i+2)) ;;
      --tls-parallel)
        TLS_PARALLEL="${args[i+1]:-}"; i=$((i+2)) ;;
      --only)
        ONLY_SECTIONS="${args[i+1]:-}"; i=$((i+2)) ;;
      --skip)
        SKIP_SECTIONS="${args[i+1]:-}"; i=$((i+2)) ;;
      --config)
        CONFIG_FILE="${args[i+1]:-}"; i=$((i+2)) ;;
      -h|--help)
        usage; exit 0 ;;
      --version)
        printf '%s\n' "${VERSION}"; exit 0 ;;
      *)
        die "Unknown argument: ${args[i]}" ;;
    esac
  done
}

apply_precedence() {
  local env_profile="${AWS_PROFILE:-}"
  local env_region="${AWS_REGION:-${AWS_DEFAULT_REGION:-}}"

  [[ "${TLS_INPUT}" == "${UNSET}" ]] && TLS_INPUT="${CONFIG_TLS_INPUT}"
  [[ "${TLS_INPUT}" == "${UNSET}" ]] && TLS_INPUT=""

  [[ "${TAG_KEY}" == "${UNSET}" ]] && TAG_KEY="${CONFIG_TAG_KEY}"
  [[ "${TAG_KEY}" == "${UNSET}" ]] && TAG_KEY=""

  [[ "${TAG_VALUE}" == "${UNSET}" ]] && TAG_VALUE="${CONFIG_TAG_VALUE}"
  [[ "${TAG_VALUE}" == "${UNSET}" ]] && TAG_VALUE=""

  [[ "${PROFILE}" == "${UNSET}" ]] && PROFILE="${CONFIG_PROFILE}"
  [[ "${PROFILE}" == "${UNSET}" ]] && PROFILE="${env_profile}"
  [[ "${PROFILE}" == "${UNSET}" ]] && PROFILE="default"

  [[ "${AWS_REGION}" == "${UNSET}" ]] && AWS_REGION="${CONFIG_AWS_REGION}"
  [[ "${AWS_REGION}" == "${UNSET}" ]] && AWS_REGION="${env_region}"
  [[ "${AWS_REGION}" == "${UNSET}" ]] && AWS_REGION="default"

  [[ "${OUTPUT_FILE}" == "${UNSET}" ]] && OUTPUT_FILE="${CONFIG_OUTPUT_FILE}"
  [[ "${OUTPUT_FILE}" == "${UNSET}" ]] && OUTPUT_FILE=""

  [[ "${OUTPUT_FORMAT}" == "${UNSET}" ]] && OUTPUT_FORMAT="${CONFIG_OUTPUT_FORMAT}"
  [[ "${OUTPUT_FORMAT}" == "${UNSET}" ]] && OUTPUT_FORMAT="markdown"

  [[ "${TOP_N}" == "${UNSET}" ]] && TOP_N="${CONFIG_TOP_N}"
  [[ "${TOP_N}" == "${UNSET}" ]] && TOP_N="${DEFAULT_TOP_N}"

  [[ "${INCLUDE_RECORD_TYPES}" == "${UNSET}" ]] && \
    INCLUDE_RECORD_TYPES="${CONFIG_INCLUDE_RECORD_TYPES}"
  [[ "${INCLUDE_RECORD_TYPES}" == "${UNSET}" ]] && INCLUDE_RECORD_TYPES=""

  [[ "${EXCLUDE_RECORD_TYPES}" == "${UNSET}" ]] && \
    EXCLUDE_RECORD_TYPES="${CONFIG_EXCLUDE_RECORD_TYPES}"
  [[ "${EXCLUDE_RECORD_TYPES}" == "${UNSET}" ]] && \
    EXCLUDE_RECORD_TYPES="${DEFAULT_EXCLUDE_TYPES}"

  [[ "${IAM_MODE}" == "${UNSET}" ]] && IAM_MODE="${CONFIG_IAM_MODE}"
  [[ "${IAM_MODE}" == "${UNSET}" ]] && IAM_MODE="${DEFAULT_IAM_MODE}"

  [[ "${TLS_TIMEOUT}" == "${UNSET}" ]] && TLS_TIMEOUT="${CONFIG_TLS_TIMEOUT}"
  [[ "${TLS_TIMEOUT}" == "${UNSET}" ]] && TLS_TIMEOUT="${DEFAULT_TLS_TIMEOUT}"

  [[ "${TLS_PARALLEL}" == "${UNSET}" ]] && TLS_PARALLEL="${CONFIG_TLS_PARALLEL}"
  [[ "${TLS_PARALLEL}" == "${UNSET}" ]] && TLS_PARALLEL="${DEFAULT_TLS_PARALLEL}"

  [[ "${ONLY_SECTIONS}" == "${UNSET}" ]] && \
    ONLY_SECTIONS="${CONFIG_ONLY_SECTIONS}"
  [[ "${ONLY_SECTIONS}" == "${UNSET}" ]] && ONLY_SECTIONS=""

  [[ "${SKIP_SECTIONS}" == "${UNSET}" ]] && \
    SKIP_SECTIONS="${CONFIG_SKIP_SECTIONS}"
  [[ "${SKIP_SECTIONS}" == "${UNSET}" ]] && SKIP_SECTIONS=""

  if [[ "${LOG_LEVEL}" == "INFO" ]]; then
    [[ "${CONFIG_LOG_LEVEL}" != "${UNSET}" ]] && LOG_LEVEL="${CONFIG_LOG_LEVEL}"
  fi
  if [[ -z "${LOG_FILE}" && "${CONFIG_LOG_FILE}" != "${UNSET}" ]]; then
    LOG_FILE="${CONFIG_LOG_FILE}"
  fi
  if [[ "${CONFIG_OVERWRITE}" != "${UNSET}" && "${OVERWRITE}" == "false" ]];
  then
    OVERWRITE="${CONFIG_OVERWRITE}"
  fi
  if [[ "${CONFIG_PARALLEL_SECTIONS}" != "${UNSET}" && \
    "${PARALLEL_SECTIONS}" == "false" ]]; then
    PARALLEL_SECTIONS="${CONFIG_PARALLEL_SECTIONS}"
  fi
}

split_list() {
  local value="$1"
  local -a items=()
  local item
  IFS=',' read -r -a items <<< "${value}"
  for item in "${items[@]}"; do
    item="${item// /}"
    [[ -n "${item}" ]] && printf '%s\n' "${item}"
  done
}

validate_sections() {
  local list_value="$1"
  local section
  while IFS= read -r section; do
    case "${section}" in
      cost|iam|tls|network) ;;
      *) die "Invalid section: ${section}" ;;
    esac
  done < <(split_list "${list_value}")
}

ENABLE_COST="true"
ENABLE_IAM="true"
ENABLE_TLS="true"
ENABLE_NETWORK="true"

apply_section_selection() {
  if [[ -n "${ONLY_SECTIONS}" ]]; then
    validate_sections "${ONLY_SECTIONS}"
    ENABLE_COST="false"
    ENABLE_IAM="false"
    ENABLE_TLS="false"
    ENABLE_NETWORK="false"
    local section
    while IFS= read -r section; do
      case "${section}" in
        cost) ENABLE_COST="true" ;;
        iam) ENABLE_IAM="true" ;;
        tls) ENABLE_TLS="true" ;;
        network) ENABLE_NETWORK="true" ;;
      esac
    done < <(split_list "${ONLY_SECTIONS}")
    return
  fi

  if [[ -n "${SKIP_SECTIONS}" ]]; then
    validate_sections "${SKIP_SECTIONS}"
    local section
    while IFS= read -r section; do
      case "${section}" in
        cost) ENABLE_COST="false" ;;
        iam) ENABLE_IAM="false" ;;
        tls) ENABLE_TLS="false" ;;
        network) ENABLE_NETWORK="false" ;;
      esac
    done < <(split_list "${SKIP_SECTIONS}")
  fi
}

validate_inputs() {
  case "${LOG_LEVEL}" in
    ERROR|WARN|INFO|DEBUG) ;;
    *) die "--log-level must be ERROR, WARN, INFO, or DEBUG" ;;
  esac
  if ! [[ "${TOP_N}" =~ ^[0-9]+$ ]] || [[ "${TOP_N}" -lt 1 || "${TOP_N}" -gt 100 ]]
  then
    die "--top-n must be 1-100"
  fi
  if ! [[ "${TLS_TIMEOUT}" =~ ^[0-9]+$ ]] || \
     [[ "${TLS_TIMEOUT}" -lt 1 || "${TLS_TIMEOUT}" -gt 60 ]]
  then
    die "--tls-timeout must be 1-60"
  fi
  if ! [[ "${TLS_PARALLEL}" =~ ^[0-9]+$ ]] || \
     [[ "${TLS_PARALLEL}" -lt 1 || "${TLS_PARALLEL}" -gt 128 ]]
  then
    die "--tls-parallel must be 1-128"
  fi
  case "${IAM_MODE}" in
    fast|full) ;;
    *) die "--iam-mode must be fast or full" ;;
  esac
  case "${PARALLEL_SECTIONS}" in
    true|false) ;;
    *) die "--parallel-sections must be true or false" ;;
  esac
  case "${OUTPUT_FORMAT}" in
    markdown|json) ;;
    *) die "--format must be markdown or json" ;;
  esac

  if [[ "${ENABLE_TLS}" == "true" ]]; then
    [[ -z "${TLS_INPUT}" ]] && die "TLS section requires --tls-input"
    [[ ! -f "${TLS_INPUT}" ]] && die "TLS input file not found: ${TLS_INPUT}"
  fi
  if [[ "${ENABLE_NETWORK}" == "true" ]]; then
    [[ -z "${TAG_KEY}" || -z "${TAG_VALUE}" ]] && \
      die "Network section requires --tag-key and --tag-value"
  fi

  if [[ -z "${OUTPUT_FILE}" ]]; then
    local ts
    ts="$(date -u '+%Y%m%dT%H%M%SZ')"
    if [[ "${OUTPUT_FORMAT}" == "json" ]]; then
      OUTPUT_FILE="${SCRIPT_DIR}/aws_consolidated_report_${ts}.json"
    else
      OUTPUT_FILE="${SCRIPT_DIR}/aws_consolidated_report_${ts}.md"
    fi
  fi
  if [[ -f "${OUTPUT_FILE}" && "${OVERWRITE}" != "true" ]]; then
    die "Output file exists: ${OUTPUT_FILE} (use --overwrite to replace)"
  fi
}

require_dependencies() {
  require_cmd aws
  require_cmd jq
  if [[ "${ENABLE_TLS}" == "true" ]]; then
    require_cmd openssl
    if ! has_cmd timeout && ! has_cmd gtimeout; then
      die "timeout (or gtimeout) is required for TLS probes"
    fi
  fi
  if [[ "${ENABLE_COST}" == "true" ]]; then
    if ! has_cmd python3 && ! has_cmd gdate && ! date -d "1970-01-01" >/dev/null 2>&1;
    then
      die "python3 or GNU date (gdate) is required for cost date calculations"
    fi
  fi
}

AWS_BASE=(aws --no-cli-pager)

aws_call() {
  local section="$1"
  shift
  local err_file out
  err_file="$(mktemp)"
  if ! out="$("${AWS_BASE[@]}" "$@" --output json 2>"${err_file}")"; then
    local err
    err="$(<"${err_file}")"
    rm -f "${err_file}"
    if [[ "${err}" == *AccessDenied* || "${err}" == *AuthFailure* || \
          "${err}" == *UnrecognizedClientException* ]]; then
      log "ERROR" "${section}" "AWS auth error: ${err}"
      exit 2
    fi
    log "WARN" "${section}" "AWS call failed: aws $* :: ${err}"
    return 1
  fi
  rm -f "${err_file}"
  printf '%s' "${out}"
}

aws_call_optional() {
  local section="$1"
  shift
  local err_file out
  err_file="$(mktemp)"
  if ! out="$("${AWS_BASE[@]}" "$@" --output json 2>"${err_file}")"; then
    local err
    err="$(<"${err_file}")"
    rm -f "${err_file}"
    if [[ "${err}" == *AccessDenied* || "${err}" == *AuthFailure* || \
          "${err}" == *UnrecognizedClientException* ]]; then
      log "ERROR" "${section}" "AWS auth error: ${err}"
      exit 2
    fi
    return 1
  fi
  rm -f "${err_file}"
  printf '%s' "${out}"
}

aws_call_retry() {
  local section="$1"
  shift
  local attempt=0
  local max_attempts=5
  local delay=1
  local out
  while [[ ${attempt} -lt ${max_attempts} ]]; do
    if out="$(aws_call "${section}" "$@")"; then
      printf '%s' "${out}"
      return 0
    fi
    if [[ ${attempt} -ge 4 ]]; then
      return 1
    fi
    sleep "${delay}"
    delay=$((delay * 2))
    attempt=$((attempt + 1))
  done
  return 1
}

WARNINGS=()
PARTIAL_FAILURE="false"

add_warning() {
  local section="$1"
  local cls="$2"
  local msg="$3"
  if [[ -n "${WARNINGS_FILE:-}" ]]; then
    printf '%s | %s | %s\n' "${section}" "${cls}" "${msg}" >> "${WARNINGS_FILE}"
    PARTIAL_FAILURE="true"
    return 0
  fi
  WARNINGS+=("${section} | ${cls} | ${msg}")
  PARTIAL_FAILURE="true"
}

write_global_header() {
  local out_file="$1"
  local ts
  ts="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  local tag_line
  if [[ -n "${TAG_KEY}" && -n "${TAG_VALUE}" ]]; then
    tag_line="${TAG_KEY}=${TAG_VALUE}"
  else
    tag_line="none"
  fi

  {
    echo "# AWS Consolidated Report"
    echo
    echo "- Generated: ${ts}"
    echo "- AWS Profile: ${PROFILE}"
    echo "- AWS Region: ${AWS_REGION}"
    echo "- Tag Filter: ${tag_line}"
    echo
  } > "${out_file}"
}

write_warnings() {
  local out_file="$1"
  if [[ "${#WARNINGS[@]}" -eq 0 ]]; then
    return 0
  fi
  # shellcheck disable=SC2129
  {
    echo "## Warnings"
    echo
    echo "| Section | Error | Message |"
    echo "|---|---|---|"
    local item
    for item in "${WARNINGS[@]}"; do
      IFS='|' read -r section cls msg <<< "${item}"
      echo "| $(md_escape "${section}") | $(md_escape "${cls}") | $(md_escape "${msg}") |"
    done
    echo
  } >> "${out_file}"
}

# ------------------- Cost Section -------------------

calculate_cost_windows() {
  local base_start base_end comp_start comp_end
  if has_cmd python3; then
    IFS=$'\t' read -r base_start base_end comp_start comp_end < <(
      python3 - <<'PY'
from datetime import datetime, timedelta
now = datetime.utcnow().date()
first_this = now.replace(day=1)
comp_start = (first_this - timedelta(days=1)).replace(day=1)
base_start = (comp_start - timedelta(days=1)).replace(day=1)
base_end = comp_start
comp_end = first_this
print(base_start.isoformat(), base_end.isoformat(), comp_start.isoformat(),
      comp_end.isoformat(), sep="\t")
PY
    )
  else
    local dc
    if has_cmd gdate; then
      dc="gdate"
    else
      dc="date"
    fi
    local first_this
    first_this="$(${dc} -u +"%Y-%m-01")"
    comp_start="$(${dc} -u -d "${first_this} -1 month" +"%Y-%m-01")"
    base_start="$(${dc} -u -d "${comp_start} -1 month" +"%Y-%m-01")"
    base_end="${comp_start}"
    comp_end="${first_this}"
  fi
  printf '%s\t%s\t%s\t%s' "${base_start}" "${base_end}" \
    "${comp_start}" "${comp_end}"
}

render_cost_section() {
  local out_file="$1"
  log "INFO" "cost" "Collecting Cost Explorer data"

  local windows
  windows="$(calculate_cost_windows)"
  local base_start base_end comp_start comp_end
  IFS=$'\t' read -r base_start base_end comp_start comp_end <<< "${windows}"
  if [[ -z "${base_start}" || -z "${comp_start}" ]]; then
    add_warning "Cost" "window" "Failed to calculate cost windows"
    return 1
  fi

  local cost_region
  if [[ "${AWS_REGION}" == "default" ]]; then
    cost_region="us-east-1"
  else
    cost_region="${AWS_REGION}"
  fi

  local filter_json=""
  if [[ -n "${INCLUDE_RECORD_TYPES}" ]]; then
    filter_json=$(jq -n --arg list "${INCLUDE_RECORD_TYPES}" '
      {Dimensions:{Key:"RECORD_TYPE",Values:($list|split(","))}}')
  else
    local exclude_list
    exclude_list="${EXCLUDE_RECORD_TYPES}"
    filter_json=$(jq -n --arg list "${exclude_list}" '
      {Not:{Dimensions:{Key:"RECORD_TYPE",Values:($list|split(","))}}}')
  fi

  local tmp_dir
  tmp_dir="$(mktemp -d)"
  local responses_file="${tmp_dir}/responses.jsonl"
  : > "${responses_file}"

  local token=""
  while :; do
    local response
    local args=(
      ce get-cost-and-usage
      --time-period "Start=${base_start},End=${comp_end}"
      --granularity MONTHLY
      --metrics "UnblendedCost"
      --group-by "Type=DIMENSION,Key=SERVICE"
      --region "${cost_region}"
    )
    if [[ -n "${token}" ]]; then
      args+=(--next-page-token "${token}")
    fi
    if ! response="$(aws_call_retry "cost" "${args[@]}" --filter "${filter_json}")"; then
      add_warning "Cost" "aws" "Failed to fetch cost data"
      rm -rf "${tmp_dir}"
      return 1
    fi
    printf '%s\n' "${response}" >> "${responses_file}"
    token="$(jq -r '.NextPageToken // empty' <<< "${response}")"
    [[ -z "${token}" ]] && break
  done

  local combined="${tmp_dir}/combined.json"
  jq -s '{ResultsByTime: (map(.ResultsByTime) | add)}' \
    "${responses_file}" > "${combined}"

  local tsv="${tmp_dir}/cost.tsv"
  jq -r '.ResultsByTime[] as $r |
    $r.TimePeriod.Start as $start |
    $r.Groups[]? |
    [$start, .Keys[0], (.Metrics.UnblendedCost.Amount|tonumber)] | @tsv' \
    "${combined}" > "${tsv}"

  local total_current
  total_current="$(awk -F$'\t' -v comp="${comp_start}" '\
    $1==comp {sum+=$3} END {printf "%.6f", sum}' "${tsv}")"

  local data_file="${tmp_dir}/data.tsv"
  awk -F$'\t' -v base="${base_start}" -v comp="${comp_start}" '\
    {svc=$2; amt=$3+0; if ($1==base) h[svc]+=amt; if ($1==comp) c[svc]+=amt;
     s[svc]=1} END {for (svc in s) {hval=h[svc]+0; cval=c[svc]+0;
     d=cval-hval; printf "%s\t%.6f\t%.6f\t%.6f\n", svc, hval, cval, d}}' \
    "${tsv}" > "${data_file}"

  local record_types_excluded="none"
  local record_types_included=""
  if [[ -n "${INCLUDE_RECORD_TYPES}" ]]; then
    record_types_included="${INCLUDE_RECORD_TYPES}"
  else
    record_types_excluded="${EXCLUDE_RECORD_TYPES}"
  fi

  if [[ "${OUTPUT_FORMAT}" == "markdown" ]]; then
    {
      echo "## Cost Report"
      echo
      echo "- Current: ${comp_start} to ${comp_end}"
      echo "- Historical: ${base_start} to ${base_end}"
      echo "- Record types excluded: ${record_types_excluded}"
      echo "## Summary"
      echo
    } >> "${out_file}"
  fi

  local current_total
  current_total="$(awk -F$'\t' -v comp="${comp_start}" '\
    $1==comp {sum+=$3} END {printf "%.2f", sum}' "${tsv}")"
  local historical_total
  historical_total="$(awk -F$'\t' -v base="${base_start}" '\
    $1==base {sum+=$3} END {printf "%.2f", sum}' "${tsv}")"
  local delta_total
  delta_total="$(awk -v c="${current_total}" -v h="${historical_total}" \
    'BEGIN {printf "%.2f", c-h}')"

  if [[ "${OUTPUT_FORMAT}" == "markdown" ]]; then
    {
      echo "- Current: \$${current_total}"
      echo "- Historical: \$${historical_total}"
      echo "- Change vs historical: \$${delta_total}"
      echo
    } >> "${out_file}"
  fi

  local spenders_file="${tmp_dir}/spenders.tsv"
  sort -t$'\t' -k3,3nr "${data_file}" | head -n "${TOP_N}" > "${spenders_file}"

  local -a spend_rows=()
  local line
  while IFS=$'\t' read -r svc hist curr delta; do
    local pct
    local cost_fmt
    if [[ "${total_current}" == "0" || "${total_current}" == "0.000000" ]]; then
      pct="0.0%"
    else
      pct="$(awk -v c="${curr}" -v t="${total_current}" \
        'BEGIN {printf "%.1f%%", (c/t)*100}')"
    fi
    cost_fmt="$(printf '%.2f' "${curr}")"
    spend_rows+=("${svc}"$'\t'"\$${cost_fmt}"$'\t'"${pct}")
  done < "${spenders_file}"

  local increases_file="${tmp_dir}/increases.tsv"
  awk -F$'\t' '$4>0.000001' "${data_file}" | sort -t$'\t' -k4,4nr \
    | head -n "${TOP_N}" > "${increases_file}"

  local -a inc_rows=()
  while IFS=$'\t' read -r svc hist curr delta; do
    local pct_change
    local hist_fmt curr_fmt delta_fmt
    if awk -v h="${hist}" 'BEGIN {exit (h<0.01)?0:1}'; then
      pct_change="new"
    else
      pct_change="$(awk -v d="${delta}" -v h="${hist}" \
        'BEGIN {printf "%.1f%%", (d/h)*100}')"
    fi
    hist_fmt="$(printf '%.2f' "${hist}")"
    curr_fmt="$(printf '%.2f' "${curr}")"
    delta_fmt="$(printf '%.2f' "${delta}")"
    inc_rows+=("${svc}"$'\t'"\$${hist_fmt}"$'\t'"\$${curr_fmt}"$'\t'"\$${delta_fmt}"$'\t'"${pct_change}")
  done < "${increases_file}"

  local more_file="${tmp_dir}/more.tsv"
  awk -F$'\t' '$4>0.000001' "${data_file}" | sort -t$'\t' -k4,4nr > "${more_file}"

  local -a more_rows=()
  while IFS=$'\t' read -r svc hist curr delta; do
    local pct_change
    local delta_fmt
    if awk -v h="${hist}" 'BEGIN {exit (h<0.01)?0:1}'; then
      pct_change="new"
    else
      pct_change="$(awk -v d="${delta}" -v h="${hist}" \
        'BEGIN {printf "%.1f%%", (d/h)*100}')"
    fi
    delta_fmt="$(printf '%.2f' "${delta}")"
    more_rows+=("${svc}"$'\t'"\$${delta_fmt}"$'\t'"${pct_change}")
  done < "${more_file}"

  if [[ "${OUTPUT_FORMAT}" == "markdown" ]]; then
    {
      render_table "Top ${TOP_N} Spenders" $'Service\tCost\t% of Total' \
        "${spend_rows[@]}"

      render_table "Top ${TOP_N} Absolute Increases" \
        $'Service\tHistorical\tCurrent\tDelta\t% Change' "${inc_rows[@]}"

      render_table "Spending More" $'Service\tDelta\t% Change' \
        "${more_rows[@]}"
    } >> "${out_file}"
  else
    local -a table_jsons=()
    table_jsons+=("$(render_table_json "Top ${TOP_N} Spenders" \
      $'Service\tCost\t% of Total' "${spend_rows[@]}")")
    table_jsons+=("$(render_table_json "Top ${TOP_N} Absolute Increases" \
      $'Service\tHistorical\tCurrent\tDelta\t% Change' "${inc_rows[@]}")")
    table_jsons+=("$(render_table_json "Spending More" \
      $'Service\tDelta\t% Change' "${more_rows[@]}")")

    local tables_json="[]"
    if [[ ${#table_jsons[@]} -gt 0 ]]; then
      tables_json="$(printf '%s\n' "${table_jsons[@]}" | jq -s '.')"
    fi

    jq -n \
      --arg current_period "${comp_start} to ${comp_end}" \
      --arg historical_period "${base_start} to ${base_end}" \
      --arg record_types_excluded "${record_types_excluded}" \
      --arg record_types_included "${record_types_included}" \
      --arg current_total "${current_total}" \
      --arg historical_total "${historical_total}" \
      --arg delta_total "${delta_total}" \
      --argjson tables "${tables_json}" \
      '{
        cost: {
          summary: {
            current_period: $current_period,
            historical_period: $historical_period,
            record_types_excluded: $record_types_excluded,
            record_types_included: $record_types_included,
            current_total: ($current_total | tonumber),
            historical_total: ($historical_total | tonumber),
            delta_total: ($delta_total | tonumber)
          },
          tables: $tables
        }
      }' > "${out_file}"
  fi

  rm -rf "${tmp_dir}"
  return 0
}

# ------------------- IAM Section -------------------

epoch_from_iso() {
  local iso="$1"
  if has_cmd python3; then
    python3 - "${iso}" <<'PY'
from datetime import datetime
import sys
iso = sys.argv[1]
try:
    dt = datetime.fromisoformat(iso.replace('Z', '+00:00'))
except ValueError:
    dt = datetime.strptime(iso, '%Y-%m-%dT%H:%M:%S%z')
print(int(dt.timestamp()))
PY
  elif has_cmd gdate; then
    gdate -u -d "${iso}" +%s
  else
    date -u -j -f "%Y-%m-%dT%H:%M:%S%z" "${iso}" +%s
  fi
}

days_since() {
  local iso="$1"
  local now_epoch
  now_epoch="$(date -u +%s)"
  local then_epoch
  then_epoch="$(epoch_from_iso "${iso}")"
  if [[ -z "${then_epoch}" ]]; then
    printf ''
    return 0
  fi
  echo $(( (now_epoch - then_epoch) / 86400 ))
}

redact_key() {
  local key="$1"
  if [[ "${#key}" -le 8 ]]; then
    echo "${key}"
  else
    echo "${key:0:4}********${key: -4}"
  fi
}

render_iam_section() {
  local out_file="$1"
  log "INFO" "iam" "Collecting IAM data"

  local identity_json
  if ! identity_json="$(aws_call_retry "iam" sts get-caller-identity)"; then
    add_warning "IAM" "aws" "Failed to get caller identity"
    return 1
  fi
  local account_id
  account_id="$(jq -r '.Account' <<< "${identity_json}")"

  local summary_json
  if ! summary_json="$(aws_call_retry "iam" iam get-account-summary)"; then
    add_warning "IAM" "aws" "Failed to get account summary"
    return 1
  fi

  local root_mfa
  root_mfa="$(jq -r '.SummaryMap.AccountMFAEnabled // 0' <<< "${summary_json}")"
  local root_keys
  root_keys="$(jq -r '.SummaryMap.AccountAccessKeysPresent // 0' \
    <<< "${summary_json}")"

  local users_json
  if ! users_json="$(aws_call_retry "iam" iam list-users)"; then
    add_warning "IAM" "aws" "Failed to list users"
    users_json='{"Users":[]}'
  fi
  local roles_json
  if ! roles_json="$(aws_call_retry "iam" iam list-roles)"; then
    add_warning "IAM" "aws" "Failed to list roles"
    roles_json='{"Roles":[]}'
  fi

  mapfile -t USER_NAMES < <(jq -r '.Users[].UserName' <<< "${users_json}")
  mapfile -t ROLE_ITEMS < <(jq -c '.Roles[]' <<< "${roles_json}")

  local console_users=0
  local console_users_no_mfa=0
  local console_users_with_mfa=0
  local users_with_keys=0
  local users_with_active_keys=0
  local active_keys=0
  local keys_old_90=0

  local -a access_key_rows=()
  local -a admin_role_rows=()
  local -a cross_role_rows=()

  local user
  for user in "${USER_NAMES[@]}"; do
    local has_console="false"
    local mfa_count="0"
    if aws_call_optional "iam" iam get-login-profile --user-name "${user}" \
      >/dev/null 2>&1; then
      has_console="true"
    fi
    if [[ "${has_console}" == "true" ]]; then
      console_users=$((console_users + 1))
      local mfa_json
      mfa_json="$(aws_call_retry "iam" iam list-mfa-devices --user-name "${user}" \
        || echo '{"MFADevices":[]}')"
      mfa_count="$(jq -r '.MFADevices|length' <<< "${mfa_json}")"
      if [[ "${mfa_count}" -gt 0 ]]; then
        console_users_with_mfa=$((console_users_with_mfa + 1))
      else
        console_users_no_mfa=$((console_users_no_mfa + 1))
      fi
    fi

    local keys_json
    local user_has_active="false"
    keys_json="$(aws_call_retry "iam" iam list-access-keys --user-name "${user}" \
      || echo '{"AccessKeyMetadata":[]}')"
    local key_count
    key_count="$(jq -r '.AccessKeyMetadata|length' <<< "${keys_json}")"
    if [[ "${key_count}" -gt 0 ]]; then
      users_with_keys=$((users_with_keys + 1))
    fi
    local key_item
    while IFS= read -r key_item; do
      local key_id status create_date age_days last_used
      key_id="$(jq -r '.AccessKeyId' <<< "${key_item}")"
      status="$(jq -r '.Status' <<< "${key_item}")"
      create_date="$(jq -r '.CreateDate' <<< "${key_item}")"
      age_days="$(days_since "${create_date}")"
      if [[ "${status}" == "Active" ]]; then
        active_keys=$((active_keys + 1))
        user_has_active="true"
      fi
      if [[ -n "${age_days}" && "${age_days}" -ge 90 ]]; then
        keys_old_90=$((keys_old_90 + 1))
      fi
      last_used="-"
      if [[ "${IAM_MODE}" == "full" ]]; then
        local last_used_json
        last_used_json="$(aws_call_retry "iam" iam get-access-key-last-used \
          --access-key-id "${key_id}" || echo '{}')"
        last_used="$(jq -r '.AccessKeyLastUsed.LastUsedDate // "-"' \
          <<< "${last_used_json}")"
      fi
      access_key_rows+=("${user}"$'\t'"$(redact_key "${key_id}")"$'\t'"${status}"$'\t'"${age_days}"$'\t'"${last_used}")
    done < <(jq -c '.AccessKeyMetadata[]' <<< "${keys_json}")
    if [[ "${user_has_active}" == "true" ]]; then
      users_with_active_keys=$((users_with_active_keys + 1))
    fi
  done

  local admin_roles=0
  local cross_roles=0

  local role_item
  for role_item in "${ROLE_ITEMS[@]}"; do
    local role_name create_date tags trust_doc
    role_name="$(jq -r '.RoleName' <<< "${role_item}")"
    create_date="$(jq -r '.CreateDate' <<< "${role_item}")"
    tags="$(jq -r '.Tags // [] | map("\(.Key)=\(.Value)") | join(",")' \
      <<< "${role_item}")"
    trust_doc="$(jq -r '.AssumeRolePolicyDocument' <<< "${role_item}")"
    local trust_type
    trust_type="$(jq -r '
      def has_service: any(.Statement[]?; .Principal.Service? != null);
      def has_aws: any(.Statement[]?; .Principal.AWS? != null);
      if has_service and has_aws then "mixed"
      elif has_service then "service"
      elif has_aws then "account"
      else "unknown" end' <<< "${trust_doc}")"

    local external_accounts
    external_accounts="$(jq -r --arg account "${account_id}" '
      def arr(x): if x == null then [] elif (x|type)=="array" then x else [x] end;
      def aws_principals:
        ([ .Statement[]? | .Principal.AWS? ] | map(arr(.)) | add) // []
        | map(tostring);
      def to_account_id:
        if . == "*" then "*"
        elif test("^[0-9]{12}$") then .
        elif test("arn:aws:iam::[0-9]{12}:") then
          (capture("arn:aws:iam::(?<id>[0-9]{12}):").id)
        else empty end;
      (aws_principals | map(to_account_id) | unique
        | map(select(. != $account)) | join(","))' <<< "${trust_doc}")"

    local conds
    conds="$(jq -r '
      [ .Statement[]? | .Condition? ]
      | map(select(. != null))
      | map(tostring)
      | unique
      | join(" | ")' <<< "${trust_doc}")"

    local is_admin="No"
    local evidence=""

    local attached_json
    attached_json="$(aws_call_retry "iam" iam list-attached-role-policies \
      --role-name "${role_name}" || echo '{"AttachedPolicies":[]}')"
    if jq -e '.AttachedPolicies[]? | select(.PolicyName=="AdministratorAccess")' \
      <<< "${attached_json}" >/dev/null 2>&1; then
      is_admin="Yes"
      evidence="managed:AdministratorAccess"
    fi

    if [[ "${IAM_MODE}" == "full" && "${is_admin}" == "No" ]]; then
      local policy_item
      while IFS= read -r policy_item; do
        local arn pol_name ver_json pol_doc
        arn="$(jq -r '.PolicyArn' <<< "${policy_item}")"
        pol_name="$(jq -r '.PolicyName' <<< "${policy_item}")"
        ver_json="$(aws_call_retry "iam" iam get-policy --policy-arn "${arn}" || echo '{}')"
        local ver_id
        ver_id="$(jq -r '.Policy.DefaultVersionId // empty' <<< "${ver_json}")"
        if [[ -n "${ver_id}" ]]; then
          pol_doc="$(aws_call_retry "iam" iam get-policy-version \
            --policy-arn "${arn}" --version-id "${ver_id}" || echo '{}')"
          if jq -e '.PolicyVersion.Document.Statement[]? | select(
            .Effect=="Allow" and ((.Action=="*") or (.Action|type=="array" and index("*")))
            and ((.Resource=="*") or (.Resource|type=="array" and index("*")))
          )' <<< "${pol_doc}" >/dev/null 2>&1; then
            is_admin="Yes"
            evidence="policy:${pol_name}"
            break
          fi
        fi
      done < <(jq -c '.AttachedPolicies[]' <<< "${attached_json}")
    fi

    if [[ "${is_admin}" == "Yes" ]]; then
      admin_roles=$((admin_roles + 1))
      admin_role_rows+=("${role_name}"$'\t'"${create_date}"$'\t'"${tags}"$'\t'"${trust_type}"$'\t'"${evidence}")
    fi

    if [[ -n "${external_accounts}" ]]; then
      cross_roles=$((cross_roles + 1))
      cross_role_rows+=("${role_name}"$'\t'"${external_accounts}"$'\t'"${conds}")
    fi
  done

  local cloudtrail_status="Unknown"
  local guardduty_status="Unknown"
  local securityhub_status="Unknown"

  local trails_json
  if ! trails_json="$(aws_call_retry "iam" cloudtrail describe-trails \
    --include-shadow-trails)"; then
    add_warning "IAM" "aws" "Failed to describe CloudTrail"
    trails_json='{"trailList":[]}'
  fi
  local trail_count
  trail_count="$(jq -r '.trailList|length' <<< "${trails_json}")"
  if [[ "${trail_count}" -gt 0 ]]; then
    cloudtrail_status="Enabled"
  else
    cloudtrail_status="Disabled"
  fi

  local guard_json
  if ! guard_json="$(aws_call_retry "iam" guardduty list-detectors)"; then
    add_warning "IAM" "aws" "Failed to list GuardDuty detectors"
    guard_json='{"DetectorIds":[]}'
  fi
  local guard_count
  guard_count="$(jq -r '.DetectorIds|length' <<< "${guard_json}")"
  if [[ "${guard_count}" -gt 0 ]]; then
    guardduty_status="Enabled"
  else
    guardduty_status="Disabled"
  fi

  local sh_json sh_status
  sh_status=""
  local sh_err_file
  sh_err_file="$(mktemp)"
  if sh_json="$("${AWS_BASE[@]}" securityhub get-enabled-standards \
    --output json 2>"${sh_err_file}")"; then
    rm -f "${sh_err_file}"
  else
    local sh_err
    sh_err="$(<"${sh_err_file}")"
    rm -f "${sh_err_file}"
    if [[ "${sh_err}" == *AccessDenied* || "${sh_err}" == *AuthFailure* || \
          "${sh_err}" == *UnrecognizedClientException* ]]; then
      log "ERROR" "iam" "AWS auth error: ${sh_err}"
      exit 2
    fi
    if [[ "${sh_err}" == *InvalidAccessException* || \
          "${sh_err}" == *"not subscribed to AWS Security Hub"* ]]; then
      sh_status="Disabled"
      sh_json='{}'
    else
      add_warning "IAM" "aws" "Failed to get Security Hub standards"
      sh_status="Unknown"
      sh_json='{}'
    fi
  fi
  if [[ -z "${sh_status}" ]]; then
    local sh_count
    sh_count="$(jq -r '.StandardsSubscriptions|length? // 0' <<< "${sh_json}")"
    if [[ "${sh_count}" -gt 0 ]]; then
      sh_status="Enabled"
    else
      sh_status="Disabled"
    fi
  fi
  securityhub_status="${sh_status}"

  local -a guardrail_rows=()
  guardrail_rows+=("CloudTrail"$'\t'"${cloudtrail_status}")
  guardrail_rows+=("GuardDuty"$'\t'"${guardduty_status}")
  guardrail_rows+=("Security Hub"$'\t'"${securityhub_status}")

  if [[ "${OUTPUT_FORMAT}" == "markdown" ]]; then
    # shellcheck disable=SC2129
    {
      echo "## IAM Report"
      echo
      echo "### Summary"
      echo
      echo "| Indicator | Value |"
      echo "| --- | --- |"
      echo "| Root MFA | $([[ "${root_mfa}" -eq 1 ]] && echo Enabled || echo Disabled) |"
      echo "| Root access keys | ${root_keys} |"
      echo "| Console users without MFA | ${console_users_no_mfa} |"
      echo "| IAM users with active access keys | ${users_with_active_keys} (keys >90 days: ${keys_old_90}) |"
      echo "| Admin-equivalent roles | ${admin_roles} |"
      echo "| Cross-account roles | ${cross_roles} |"
      echo "| CloudTrail | ${cloudtrail_status} |"
      echo "| GuardDuty | ${guardduty_status} |"
      echo "| Security Hub | ${securityhub_status} |"
      echo
      echo "### Root & Break-Glass Status"
      echo
      echo "- Root MFA enabled: $([[ "${root_mfa}" -eq 1 ]] && echo Yes || echo No)"
      echo "- Root access keys present: $([[ "${root_keys}" -gt 0 ]] && echo Yes || echo No)"
      echo
      echo "### IAM Users & Access Keys"
      echo
      echo "- Total IAM users: ${#USER_NAMES[@]}"
      echo "- Users with console access: ${console_users}"
      echo "- Console users with MFA: ${console_users_with_mfa}"
      echo "- Console users without MFA: ${console_users_no_mfa}"
      echo "- Users with access keys: ${users_with_keys}"
      echo "- Active access keys: ${active_keys}"
      echo "- Access keys older than 90 days: ${keys_old_90}"
      echo
    } >> "${out_file}"

    render_table_body $'User\tAccess Key\tStatus\tAge (days)\tLast Used' \
      "${access_key_rows[@]}" >> "${out_file}"

    render_table "IAM Roles" $'Role\tCreated\tTags\tTrust Type\tEvidence' \
      "${admin_role_rows[@]}" >> "${out_file}"

    render_table "Cross-Account Roles" $'Role\tExternal Accounts\tConditions' \
      "${cross_role_rows[@]}" >> "${out_file}"

    {
      echo "### Guardrails & Security Services"
      echo
      echo "- CloudTrail: ${cloudtrail_status}"
      echo "- GuardDuty: ${guardduty_status}"
      echo "- Security Hub: ${securityhub_status}"
      echo
      echo "### Notes & Recommended Next Steps"
      echo
    } >> "${out_file}"
  fi

  local -a recs=()
  if [[ "${root_mfa}" -eq 0 ]]; then
    recs+=("Enable root MFA.")
  fi
  if [[ "${root_keys}" -gt 0 ]]; then
    recs+=("Remove root access keys.")
  fi
  if [[ "${console_users_no_mfa}" -gt 0 ]]; then
    recs+=("Enable MFA for ${console_users_no_mfa} console users.")
  fi
  if [[ "${keys_old_90}" -gt 0 ]]; then
    recs+=("Rotate ${keys_old_90} access keys older than 90 days.")
  fi
  if [[ "${admin_roles}" -gt 0 ]]; then
    recs+=("Review ${admin_roles} admin-equivalent roles.")
  fi
  if [[ "${cross_roles}" -gt 0 ]]; then
    recs+=("Review ${cross_roles} cross-account roles.")
  fi
  if [[ "${cloudtrail_status}" == "Disabled" ]]; then
    recs+=("Enable multi-region CloudTrail with validation.")
  fi
  if [[ "${guardduty_status}" == "Disabled" ]]; then
    recs+=("Enable GuardDuty detectors.")
  fi
  if [[ "${securityhub_status}" == "Disabled" ]]; then
    recs+=("Enable Security Hub standards.")
  fi

  if [[ "${OUTPUT_FORMAT}" == "markdown" ]]; then
    if [[ "${#recs[@]}" -eq 0 ]]; then
      echo "- No recommendations." >> "${out_file}"
    else
      local rec
      for rec in "${recs[@]}"; do
        echo "- ${rec}" >> "${out_file}"
      done
    fi
    echo >> "${out_file}"
  else
    local -a table_jsons=()
    table_jsons+=("$(render_table_json "Access Keys" \
      $'User\tAccess Key\tStatus\tAge (days)\tLast Used' "${access_key_rows[@]}")")
    table_jsons+=("$(render_table_json "IAM Roles" \
      $'Role\tCreated\tTags\tTrust Type\tEvidence' "${admin_role_rows[@]}")")
    table_jsons+=("$(render_table_json "Cross-Account Roles" \
      $'Role\tExternal Accounts\tConditions' "${cross_role_rows[@]}")")
    table_jsons+=("$(render_table_json "Guardrails & Security Services" \
      $'Service\tStatus' "${guardrail_rows[@]}")")

    local tables_json="[]"
    if [[ ${#table_jsons[@]} -gt 0 ]]; then
      tables_json="$(printf '%s\n' "${table_jsons[@]}" | jq -s '.')"
    fi

    jq -n \
      --arg root_mfa "${root_mfa}" \
      --arg root_keys "${root_keys}" \
      --arg console_users_no_mfa "${console_users_no_mfa}" \
      --arg users_with_active_keys "${users_with_active_keys}" \
      --arg keys_old_90 "${keys_old_90}" \
      --arg admin_roles "${admin_roles}" \
      --arg cross_roles "${cross_roles}" \
      --arg cloudtrail_status "${cloudtrail_status}" \
      --arg guardduty_status "${guardduty_status}" \
      --arg securityhub_status "${securityhub_status}" \
      --arg total_users "${#USER_NAMES[@]}" \
      --arg console_users "${console_users}" \
      --arg console_users_with_mfa "${console_users_with_mfa}" \
      --arg users_with_keys "${users_with_keys}" \
      --arg active_keys "${active_keys}" \
      --argjson tables "${tables_json}" \
      '{
        iam: {
          summary: {
            root_mfa_enabled: ($root_mfa | tonumber == 1),
            root_access_keys_present: ($root_keys | tonumber),
            console_users_without_mfa: ($console_users_no_mfa | tonumber),
            iam_users_with_active_access_keys: ($users_with_active_keys | tonumber),
            access_keys_older_than_90_days: ($keys_old_90 | tonumber),
            admin_equivalent_roles: ($admin_roles | tonumber),
            cross_account_roles: ($cross_roles | tonumber),
            cloudtrail: $cloudtrail_status,
            guardduty: $guardduty_status,
            security_hub: $securityhub_status,
            total_iam_users: ($total_users | tonumber),
            users_with_console_access: ($console_users | tonumber),
            console_users_with_mfa: ($console_users_with_mfa | tonumber),
            users_with_access_keys: ($users_with_keys | tonumber),
            active_access_keys: ($active_keys | tonumber)
          },
          tables: $tables
        }
      }' > "${out_file}"
  fi
  return 0
}

# ------------------- TLS Section -------------------

trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "${s}"
}

# shellcheck disable=SC2329
parse_target() {
  local raw="$1"
  local line="$raw"

  if [[ "${line}" == *"://"* ]]; then
    line="${line#*://}"
  fi
  line="${line%%/*}"
  line="${line%%\?*}"
  line="${line%%\#*}"

  local host=""
  local port=""
  if [[ "${line}" == *":"* ]]; then
    host="${line%%:*}"
    port="${line##*:}"
  else
    host="${line}"
    port="443"
  fi

  if [[ -z "${port}" || ! "${port}" =~ ^[0-9]+$ ]]; then
    port="443"
  fi

  printf '%s\t%s' "${host}" "${port}"
}

# shellcheck disable=SC2329
resolve_ip() {
  local host="$1"
  local ip=""
  if has_cmd dig; then
    ip="$(dig +short A "${host}" | head -n 1)"
    [[ -z "${ip}" ]] && ip="$(dig +short AAAA "${host}" | head -n 1)"
  elif has_cmd python3; then
    ip="$(python3 - <<'PY' "${host}"
import socket
import sys
host = sys.argv[1]
try:
    infos = socket.getaddrinfo(host, None)
except Exception:
    infos = []

ipv4 = None
ipv6 = None
for family, _, _, _, sockaddr in infos:
    if family == socket.AF_INET and not ipv4:
        ipv4 = sockaddr[0]
    elif family == socket.AF_INET6 and not ipv6:
        ipv6 = sockaddr[0]

print(ipv4 or ipv6 or "")
PY
)"
  fi
  printf '%s' "${ip}"
}

# shellcheck disable=SC2329
probe_tls_one() {
  local item="$1"
  local idx="${item%%$'\t'*}"
  local raw="${item#*$'\t'}"

  if [[ -z "${idx}" || "${raw}" == "${item}" ]]; then
    return 0
  fi

  local parsed host port
  parsed="$(parse_target "${raw}")"
  host="${parsed%%$'\t'*}"
  port="${parsed##*$'\t'}"
  local host_ip
  host_ip="$(resolve_ip "${host}")"
  [[ -z "${host_ip}" ]] && host_ip="unresolved"

  local output status
  set +e
  output="$(${TLS_TIMEOUT_CMD} "${TLS_TIMEOUT}" openssl s_client \
    -connect "${host}:${port}" -servername "${host}" -brief < /dev/null 2>&1)"
  status=$?
  set -e

  local tls_version error cert_expires
  tls_version="$(printf '%s\n' "${output}" | awk -F': *' \
    '/Protocol( version)?/{print $NF; exit}' | tr -d '\r')"

  if [[ "${status}" -eq 124 || "${status}" -eq 137 ]]; then
    tls_version="unknown"
    error="timeout"
  elif [[ -n "${tls_version}" ]]; then
    error=""
  elif [[ "${status}" -ne 0 ]]; then
    tls_version="unknown"
    error="connect_failed"
  else
    tls_version="unknown"
    error="handshake_failed"
  fi

  cert_expires="unknown"
  if [[ -z "${error}" ]]; then
    local cert_output cert_status
    set +e
    cert_output="$(${TLS_TIMEOUT_CMD} "${TLS_TIMEOUT}" openssl s_client \
      -connect "${host}:${port}" -servername "${host}" -showcerts \
      < /dev/null 2>/dev/null | sed -n '/BEGIN CERTIFICATE/,/END CERTIFICATE/p' \
      | openssl x509 -noout -enddate 2>/dev/null)"
    cert_status=$?
    set -e
    if [[ "${cert_status}" -eq 0 && -n "${cert_output}" ]]; then
      cert_expires="${cert_output#notAfter=}"
      cert_expires="$(trim "${cert_expires}")"
      [[ -z "${cert_expires}" ]] && cert_expires="unknown"
    fi
  fi

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "${idx}" "${raw}" "${host_ip}" \
    "${port}" "${tls_version}" "${error}" "${cert_expires}"
}

render_tls_section() {
  local out_file="$1"
  log "INFO" "tls" "Probing TLS targets"

  TLS_TIMEOUT_CMD=""
  if has_cmd timeout; then
    TLS_TIMEOUT_CMD="timeout"
  else
    TLS_TIMEOUT_CMD="gtimeout"
  fi

  local tmp_dir
  tmp_dir="$(mktemp -d)"
  local input_list="${tmp_dir}/input.list"
  local idx=0
  while IFS= read -r line || [[ -n "${line}" ]]; do
    line="$(trim "${line}")"
    line="${line%$'\r'}"
    [[ -z "${line}" ]] && continue
    [[ "${line}" == \#* ]] && continue
    idx=$((idx + 1))
    printf '%s\t%s\0' "${idx}" "${line}" >> "${input_list}"
  done < "${TLS_INPUT}"

  local results_with_idx="${tmp_dir}/results_with_idx.tsv"
  : > "${results_with_idx}"

  if [[ "${idx}" -gt 0 ]]; then
    export TLS_TIMEOUT TLS_TIMEOUT_CMD
    export -f has_cmd trim parse_target resolve_ip probe_tls_one
    # shellcheck disable=SC2016
    xargs -0 -n1 -P "${TLS_PARALLEL}" -I {} bash -c \
      'probe_tls_one "$1"' _ {} < "${input_list}" > "${results_with_idx}"
  fi

  local results_sorted="${tmp_dir}/results_sorted.tsv"
  if [[ -s "${results_with_idx}" ]]; then
    sort -t$'\t' -k1,1n "${results_with_idx}" | cut -f2- > "${results_sorted}"
  else
    : > "${results_sorted}"
  fi

  declare -A counts=()
  local error_count=0
  local row_count=0

  while IFS= read -r line; do
    [[ -z "${line}" ]] && continue
    split_tsv_line "${line}"
    local tls_version="${SPLIT_TSV_FIELDS[3]-}"
    local error="${SPLIT_TSV_FIELDS[4]-}"
    row_count=$((row_count + 1))
    [[ -z "${tls_version}" ]] && tls_version="unknown"
    counts["${tls_version}"]=$((counts["${tls_version}"] + 1))
    [[ -n "${error}" ]] && error_count=$((error_count + 1))
  done < "${results_sorted}"

  local -a summary_keys=("TLSv1.3" "TLSv1.2" "TLSv1.1" "TLSv1" "unknown")

  if [[ "${OUTPUT_FORMAT}" == "markdown" ]]; then
    {
      echo "## TLS Report"
      echo
      echo "### Summary"
      echo
      local key
      for key in "${summary_keys[@]}"; do
        local label="${key}"
        if [[ "${key}" == "TLSv1" ]]; then
          label="TLSv1.0"
        fi
        echo "- ${label}: ${counts[${key}]:-0}"
      done
      echo "- Errors: ${error_count}"
      echo
    } >> "${out_file}"
  fi

  local -a tls_rows=()
  local -a cert_rows=()
  while IFS= read -r line; do
    [[ -z "${line}" ]] && continue
    split_tsv_line "${line}"
    local input="${SPLIT_TSV_FIELDS[0]-}"
    local host="${SPLIT_TSV_FIELDS[1]-}"
    local port="${SPLIT_TSV_FIELDS[2]-}"
    local tls_version="${SPLIT_TSV_FIELDS[3]-}"
    local error="${SPLIT_TSV_FIELDS[4]-}"
    local cert_expires="${SPLIT_TSV_FIELDS[5]-}"
    tls_rows+=("${input}"$'\t'"${host}"$'\t'"${port}"$'\t'"${tls_version}"$'\t'"${error}")
    local exp_display="${cert_expires}"
    [[ -z "${exp_display}" || "${exp_display}" == "unknown" ]] && exp_display="n/a"
    cert_rows+=("${input}"$'\t'"${exp_display}")
  done < "${results_sorted}"

  if [[ "${OUTPUT_FORMAT}" == "markdown" ]]; then
    render_table "TLS" $'Input\tHost (IP)\tPort\tTLS Version\tError' \
      "${tls_rows[@]}" >> "${out_file}"

    render_table "Certificate Expiration" $'Input\tExpires' \
      "${cert_rows[@]}" >> "${out_file}"
  else
    local tls13 tls12 tls11 tls10 tls_unknown
    tls13="${counts["TLSv1.3"]-0}"
    tls12="${counts["TLSv1.2"]-0}"
    tls11="${counts["TLSv1.1"]-0}"
    tls10="${counts["TLSv1"]-0}"
    tls_unknown="${counts["unknown"]-0}"

    local -a table_jsons=()
    table_jsons+=("$(render_table_json "TLS" \
      $'Input\tHost (IP)\tPort\tTLS Version\tError' "${tls_rows[@]}")")
    table_jsons+=("$(render_table_json "Certificate Expiration" \
      $'Input\tExpires' "${cert_rows[@]}")")

    local tables_json="[]"
    if [[ ${#table_jsons[@]} -gt 0 ]]; then
      tables_json="$(printf '%s\n' "${table_jsons[@]}" | jq -s '.')"
    fi

    jq -n \
      --argjson tls13 "${tls13}" \
      --argjson tls12 "${tls12}" \
      --argjson tls11 "${tls11}" \
      --argjson tls10 "${tls10}" \
      --argjson tls_unknown "${tls_unknown}" \
      --argjson errors "${error_count}" \
      --argjson total "${row_count}" \
      --argjson tables "${tables_json}" \
      '{
        tls: {
          summary: {
            tls_versions: {
              "TLSv1.3": $tls13,
              "TLSv1.2": $tls12,
              "TLSv1.1": $tls11,
              "TLSv1.0": $tls10,
              "unknown": $tls_unknown
            },
            errors: $errors,
            targets_total: $total
          },
          tables: $tables
        }
      }' > "${out_file}"
  fi

  rm -rf "${tmp_dir}"
  return 0
}

# ------------------- Network Section -------------------

render_network_section() {
  local out_file="$1"
  log "INFO" "network" "Collecting network inventory"

  local tag_filter="Name=tag:${TAG_KEY},Values=${TAG_VALUE}"

  local vpcs_json
  if ! vpcs_json="$(aws_call_retry "network" ec2 describe-vpcs --filters "${tag_filter}")"; then
    add_warning "Network" "aws" "Failed to describe VPCs"
    vpcs_json='{"Vpcs":[]}'
  fi
  local subnets_json
  if ! subnets_json="$(aws_call_retry "network" ec2 describe-subnets --filters "${tag_filter}")"; then
    add_warning "Network" "aws" "Failed to describe subnets"
    subnets_json='{"Subnets":[]}'
  fi
  local rtb_json
  if ! rtb_json="$(aws_call_retry "network" ec2 describe-route-tables --filters "${tag_filter}")"; then
    add_warning "Network" "aws" "Failed to describe route tables"
    rtb_json='{"RouteTables":[]}'
  fi
  local nat_json
  if ! nat_json="$(aws_call_retry "network" ec2 describe-nat-gateways \
    --filter "Name=tag:${TAG_KEY},Values=${TAG_VALUE}")"; then
    add_warning "Network" "aws" "Failed to describe NAT gateways"
    nat_json='{"NatGateways":[]}'
  fi
  local sg_json
  if ! sg_json="$(aws_call_retry "network" ec2 describe-security-groups --filters "${tag_filter}")"; then
    add_warning "Network" "aws" "Failed to describe security groups"
    sg_json='{"SecurityGroups":[]}'
  fi

  local vpc_count subnet_count rtb_count nat_count sg_count
  vpc_count="$(jq -r '.Vpcs|length' <<< "${vpcs_json}")"
  subnet_count="$(jq -r '.Subnets|length' <<< "${subnets_json}")"
  rtb_count="$(jq -r '.RouteTables|length' <<< "${rtb_json}")"
  nat_count="$(jq -r '.NatGateways|length' <<< "${nat_json}")"
  sg_count="$(jq -r '.SecurityGroups|length' <<< "${sg_json}")"

  local -a web_acl_rows=()
  local -a acl_names=()
  local -a acl_scopes=()
  local -a acl_ipset_files=()
  local -a acl_other_files=()
  declare -A ipset_file_by_arn=()
  declare -A ipset_name_by_arn=()
  local -a ipset_arns=()

  local waf_tmp_dir
  waf_tmp_dir="$(mktemp -d)"

  local tag_json
  if ! tag_json="$(aws_call_retry "network" resourcegroupstaggingapi get-resources \
    --tag-filters "Key=${TAG_KEY},Values=${TAG_VALUE}")"; then
    add_warning "Network" "aws" "Failed to query tagged resources"
    tag_json='{"ResourceTagMappingList":[]}'
  fi

  local res_arn
  while IFS= read -r res_arn; do
    local web_acl_json
    web_acl_json="$(aws_call_optional "network" wafv2 get-web-acl-for-resource \
      --resource-arn "${res_arn}" || echo '')"
    if [[ -n "${web_acl_json}" ]]; then
      local name id arn scope
      name="$(jq -r '.WebACL.Name' <<< "${web_acl_json}")"
      id="$(jq -r '.WebACL.Id' <<< "${web_acl_json}")"
      arn="$(jq -r '.WebACL.ARN' <<< "${web_acl_json}")"
      if [[ "${arn}" == *":global/"* || "${arn}" == *":global/webacl/"* ]]; then
        scope="CLOUDFRONT"
      else
        scope="REGIONAL"
      fi

      local region_args=()
      if [[ "${scope}" == "CLOUDFRONT" ]]; then
        region_args=(--region "us-east-1")
      fi

      local get_acl
      get_acl="$(aws_call_retry "network" wafv2 get-web-acl \
        "${region_args[@]}" --name "${name}" --id "${id}" --scope "${scope}" \
        || echo '{"WebACL":{}}')"
      local capacity
      capacity="$(jq -r '.WebACL.Capacity // 0' <<< "${get_acl}")"
      web_acl_rows+=("${name}"$'\t'"${id}"$'\t'"${capacity}")

      acl_names+=("${name}")
      acl_scopes+=("${scope}")
      local ipset_file="${waf_tmp_dir}/rules_ipset_${id}.tsv"
      local other_file="${waf_tmp_dir}/rules_other_${id}.tsv"
      : > "${ipset_file}"
      : > "${other_file}"
      acl_ipset_files+=("${ipset_file}")
      acl_other_files+=("${other_file}")

      local rules_json
      rules_json="$(jq -c '.WebACL.Rules[]?' <<< "${get_acl}")"
      local rule
      while IFS= read -r rule; do
        local rule_name priority
        rule_name="$(jq -r '.Name' <<< "${rule}")"
        priority="$(jq -r '.Priority' <<< "${rule}")"
        if jq -e '.Statement.IPSetReferenceStatement? // empty' \
          <<< "${rule}" >/dev/null 2>&1; then
          local ipset_arn
          ipset_arn="$(jq -r '.Statement.IPSetReferenceStatement.ARN' <<< "${rule}")"
          local ipset_id ipset_name
          ipset_id="${ipset_arn##*/}"
          local ipset_path="${ipset_arn%/*}"
          ipset_name="${ipset_path##*/}"
          printf '%s\t%s\t%s\n' "${rule_name}" "${priority}" "${ipset_name}" \
            >> "${ipset_file}"

          if [[ -z "${ipset_file_by_arn["${ipset_arn}"]+set}" ]]; then
            local ipset_scope
            if [[ "${ipset_arn}" == *":global/"* || "${ipset_arn}" == *":global/ipset/"* ]]; then
              ipset_scope="CLOUDFRONT"
            else
              ipset_scope="REGIONAL"
            fi
            local ipset_region_args=()
            if [[ "${ipset_scope}" == "CLOUDFRONT" ]]; then
              ipset_region_args=(--region "us-east-1")
            fi
            local ipset_json
            ipset_json="$(aws_call_retry "network" wafv2 get-ip-set \
              "${ipset_region_args[@]}" --name "${ipset_name}" --scope "${ipset_scope}" \
              --id "${ipset_id}" || echo '{"IPSet":{}}')"
            local ipset_file="${waf_tmp_dir}/ipset_${ipset_name}_${ipset_id}.tsv"
            : > "${ipset_file}"
            local addr
            while IFS= read -r addr; do
              printf '%s\n' "${addr}" >> "${ipset_file}"
            done < <(jq -r '.IPSet.Addresses[]?' <<< "${ipset_json}")
            ipset_file_by_arn["${ipset_arn}"]="${ipset_file}"
            ipset_name_by_arn["${ipset_arn}"]="${ipset_name}"
            ipset_arns+=("${ipset_arn}")
          fi
        else
          local rule_type
          rule_type="$(jq -r '
            if .Statement.ManagedRuleGroupStatement? then "ManagedRuleGroup"
            elif .Statement.RateBasedStatement? then "RateBased"
            elif .Statement.RuleGroupReferenceStatement? then "RuleGroup"
            elif .Statement.IPSetReferenceStatement? then "IPSet"
            else "Custom" end' <<< "${rule}")"
          printf '%s\t%s\t%s\n' "${rule_name}" "${priority}" "${rule_type}" \
            >> "${other_file}"
        fi
      done <<< "${rules_json}"
    fi
  done < <(jq -r '.ResourceTagMappingList[].ResourceARN' <<< "${tag_json}")

  local waf_web_acl_count="${#web_acl_rows[@]}"

  if [[ "${OUTPUT_FORMAT}" == "markdown" ]]; then
    {
      echo "## Network Inventory"
      echo
      echo "- VPCs: ${vpc_count}"
      echo "- Subnets: ${subnet_count}"
      echo "- Route Tables: ${rtb_count}"
      echo "- NAT Gateways: ${nat_count}"
      echo "- Security Groups: ${sg_count}"
      echo "- WAF Web ACLs: ${waf_web_acl_count}"
      echo
    } >> "${out_file}"
  fi

  local -a vpc_rows=()
  while IFS= read -r row; do
    vpc_rows+=("${row}")
  done < <(jq -r '.Vpcs[] | [
      .VpcId,
      .CidrBlock,
      (.Tags // [] | map(select(.Key=="Name") | .Value) | .[0] // "")
    ] | @tsv' <<< "${vpcs_json}" | sort -t$'\t' -k1,1)

  local -a table_jsons=()
  if [[ "${OUTPUT_FORMAT}" == "markdown" ]]; then
    render_table "Vpcs" $'VpcId\tCidrBlock\tName' "${vpc_rows[@]}" \
      >> "${out_file}"
  else
    table_jsons+=("$(render_table_json "Vpcs" \
      $'VpcId\tCidrBlock\tName' "${vpc_rows[@]}")")
  fi

  local -a subnet_rows=()
  while IFS= read -r row; do
    subnet_rows+=("${row}")
  done < <(jq -r '.Subnets[] | [
      .SubnetId,
      .VpcId,
      .AvailabilityZone,
      .CidrBlock,
      (.Tags // [] | map(select(.Key=="Name") | .Value) | .[0] // "")
    ] | @tsv' <<< "${subnets_json}" | sort -t$'\t' -k1,1)

  if [[ "${OUTPUT_FORMAT}" == "markdown" ]]; then
    render_table "Subnets" $'SubnetId\tVpcId\tAZ\tCidrBlock\tName' \
      "${subnet_rows[@]}" >> "${out_file}"
  else
    table_jsons+=("$(render_table_json "Subnets" \
      $'SubnetId\tVpcId\tAZ\tCidrBlock\tName' "${subnet_rows[@]}")")
  fi

  local -a rtb_rows=()
  while IFS= read -r row; do
    rtb_rows+=("${row}")
  done < <(jq -r '.RouteTables[] | [
      .OwnerId,
      .RouteTableId,
      .VpcId,
      (.Tags // [] | map(select(.Key=="Name") | .Value) | .[0] // "")
    ] | @tsv' <<< "${rtb_json}" | sort -t$'\t' -k2,2)

  if [[ "${OUTPUT_FORMAT}" == "markdown" ]]; then
    render_table "RouteTables" $'OwnerId\tRouteTableId\tVpcId\tName' \
      "${rtb_rows[@]}" >> "${out_file}"
  else
    table_jsons+=("$(render_table_json "RouteTables" \
      $'OwnerId\tRouteTableId\tVpcId\tName' "${rtb_rows[@]}")")
  fi

  local -a route_rows=()
  while IFS= read -r row; do
    route_rows+=("${row}")
  done < <(jq -r '.RouteTables[] | .RouteTableId as $rtb |
      .Routes[]? | [
        $rtb,
        (.DestinationCidrBlock // .DestinationIpv6CidrBlock // ""),
        (.GatewayId // .NatGatewayId // .TransitGatewayId // .VpcPeeringConnectionId
          // .NetworkInterfaceId // .InstanceId // ""),
        (.State // "")
      ] | @tsv' <<< "${rtb_json}" | sort -t$'\t' -k1,1 -k2,2)

  if [[ "${OUTPUT_FORMAT}" == "markdown" ]]; then
    render_table "Routes" $'RouteTableId\tDestination\tTarget\tState' \
      "${route_rows[@]}" >> "${out_file}"
  else
    table_jsons+=("$(render_table_json "Routes" \
      $'RouteTableId\tDestination\tTarget\tState' "${route_rows[@]}")")
  fi

  local -a nat_rows=()
  while IFS= read -r row; do
    nat_rows+=("${row}")
  done < <(jq -r '.NatGateways[] | [
      .NatGatewayId,
      .ConnectivityType,
      .VpcId,
      .SubnetId,
      (.NatGatewayAddresses[0].PublicIp // ""),
      (.NatGatewayAddresses[0].PrivateIp // ""),
      (.Tags // [] | map(select(.Key=="Name") | .Value) | .[0] // "")
    ] | @tsv' <<< "${nat_json}" | sort -t$'\t' -k1,1)

  if [[ "${OUTPUT_FORMAT}" == "markdown" ]]; then
    render_table "NAT Gateways" \
      $'NatGatewayId\tType\tVpcId\tSubnetId\tPublicIp\tPrivateIp\tName' \
      "${nat_rows[@]}" >> "${out_file}"
  else
    table_jsons+=("$(render_table_json "NAT Gateways" \
      $'NatGatewayId\tType\tVpcId\tSubnetId\tPublicIp\tPrivateIp\tName' \
      "${nat_rows[@]}")")
  fi

  local -a sg_rows=()
  while IFS= read -r row; do
    sg_rows+=("${row}")
  done < <(jq -r '.SecurityGroups[] | [
      .GroupName,
      .GroupId,
      .Description,
      .VpcId
    ] | @tsv' <<< "${sg_json}" | sort -t$'\t' -k2,2)

  if [[ "${OUTPUT_FORMAT}" == "markdown" ]]; then
    render_table "Security Groups" \
      $'GroupName\tSecurityGroupId\tDescription\tVpcId' "${sg_rows[@]}" \
      >> "${out_file}"
  else
    table_jsons+=("$(render_table_json "Security Groups" \
      $'GroupName\tSecurityGroupId\tDescription\tVpcId' "${sg_rows[@]}")")
  fi

  local -a inbound_rows=()
  local -a outbound_rows=()

  while IFS= read -r sg; do
    local sg_id
    sg_id="$(jq -r '.GroupId' <<< "${sg}")"
    local in_perm
    while IFS= read -r in_perm; do
      local protocol port desc
      protocol="$(jq -r '.IpProtocol' <<< "${in_perm}")"
      port="$(jq -r 'if .FromPort == null then "all" else (.FromPort|tostring) end' \
        <<< "${in_perm}")"
      desc="$(jq -r '.Description // ""' <<< "${in_perm}")"
      local src
      src="$(jq -r '[.IpRanges[].CidrIp? , .Ipv6Ranges[].CidrIpv6? ,
        .UserIdGroupPairs[].GroupId? , .PrefixListIds[].PrefixListId?]
        | map(select(.!=null)) | join(",")' <<< "${in_perm}")"
      inbound_rows+=("${protocol}"$'\t'"${port}"$'\t'"${src}"$'\t'"${sg_id}"$'\t'"${desc}")
    done < <(jq -c '.IpPermissions[]' <<< "${sg}")

    local out_perm
    while IFS= read -r out_perm; do
      local protocol port dest desc
      protocol="$(jq -r '.IpProtocol' <<< "${out_perm}")"
      port="$(jq -r 'if .FromPort == null then "all" else (.FromPort|tostring) end' \
        <<< "${out_perm}")"
      desc="$(jq -r '.Description // ""' <<< "${out_perm}")"
      dest="$(jq -r '[.IpRanges[].CidrIp? , .Ipv6Ranges[].CidrIpv6? ,
        .UserIdGroupPairs[].GroupId? , .PrefixListIds[].PrefixListId?]
        | map(select(.!=null)) | join(",")' <<< "${out_perm}")"
      outbound_rows+=("${protocol}"$'\t'"${port}"$'\t'"${sg_id}"$'\t'"${dest}"$'\t'"${desc}")
    done < <(jq -c '.IpPermissionsEgress[]' <<< "${sg}")
  done < <(jq -c '.SecurityGroups[]' <<< "${sg_json}")

  if [[ "${OUTPUT_FORMAT}" == "markdown" ]]; then
    # shellcheck disable=SC2129
    render_table "Inbound rules" \
      $'Protocol\tPort\tSource\tDestination\tDescription' "${inbound_rows[@]}" \
      >> "${out_file}"

    render_table "Outbound rules" \
      $'Protocol\tPort\tSource\tDestination\tDescription' "${outbound_rows[@]}" \
      >> "${out_file}"

    render_table "AWS WAFv2 Web ACLs (resources tagged ${TAG_KEY}=${TAG_VALUE})" \
      $'Name\tId\tCapacity' "${web_acl_rows[@]}" >> "${out_file}"
  else
    table_jsons+=("$(render_table_json "Inbound rules" \
      $'Protocol\tPort\tSource\tDestination\tDescription' "${inbound_rows[@]}")")
    table_jsons+=("$(render_table_json "Outbound rules" \
      $'Protocol\tPort\tSource\tDestination\tDescription' "${outbound_rows[@]}")")
    table_jsons+=("$(render_table_json \
      "AWS WAFv2 Web ACLs (resources tagged ${TAG_KEY}=${TAG_VALUE})" \
      $'Name\tId\tCapacity' "${web_acl_rows[@]}")")
  fi

  local idx
  for ((idx = 0; idx < ${#acl_names[@]}; idx++)); do
    local acl_name acl_scope ipset_file other_file
    acl_name="${acl_names[idx]}"
    acl_scope="${acl_scopes[idx]}"
    ipset_file="${acl_ipset_files[idx]}"
    other_file="${acl_other_files[idx]}"

    if [[ -s "${ipset_file}" ]]; then
      local -a ipset_rule_rows=()
      mapfile -t ipset_rule_rows < <(sort -t$'\t' -k2,2n -k1,1 "${ipset_file}")
      if [[ "${OUTPUT_FORMAT}" == "markdown" ]]; then
        render_table "Rules ${acl_name} (${acl_scope})" \
          $'Name\tPriority\tIPSetName' "${ipset_rule_rows[@]}" >> "${out_file}"
      else
        table_jsons+=("$(render_table_json "Rules ${acl_name} (${acl_scope})" \
          $'Name\tPriority\tIPSetName' "${ipset_rule_rows[@]}")")
      fi
    fi

    if [[ -s "${other_file}" ]]; then
      local -a other_rule_rows=()
      mapfile -t other_rule_rows < <(sort -t$'\t' -k2,2n -k1,1 "${other_file}")
      if [[ "${OUTPUT_FORMAT}" == "markdown" ]]; then
        render_table "Rules ${acl_name} (${acl_scope})" \
          $'Name\tPriority\tType' "${other_rule_rows[@]}" >> "${out_file}"
      else
        table_jsons+=("$(render_table_json "Rules ${acl_name} (${acl_scope})" \
          $'Name\tPriority\tType' "${other_rule_rows[@]}")")
      fi
    fi
  done

  if [[ "${#ipset_arns[@]}" -gt 0 ]]; then
    local -a ipset_entries=()
    local ipset_arn
    for ipset_arn in "${ipset_arns[@]}"; do
      ipset_entries+=("${ipset_name_by_arn["${ipset_arn}"]}"$'\t'"${ipset_arn}")
    done
    while IFS=$'\t' read -r ipset_name ipset_arn; do
      local ipset_file
      ipset_file="${ipset_file_by_arn["${ipset_arn}"]}"
      if [[ -s "${ipset_file}" ]]; then
        local -a addr_rows=()
        mapfile -t addr_rows < <(sort -u "${ipset_file}")
        if [[ "${OUTPUT_FORMAT}" == "markdown" ]]; then
          render_table "IPSet ${ipset_name}" $'Address' "${addr_rows[@]}" \
            >> "${out_file}"
        else
          table_jsons+=("$(render_table_json "IPSet ${ipset_name}" \
            $'Address' "${addr_rows[@]}")")
        fi
      fi
    done < <(printf '%s\n' "${ipset_entries[@]}" | sort -t$'\t' -k1,1 -u)
  fi

  rm -rf "${waf_tmp_dir}"

  if [[ "${OUTPUT_FORMAT}" != "markdown" ]]; then
    local tables_json="[]"
    if [[ ${#table_jsons[@]} -gt 0 ]]; then
      tables_json="$(printf '%s\n' "${table_jsons[@]}" | jq -s '.')"
    fi

    jq -n \
      --argjson vpcs "${vpc_count}" \
      --argjson subnets "${subnet_count}" \
      --argjson route_tables "${rtb_count}" \
      --argjson nat_gateways "${nat_count}" \
      --argjson security_groups "${sg_count}" \
      --argjson waf_web_acls "${waf_web_acl_count}" \
      --argjson tables "${tables_json}" \
      '{
        network: {
          summary: {
            vpcs: $vpcs,
            subnets: $subnets,
            route_tables: $route_tables,
            nat_gateways: $nat_gateways,
            security_groups: $security_groups,
            waf_web_acls: $waf_web_acls
          },
          tables: $tables
        }
      }' > "${out_file}"
  fi

  return 0
}

main() {
  parse_args "$@"
  parse_config
  apply_precedence
  apply_section_selection
  validate_inputs
  require_dependencies

  log "INFO" "core" "Using AWS profile: ${PROFILE} (region: ${AWS_REGION})"

  AWS_BASE=(aws --no-cli-pager)
  if [[ -n "${PROFILE}" ]]; then
    AWS_BASE+=(--profile "${PROFILE}")
  fi
  if [[ -n "${AWS_REGION}" && "${AWS_REGION}" != "default" ]]; then
    AWS_BASE+=(--region "${AWS_REGION}")
  fi

  if [[ "${OUTPUT_FORMAT}" == "markdown" ]]; then
    local report_tmp
    report_tmp="$(mktemp)"
    write_global_header "${report_tmp}"

    if [[ "${PARALLEL_SECTIONS}" == "true" ]]; then
      log "INFO" "core" "Running enabled sections in parallel"
      local warnings_tmp
      warnings_tmp="$(mktemp)"
      : > "${warnings_tmp}"
      WARNINGS_FILE="${warnings_tmp}"
      export WARNINGS_FILE

      local -a section_names=()
      local -a section_files=()
      local -a section_pids=()

      if [[ "${ENABLE_COST}" == "true" ]]; then
        local cost_tmp
        cost_tmp="$(mktemp)"
        section_names+=("Cost")
        section_files+=("${cost_tmp}")
        render_cost_section "${cost_tmp}" &
        section_pids+=("$!")
      fi
      if [[ "${ENABLE_IAM}" == "true" ]]; then
        local iam_tmp
        iam_tmp="$(mktemp)"
        section_names+=("IAM")
        section_files+=("${iam_tmp}")
        render_iam_section "${iam_tmp}" &
        section_pids+=("$!")
      fi
      if [[ "${ENABLE_TLS}" == "true" ]]; then
        local tls_tmp
        tls_tmp="$(mktemp)"
        section_names+=("TLS")
        section_files+=("${tls_tmp}")
        render_tls_section "${tls_tmp}" &
        section_pids+=("$!")
      fi
      if [[ "${ENABLE_NETWORK}" == "true" ]]; then
        local network_tmp
        network_tmp="$(mktemp)"
        section_names+=("Network")
        section_files+=("${network_tmp}")
        render_network_section "${network_tmp}" &
        section_pids+=("$!")
      fi

      local idx
      for idx in "${!section_pids[@]}"; do
        local status=0
        if ! wait "${section_pids[idx]}"; then
          status=$?
        fi
        if [[ ${status} -ne 0 ]]; then
          printf '%s | failed | %s section failed\n' \
            "${section_names[idx]}" "${section_names[idx]}" >> "${warnings_tmp}"
        fi
      done

      local file_idx
      for file_idx in "${!section_files[@]}"; do
        if [[ -s "${section_files[file_idx]}" ]]; then
          cat "${section_files[file_idx]}" >> "${report_tmp}"
        fi
        rm -f "${section_files[file_idx]}"
      done

      if [[ -s "${warnings_tmp}" ]]; then
        PARTIAL_FAILURE="true"
        while IFS= read -r item; do
          WARNINGS+=("${item}")
        done < "${warnings_tmp}"
      fi
      rm -f "${warnings_tmp}"
      WARNINGS_FILE=""
      unset WARNINGS_FILE
    else
      if [[ "${ENABLE_COST}" == "true" ]]; then
        if ! render_cost_section "${report_tmp}"; then
          add_warning "Cost" "failed" "Cost section failed"
        fi
      fi
      if [[ "${ENABLE_IAM}" == "true" ]]; then
        if ! render_iam_section "${report_tmp}"; then
          add_warning "IAM" "failed" "IAM section failed"
        fi
      fi
      if [[ "${ENABLE_TLS}" == "true" ]]; then
        if ! render_tls_section "${report_tmp}"; then
          add_warning "TLS" "failed" "TLS section failed"
        fi
      fi
      if [[ "${ENABLE_NETWORK}" == "true" ]]; then
        if ! render_network_section "${report_tmp}"; then
          add_warning "Network" "failed" "Network section failed"
        fi
      fi
    fi

    write_warnings "${report_tmp}"

    mv "${report_tmp}" "${OUTPUT_FILE}"
    log "INFO" "core" "Report written to ${OUTPUT_FILE}"
  else
    local -a section_names=()
    local -a section_files=()
    local -a section_pids=()

    if [[ "${PARALLEL_SECTIONS}" == "true" ]]; then
      log "INFO" "core" "Running enabled sections in parallel"
      local warnings_tmp
      warnings_tmp="$(mktemp)"
      : > "${warnings_tmp}"
      WARNINGS_FILE="${warnings_tmp}"
      export WARNINGS_FILE

      if [[ "${ENABLE_COST}" == "true" ]]; then
        local cost_tmp
        cost_tmp="$(mktemp)"
        section_names+=("Cost")
        section_files+=("${cost_tmp}")
        render_cost_section "${cost_tmp}" &
        section_pids+=("$!")
      fi
      if [[ "${ENABLE_IAM}" == "true" ]]; then
        local iam_tmp
        iam_tmp="$(mktemp)"
        section_names+=("IAM")
        section_files+=("${iam_tmp}")
        render_iam_section "${iam_tmp}" &
        section_pids+=("$!")
      fi
      if [[ "${ENABLE_TLS}" == "true" ]]; then
        local tls_tmp
        tls_tmp="$(mktemp)"
        section_names+=("TLS")
        section_files+=("${tls_tmp}")
        render_tls_section "${tls_tmp}" &
        section_pids+=("$!")
      fi
      if [[ "${ENABLE_NETWORK}" == "true" ]]; then
        local network_tmp
        network_tmp="$(mktemp)"
        section_names+=("Network")
        section_files+=("${network_tmp}")
        render_network_section "${network_tmp}" &
        section_pids+=("$!")
      fi

      local idx
      for idx in "${!section_pids[@]}"; do
        local status=0
        if ! wait "${section_pids[idx]}"; then
          status=$?
        fi
        if [[ ${status} -ne 0 ]]; then
          printf '%s | failed | %s section failed\n' \
            "${section_names[idx]}" "${section_names[idx]}" >> "${warnings_tmp}"
        fi
      done

      if [[ -s "${warnings_tmp}" ]]; then
        PARTIAL_FAILURE="true"
        while IFS= read -r item; do
          WARNINGS+=("${item}")
        done < "${warnings_tmp}"
      fi
      rm -f "${warnings_tmp}"
      WARNINGS_FILE=""
      unset WARNINGS_FILE
    else
      if [[ "${ENABLE_COST}" == "true" ]]; then
        local cost_tmp
        cost_tmp="$(mktemp)"
        if ! render_cost_section "${cost_tmp}"; then
          add_warning "Cost" "failed" "Cost section failed"
        fi
        section_files+=("${cost_tmp}")
      fi
      if [[ "${ENABLE_IAM}" == "true" ]]; then
        local iam_tmp
        iam_tmp="$(mktemp)"
        if ! render_iam_section "${iam_tmp}"; then
          add_warning "IAM" "failed" "IAM section failed"
        fi
        section_files+=("${iam_tmp}")
      fi
      if [[ "${ENABLE_TLS}" == "true" ]]; then
        local tls_tmp
        tls_tmp="$(mktemp)"
        if ! render_tls_section "${tls_tmp}"; then
          add_warning "TLS" "failed" "TLS section failed"
        fi
        section_files+=("${tls_tmp}")
      fi
      if [[ "${ENABLE_NETWORK}" == "true" ]]; then
        local network_tmp
        network_tmp="$(mktemp)"
        if ! render_network_section "${network_tmp}"; then
          add_warning "Network" "failed" "Network section failed"
        fi
        section_files+=("${network_tmp}")
      fi
    fi

    local meta_tmp warnings_tmp
    meta_tmp="$(mktemp)"
    warnings_tmp="$(mktemp)"
    write_json_metadata "${meta_tmp}"
    write_json_warnings "${warnings_tmp}"

    local -a merge_files=("${meta_tmp}" "${warnings_tmp}")
    if [[ ${#section_files[@]} -gt 0 ]]; then
      local section_file
      for section_file in "${section_files[@]}"; do
        if [[ -s "${section_file}" ]]; then
          merge_files+=("${section_file}")
        fi
      done
    fi

    jq -s 'reduce .[] as $item ({}; . * $item)' "${merge_files[@]}" \
      > "${OUTPUT_FILE}"

    rm -f "${meta_tmp}" "${warnings_tmp}"
    local file
    for file in "${section_files[@]}"; do
      rm -f "${file}"
    done

    log "INFO" "core" "Report written to ${OUTPUT_FILE}"
  fi

  if [[ "${PARTIAL_FAILURE}" == "true" ]]; then
    exit 3
  fi
  exit 0
}

main "$@"
