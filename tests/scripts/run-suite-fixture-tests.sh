#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
RUNNER="$REPO_ROOT/tests/scripts/run-suite.sh"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_file_contains() {
  file=$1
  text=$2
  if ! grep -Fxq "$text" "$file"; then
    printf 'Expected %s to contain exact line: %s\n' "$file" "$text" >&2
    printf 'Actual contents:\n' >&2
    [ -f "$file" ] && sed 's/^/  /' "$file" >&2
    fail "missing expected line"
  fi
}

assert_file_not_contains() {
  file=$1
  text=$2
  if [ -f "$file" ] && grep -Fxq "$text" "$file"; then
    printf 'Expected %s not to contain exact line: %s\n' "$file" "$text" >&2
    printf 'Actual contents:\n' >&2
    sed 's/^/  /' "$file" >&2
    fail "unexpected line present"
  fi
}

assert_empty_file() {
  file=$1
  [ -f "$file" ] || fail "$file was not created"
  [ ! -s "$file" ] || fail "$file should be empty"
}

make_fixture() {
  root=$1
  mkdir -p "$root/bin" "$root/tests/core" "$root/tests/extensions/creation" \
    "$root/tests/extensions/checksum" "$root/tests/extensions/termination" \
    "$root/tests/probes" "$root/tests/skips" "$root/results"

  printf 'GET {{base_url}}\nHTTP 200\n' > "$root/tests/core/core.hurl"
  printf 'POST {{base_url}}\nHTTP 201\n' > "$root/tests/extensions/creation/create.hurl"
  printf 'PATCH {{base_url}}\nHTTP 204\n' > "$root/tests/extensions/checksum/checksum.hurl"
  printf 'DELETE {{base_url}}\nHTTP 204\n' > "$root/tests/extensions/termination/terminate.hurl"
  cat > "$root/tests/probes/probe.py" <<'PY'
from pathlib import Path
Path('results/probe-ran.txt').write_text('ran\n')
PY
  cat > "$root/tests/probes/checksum_trailer.py" <<'PY'
from pathlib import Path
Path('results/checksum-trailer-ran.txt').write_text('ran\n')
PY
  cat > "$root/tests/probes/options_headers.py" <<'PY'
from pathlib import Path
Path('results/options-headers-ran.txt').write_text('ran\n')
PY

  cat > "$root/bin/hurl" <<'SH'
#!/bin/sh
set -eu
if [ "${FAKE_HURL_OPTIONS_FAIL:-}" = "1" ]; then
  exit 7
fi
case " $* " in
  *" --test "*)
    while [ "$#" -gt 0 ]; do
      case "$1" in
        *.hurl) printf '%s\n' "$1" >> "${FAKE_HURL_RAN_FILE:-results/hurl-ran.txt}" ;;
      esac
      shift
    done
    exit 0
    ;;
  *)
    printf 'HTTP/1.1 204 No Content\n'
    if [ "${FAKE_TUS_EXTENSIONS+x}" = x ]; then
      printf 'Tus-Extension: %s\n' "$FAKE_TUS_EXTENSIONS"
    fi
    exit 0
    ;;
esac
SH
  chmod +x "$root/bin/hurl"
}

run_fixture() {
  root=$1
  shift
  (cd "$root" && PATH="$root/bin:$PATH" RESULTS_DIR=results LIST_ONLY=true TUS_SERVER_NAME=tusd sh "$RUNNER" "$@")
}

test_failed_options_marks_extensions_unsupported() {
  root=$(mktemp -d)
  make_fixture "$root"
  (cd "$root" && PATH="$root/bin:$PATH" RESULTS_DIR=results LIST_ONLY=true TUS_SERVER_NAME=tusd FAKE_HURL_OPTIONS_FAIL=1 sh "$RUNNER" tests/extensions/checksum tests/extensions/termination)
  assert_file_contains "$root/results/unsupported-tusd.txt" "tests/extensions/checksum/checksum.hurl"
  assert_file_contains "$root/results/unsupported-tusd.txt" "tests/extensions/termination/terminate.hurl"
  assert_empty_file "$root/results/active-tusd.txt"
}

test_creation_only_advertisement_filters_other_extensions() {
  root=$(mktemp -d)
  make_fixture "$root"
  (cd "$root" && PATH="$root/bin:$PATH" RESULTS_DIR=results LIST_ONLY=true TUS_SERVER_NAME=tusd FAKE_TUS_EXTENSIONS=creation sh "$RUNNER" tests/extensions/creation tests/extensions/checksum tests/extensions/termination)
  assert_file_contains "$root/results/active-tusd.txt" "tests/extensions/creation/create.hurl"
  assert_file_contains "$root/results/unsupported-tusd.txt" "tests/extensions/checksum/checksum.hurl"
  assert_file_contains "$root/results/unsupported-tusd.txt" "tests/extensions/termination/terminate.hurl"
  assert_file_contains "$root/results/status-tusd.txt" "0"
}

test_skips_apply_after_unsupported_with_exact_matching() {
  root=$(mktemp -d)
  make_fixture "$root"
  cat > "$root/tests/skips/tusd.txt" <<'EOF'
tests/extensions/creation/create.hurl
tests/extensions/creation/create.hurl.extra
tests/extensions/checksum/checksum.hurl
EOF
  (cd "$root" && PATH="$root/bin:$PATH" RESULTS_DIR=results LIST_ONLY=true TUS_SERVER_NAME=tusd FAKE_TUS_EXTENSIONS=creation sh "$RUNNER" tests/extensions/creation tests/extensions/checksum)
  assert_file_contains "$root/results/skipped-tusd.txt" "tests/extensions/creation/create.hurl"
  assert_file_not_contains "$root/results/skipped-tusd.txt" "tests/extensions/checksum/checksum.hurl"
  assert_file_contains "$root/results/unsupported-tusd.txt" "tests/extensions/checksum/checksum.hurl"
  assert_file_not_contains "$root/results/skipped-tusd.txt" "tests/extensions/creation/create.hurl.extra"
  assert_empty_file "$root/results/active-tusd.txt"
}

test_missing_skip_file_is_empty_report() {
  root=$(mktemp -d)
  make_fixture "$root"
  rm -f "$root/tests/skips/tusd.txt"
  run_fixture "$root" tests/core
  assert_empty_file "$root/results/skipped-tusd.txt"
  assert_file_contains "$root/results/active-tusd.txt" "tests/core/core.hurl"
}

test_probe_paths_are_selectable_and_skippable() {
  root=$(mktemp -d)
  make_fixture "$root"
  printf 'tests/probes/probe.py\n' > "$root/tests/skips/tusd.txt"
  run_fixture "$root" tests/probes/probe.py
  assert_file_contains "$root/results/all-tusd.txt" "tests/probes/probe.py"
  assert_file_contains "$root/results/skipped-tusd.txt" "tests/probes/probe.py"
  assert_file_contains "$root/results/status-tusd.txt" "0"
  assert_empty_file "$root/results/active-tusd.txt"
  [ ! -f "$root/results/probe-ran.txt" ] || fail "probe ran during LIST_ONLY skipped selection"
}

test_known_probe_requires_advertised_extension() {
  root=$(mktemp -d)
  make_fixture "$root"
  (cd "$root" && PATH="$root/bin:$PATH" RESULTS_DIR=results LIST_ONLY=true TUS_SERVER_NAME=tusd FAKE_TUS_EXTENSIONS=creation sh "$RUNNER" tests/probes/checksum_trailer.py)
  assert_file_contains "$root/results/all-tusd.txt" "tests/probes/checksum_trailer.py"
  assert_file_contains "$root/results/unsupported-tusd.txt" "tests/probes/checksum_trailer.py"
  assert_empty_file "$root/results/raw-active-tusd.txt"
  assert_empty_file "$root/results/active-tusd.txt"
  assert_file_contains "$root/results/status-tusd.txt" "0"
}

test_options_probe_does_not_require_creation() {
  root=$(mktemp -d)
  make_fixture "$root"
  run_fixture "$root" tests/probes/options_headers.py
  assert_file_contains "$root/results/all-tusd.txt" "tests/probes/options_headers.py"
  assert_file_contains "$root/results/active-tusd.txt" "tests/probes/options_headers.py"
  assert_file_not_contains "$root/results/unsupported-tusd.txt" "tests/probes/options_headers.py"
  assert_file_contains "$root/results/status-tusd.txt" "0"
}

test_options_probe_skips_max_size_post_without_creation() {
  python3 - "$REPO_ROOT/tests/probes/options_headers.py" <<'PY'
import os
import subprocess
import sys
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer


probe = sys.argv[1]


class Handler(BaseHTTPRequestHandler):
    saw_post = False

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Tus-Version", "1.0.0")
        self.send_header("Tus-Max-Size", "10")
        self.end_headers()

    def do_POST(self):
        Handler.saw_post = True
        self.send_response(404)
        self.end_headers()

    def log_message(self, _format, *args):
        pass


server = HTTPServer(("127.0.0.1", 0), Handler)
thread = threading.Thread(target=server.serve_forever)
thread.start()
try:
    env = os.environ.copy()
    env["TUS_BASE_URL"] = f"http://127.0.0.1:{server.server_port}/files"
    result = subprocess.run(
        [sys.executable, probe],
        env=env,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
finally:
    server.shutdown()
    thread.join()

if result.returncode != 0:
    sys.stderr.write(result.stdout)
    sys.stderr.write(result.stderr)
    raise SystemExit("options_headers.py failed without creation advertisement")
if Handler.saw_post:
    raise SystemExit("options_headers.py sent POST without creation advertisement")
PY
}

test_active_probe_runs_when_selected() {
  root=$(mktemp -d)
  make_fixture "$root"
  (cd "$root" && PATH="$root/bin:$PATH" RESULTS_DIR=results TUS_SERVER_NAME=tusd sh "$RUNNER" tests/probes)
  assert_file_contains "$root/results/active-tusd.txt" "tests/probes/probe.py"
  assert_file_contains "$root/results/status-tusd.txt" "0"
  [ -f "$root/results/probe-ran.txt" ] || fail "selected active probe did not run"
}

test_missing_explicit_probe_path_is_ignored() {
  root=$(mktemp -d)
  make_fixture "$root"
  run_fixture "$root" tests/probes/not-yet-created.py
  assert_empty_file "$root/results/all-tusd.txt"
  assert_empty_file "$root/results/active-tusd.txt"
  assert_file_contains "$root/results/status-tusd.txt" "0"
}

test_invalid_server_name_is_rejected() {
  root=$(mktemp -d)
  make_fixture "$root"
  if (cd "$root" && PATH="$root/bin:$PATH" RESULTS_DIR=results TUS_SERVER_NAME='../bad' sh "$RUNNER" tests/core >out.txt 2>err.txt); then
    fail "invalid TUS_SERVER_NAME succeeded"
  fi
  grep -q 'Problem:' "$root/err.txt" || fail "invalid server error lacks Problem section"
}

test_failed_options_marks_extensions_unsupported
test_creation_only_advertisement_filters_other_extensions
test_skips_apply_after_unsupported_with_exact_matching
test_missing_skip_file_is_empty_report
test_probe_paths_are_selectable_and_skippable
test_known_probe_requires_advertised_extension
test_options_probe_does_not_require_creation
test_options_probe_skips_max_size_post_without_creation
test_active_probe_runs_when_selected
test_missing_explicit_probe_path_is_ignored
test_invalid_server_name_is_rejected

printf 'run-suite fixture tests passed\n'
