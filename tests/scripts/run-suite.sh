#!/bin/sh
set -eu

problem() {
  printf 'Problem: %s\n' "$1" >&2
  printf 'Likely cause: %s\n' "$2" >&2
  printf 'Fix: %s\n' "$3" >&2
  printf 'Docs: %s\n' "$4" >&2
}

TUS_BASE_URL=${TUS_BASE_URL:-http://tus:8080/files}
TUS_SERVER_NAME=${TUS_SERVER_NAME:-}
RESULTS_DIR=${RESULTS_DIR:-results}

case "$TUS_SERVER_NAME" in
  '')
    problem 'TUS_SERVER_NAME is empty.' 'The runner cannot create safe per-server report filenames.' 'Set TUS_SERVER_NAME to a stable server id such as tusd.' 'README.md#quick-start'
    exit 2
    ;;
  *[!A-Za-z0-9._-]*)
    problem 'TUS_SERVER_NAME contains unsafe characters.' 'Only letters, numbers, dot, underscore, and hyphen are allowed in report and skip paths.' 'Use a normalized name such as tus-node-server.' 'README.md#quick-start'
    exit 2
    ;;
esac

mkdir -p "$RESULTS_DIR"

ALL="$RESULTS_DIR/all-$TUS_SERVER_NAME.txt"
UNSUPPORTED="$RESULTS_DIR/unsupported-$TUS_SERVER_NAME.txt"
RAW_ACTIVE="$RESULTS_DIR/raw-active-$TUS_SERVER_NAME.txt"
SKIPPED="$RESULTS_DIR/skipped-$TUS_SERVER_NAME.txt"
ACTIVE="$RESULTS_DIR/active-$TUS_SERVER_NAME.txt"
STATUS="$RESULTS_DIR/status-$TUS_SERVER_NAME.txt"

: > "$ALL"
: > "$UNSUPPORTED"
: > "$RAW_ACTIVE"
: > "$SKIPPED"
: > "$ACTIVE"
: > "$STATUS"

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT INT TERM

normalize_path() {
  path=$1
  path=${path#./}
  printf '%s\n' "$path"
}

append_file_if_test() {
  path=$(normalize_path "$1")
  [ -f "$path" ] || return 0
  case "$path" in
    *.hurl|*.py) printf '%s\n' "$path" >> "$tmp_dir/all.unsorted" ;;
  esac
}

collect_from_dir() {
  dir=$(normalize_path "$1")
  [ -d "$dir" ] || return 0
  find "$dir" -type f -name '*.hurl' | sort >> "$tmp_dir/all.unsorted"
  case "$dir" in
    tests/probes|tests/probes/*)
      find "$dir" -type f -name '*.py' | sort >> "$tmp_dir/all.unsorted"
      ;;
  esac
}

: > "$tmp_dir/all.unsorted"
if [ "$#" -eq 0 ]; then
  set -- tests/core tests/extensions tests/probes
fi

for input in "$@"; do
  input=$(normalize_path "$input")
  if [ -d "$input" ]; then
    collect_from_dir "$input"
  else
    append_file_if_test "$input"
  fi
done

sort -u "$tmp_dir/all.unsorted" > "$ALL"

discover_extensions() {
  options_file="$tmp_dir/options.hurl"
  options_out="$tmp_dir/options.out"
  cat > "$options_file" <<EOF
OPTIONS {{base_url}}
EOF
  if ! hurl --very-verbose --variable "base_url=$TUS_BASE_URL" "$options_file" > "$options_out" 2>&1; then
    return 0
  fi
  awk 'BEGIN { IGNORECASE=1 }
    /^[<[:space:]]*Tus-Extension:/ {
      sub(/^[<[:space:]]*Tus-Extension:[[:space:]]*/, "")
      gsub(/\r/, "")
      print
    }' "$options_out" | tr ',' '\n' | awk '{ gsub(/^[[:space:]]+|[[:space:]]+$/, ""); if ($0 != "") print tolower($0) }'
}

discover_extensions > "$tmp_dir/extensions"

is_advertised() {
  grep -Fxq "$1" "$tmp_dir/extensions"
}

extension_for_path() {
  case "$1" in
    tests/probes/checksum_trailer.py)
      printf '%s\n' "checksum-trailer"
      ;;
    tests/probes/expiration_lifecycle.py)
      printf '%s\n' "expiration"
      ;;
    tests/probes/options_headers.py)
      printf '%s\n' "creation"
      ;;
    tests/extensions/*/*)
      rest=${1#tests/extensions/}
      printf '%s\n' "${rest%%/*}"
      ;;
  esac
}

while IFS= read -r path; do
  [ -n "$path" ] || continue
  ext=$(extension_for_path "$path" || true)
  if [ -n "$ext" ] && ! is_advertised "$ext"; then
    printf '%s\n' "$path" >> "$UNSUPPORTED"
  else
    printf '%s\n' "$path" >> "$RAW_ACTIVE"
  fi
done < "$ALL"

skip_file="tests/skips/$TUS_SERVER_NAME.txt"
skip_exact="$tmp_dir/skips"
if [ -f "$skip_file" ]; then
  awk 'NF && $1 !~ /^#/ { print $0 }' "$skip_file" | sort -u > "$skip_exact"
else
  : > "$skip_exact"
fi

while IFS= read -r path; do
  [ -n "$path" ] || continue
  if grep -Fxq "$path" "$skip_exact"; then
    printf '%s\n' "$path" >> "$SKIPPED"
  else
    printf '%s\n' "$path" >> "$ACTIVE"
  fi
done < "$RAW_ACTIVE"

if [ "${LIST_ONLY:-}" = "true" ]; then
  printf '0\n' > "$STATUS"
  exit 0
fi

failed=0

hurl_args=""
if [ "${REPORT_HTML:-}" = "true" ]; then
  mkdir -p "$RESULTS_DIR/html"
  hurl_args="$hurl_args --report-html $RESULTS_DIR/html"
fi
if [ "${REPORT_JSON:-}" = "true" ]; then
  mkdir -p "$RESULTS_DIR/json"
  hurl_args="$hurl_args --report-json $RESULTS_DIR/json"
fi
if [ "${REPORT_JUNIT:-}" = "true" ]; then
  hurl_args="$hurl_args --report-junit $RESULTS_DIR/results-junit.xml"
fi
if [ "${REPORT_TAP:-}" = "true" ]; then
  hurl_args="$hurl_args --report-tap $RESULTS_DIR/report.tap"
fi

hurl_files="$tmp_dir/hurl-files"
py_files="$tmp_dir/py-files"
grep '\.hurl$' "$ACTIVE" > "$hurl_files" || true
grep '\.py$' "$ACTIVE" > "$py_files" || true

if [ -s "$hurl_files" ]; then
  # shellcheck disable=SC2086
  hurl_status=0
  xargs hurl --variable "tus_version=1.0.0" --variable "base_url=$TUS_BASE_URL" --test $hurl_args < "$hurl_files" || hurl_status=$?
  if [ "$hurl_status" -ne 0 ]; then
    problem 'One or more Hurl compliance tests failed.' 'The server behavior did not match selected tus protocol assertions, or the server became unavailable.' 'Inspect Hurl output and the generated active/unsupported/skipped reports.' 'tests/README.md#runner-configuration'
    failed=$hurl_status
  fi
fi

while IFS= read -r probe; do
  [ -n "$probe" ] || continue
  probe_status=0
  TUS_BASE_URL="$TUS_BASE_URL" TUS_SERVER_NAME="$TUS_SERVER_NAME" RESULTS_DIR="$RESULTS_DIR" python3 "$probe" || probe_status=$?
  if [ "$probe_status" -ne 0 ]; then
    problem 'A selected Python probe failed.' 'The probe detected non-compliance or hit a runner/server error.' 'Inspect probe output and verify the server supports the feature under test.' 'docs/server-noncompliance.md'
    failed=$probe_status
  fi
done < "$py_files"

printf '%s\n' "$failed" > "$STATUS"
exit "$failed"
