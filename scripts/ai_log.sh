#!/usr/bin/env bash
set -euo pipefail

# Usage: echo "details text" | scripts/ai_log.sh <category> <action> [--files <comma-separated>] [--status <ok|error>] [--meta k=v ...]

LOG_FILE=".ai/log.jsonl"
mkdir -p "$(dirname "$LOG_FILE")"

if [[ $# -lt 2 ]]; then
  echo "Usage: ai_log.sh <category> <action> [--files <comma-separated>] [--status <ok|error>] [--meta k=v ...]" >&2
  exit 1
fi

category="$1"; shift
action="$1"; shift
files="[]"
status="ok"
declare -a metas

while [[ $# -gt 0 ]]; do
  case "$1" in
    --files)
      shift
      IFS=',' read -r -a arr <<< "${1:-}"
      # Build JSON array of strings
      files="[\"$(printf '%s\",\"' "${arr[@]}")\"]"
      files="${files/",\"]/"]" # trim trailing comma
      shift
      ;;
    --status)
      shift
      status="${1:-ok}"
      shift
      ;;
    --meta)
      shift
      metas+=("${1:-}")
      shift
      ;;
    *)
      echo "Unknown arg: $1" >&2; exit 1;
      ;;
  esac
done

ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
actor="${AI_ACTOR:-codex-cli}"
session="${AI_SESSION:-}"
plan_step="${AI_PLAN_STEP:-}"

# Read details from stdin (if provided) and base64-encode to avoid JSON escaping
if [ -t 0 ]; then
  details_b64=""
else
  details_b64="$(cat | base64 | tr -d '\n')"
fi

# Build meta object
meta_json="{}"
if [[ ${#metas[@]} -gt 0 ]]; then
  meta_json="{"
  for kv in "${metas[@]}"; do
    k="${kv%%=*}"; v="${kv#*=}"
    # escape quotes in v
    v_esc="${v//\"/\\\"}"
    meta_json+="\"$k\":\"$v_esc\"," 
  done
  meta_json="${meta_json%,}""}"
fi

line="{\"ts\":\"$ts\",\"actor\":\"$actor\",\"session\":\"$session\",\"category\":\"$category\",\"action\":\"$action\",\"plan_step\":\"$plan_step\",\"details_b64\":\"$details_b64\",\"files\":$files,\"status\":\"$status\",\"meta\":$meta_json}"

printf "%s\n" "$line" >> "$LOG_FILE"
echo "Appended log entry to $LOG_FILE" >&2
