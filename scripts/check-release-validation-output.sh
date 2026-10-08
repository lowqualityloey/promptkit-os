#!/usr/bin/env bash
# Evaluates output and exit status of validate-release-records scripts against the formal output contract.
# Enforces strict 5-field diagnostic parsing, path-specific grandfathering, and summary consistency.

set -u
set -o pipefail

usage() {
  echo "Usage: check-release-validation-output.sh --exit-code <code|" >&2
  exit 2
}

EXIT_CODE=""
INPUT_FILE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --exit-code)
      EXIT_CODE="$2"
      shift 2
      ;;
    --input-file)
      INPUT_FILE="$2"
      shift 2
      ;;
    *)
      usage
      ;;
  esac
done

if [ -z "$EXIT_CODE" ]; then
  echo "Error: --exit-code <code> is required." >&2
  exit 2
fi

raw_lines=()
if [ -n "$INPUT_FILE" ] && [ -f "$INPUT_FILE" ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%$'\r'}"
    raw_lines+=("$line")
  done < "$INPUT_FILE"
else
  while IFS= read -r line || [ -n "$line" ]; do
    # Strip trailing carriage return if present
    line="${line%$'\r'}"
    raw_lines+=("$line")
  done
fi

# Check if empty output
has_non_empty=0
for l in "${raw_lines[@]}"; do
  # Check if non-whitespace
  if [[ "$l" =~ [^[:space:]] ]]; then
    has_non_empty=1
    break
  fi
done

if [ $has_non_empty -eq 0 ]; then
  echo "Contract violation: Validator output was completely empty." >&2
  exit 1
fi

if [ "$EXIT_CODE" -ne 0 ] && [ "$EXIT_CODE" -ne 1 ]; then
  echo "Release record validation crashed with exit code $EXIT_CODE. Output:" >&2
  printf "  %s\n" "${raw_lines[@]}" >&2
  exit "$EXIT_CODE"
fi

summary_count=0
summary_type=""
summary_errors=0
diagnostic_count=0
invalid_lines=()
non_grandfathered=()

for line in "${raw_lines[@]}"; do
  if [ -z "$line" ]; then
    invalid_lines+=("<empty line>")
    continue
  fi

  if [[ "$line" =~ ^VALID\|RECORDS=([0-9]+)\|ROOT=(.*)$ ]]; then
    summary_count=$((summary_count + 1))
    summary_type="VALID"
    continue
  fi

  if [[ "$line" =~ ^FAILED\|ERRORS=([0-9]+)\|RECORDS=([0-9]+)$ ]]; then
    summary_count=$((summary_count + 1))
    summary_type="FAILED"
    summary_errors="${BASH_REMATCH[1]}"
    continue
  fi

  # 5 pipe-delimited fields: CATEGORY|EVAL_ID|RECORD_PATH|MESSAGE|REMEDY
  if [[ "$line" =~ ^([A-Z_]+)\|([^|]+)\|([^|]+)\|([^|]+)\|(.*)$ ]]; then
    rec_path="${BASH_REMATCH[3]}"
    remedy="${BASH_REMATCH[5]}"

    if [ -z "$remedy" ]; then
      invalid_lines+=("$line (empty remedy)")
      continue
    fi

    diagnostic_count=$((diagnostic_count + 1))
    norm_path="${rec_path//\\//}"
    if [[ "$norm_path" =~ ^(\./)?docs/releases/2026-09-08-v1\.0\.0-[^/]+\.md$ ]]; then
      :
    else
      non_grandfathered+=("$line")
    fi
    continue
  fi

  invalid_lines+=("$line")
done

if [ ${#invalid_lines[@]} -gt 0 ]; then
  echo "Contract violation: Found unrecognized or unstructured line(s):" >&2
  printf "  %s\n" "${invalid_lines[@]}" >&2
  exit 1
fi

if [ $summary_count -ne 1 ]; then
  echo "Contract violation: Expected exactly 1 summary line, found $summary_count." >&2
  exit 1
fi

if [ "$EXIT_CODE" -eq 0 ]; then
  if [ "$summary_type" != "VALID" ]; then
    echo "Contract violation: Process exited 0 but summary was $summary_type." >&2
    exit 1
  fi
  if [ $diagnostic_count -ne 0 ]; then
    echo "Contract violation: Process exited 0 with $diagnostic_count diagnostic(s)." >&2
    exit 1
  fi
  echo "All release records passed validation (clean valid)."
  exit 0
elif [ "$EXIT_CODE" -eq 1 ]; then
  if [ "$summary_type" != "FAILED" ]; then
    echo "Contract violation: Process exited 1 but summary was $summary_type." >&2
    exit 1
  fi
  if [ $diagnostic_count -eq 0 ]; then
    echo "Contract violation: Process exited 1 with FAILED summary but 0 diagnostics." >&2
    exit 1
  fi
  if [ $diagnostic_count -ne "$summary_errors" ]; then
    echo "Contract violation: FAILED summary reported $summary_errors error(s), but parsed $diagnostic_count diagnostic(s)." >&2
    exit 1
  fi
  if [ ${#non_grandfathered[@]} -gt 0 ]; then
    echo "Release record validation errors found in non-grandfathered records:" >&2
    printf "  %s\n" "${non_grandfathered[@]}" >&2
    exit 1
  fi
  echo "All non-grandfathered release records passed validation (all diagnostics grandfathered)."
  exit 0
fi
