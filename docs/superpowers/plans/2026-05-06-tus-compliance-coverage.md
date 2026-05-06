<!-- /autoplan restore point: /home/laborant/.gstack/projects/tus-compliance-tests/main-autoplan-restore-20260506-081634.md -->
# Tus Compliance Coverage Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn this repository into a spec-traceable tus 1.0.0 conformance suite: add the missing protocol coverage, verify it against the bundled Dagger server matrix, distinguish unsupported extensions from non-compliance, and record source-verified server non-compliance with server-specific skips.

**Architecture:** Keep ordinary protocol checks as focused Hurl files under the existing `tests/core` and `tests/extensions` directories. Add a thin Dagger runner layer that discovers each server's advertised `Tus-Extension` capabilities, reports unsupported extension tests separately, omits only source-verified known failures per server, and runs small probe scripts for protocol cases Hurl cannot express reliably, especially HTTP trailers and real expiration timing. Store server exceptions in `tests/skips/<server>.txt`, unsupported capability reports in `results/unsupported-<server>.txt`, active filtered test lists in `results/active-<server>.txt`, and the source evidence in `docs/server-noncompliance.md`.

**Tech Stack:** Hurl v7+, Dagger Dang, shell, Python standard library for raw HTTP probes, Dockerized tus servers from `dagger.dang`.

---

## Approach Decision

Recommended approach: add strict compliance tests plus explicit skip infrastructure.

Rejected approach: weakening strict tests to pass every bundled server by accepting broad status ranges. That would keep the Dagger matrix green but would not make the suite 100% compliant.

Rejected approach: maintaining a separate manual-only checklist for Hurl limitations. That would document gaps but would not give automated regression protection.

## File Structure

- Modify `dagger.dang`: route Dagger test execution through a script that supports server-specific skip manifests and probe execution. Before editing this file, follow `AGENTS.md`: read the Dang grammar, stdlib, and tests linked there.
- Create `tests/Dockerfile.runner`: test-runner image with Hurl and Python for `.hurl` files plus raw HTTP probes.
- Create `tests/scripts/run-suite.sh`: runs selected Hurl files, discovers advertised extensions, writes `results/all-<server>.txt`, `results/unsupported-<server>.txt`, `results/skipped-<server>.txt`, and `results/active-<server>.txt`, applies `tests/skips/<server>.txt` only after unsupported extension filtering, and runs probe scripts.
- Create `tests/skips/tusd.txt`, `tests/skips/rustus.txt`, `tests/skips/tus-node-server.txt`: exact relative paths to tests that are skipped only after source verification.
- Create `docs/server-noncompliance.md`: source-code evidence for any server-specific skipped test.
- Create `docs/protocol-coverage-audit.md` early: a spec clause to test/probe map for the 13 coverage findings, kept updated as each task lands.
- Create `tests/probes/checksum_trailer.py`: raw HTTP/1.1 chunked trailer probe.
- Create `tests/probes/expiration_lifecycle.py`: expiration lifecycle probe with a configurable wait.
- Add new Hurl files under `tests/core/cp-override`, `tests/core/cp-ver`, `tests/core/cp-patch`, `tests/core/cp-err`, `tests/extensions/creation`, `tests/extensions/creation-defer-length`, `tests/extensions/checksum`, `tests/extensions/concatenation`, and `tests/extensions/termination`.
- Modify `README.md` and `tests/README.md` in Task 1 with a minimal quickstart, result-file explanation, and troubleshooting anchors. Revisit them in Task 9 to document new strict coverage, probe tests, Dagger verification commands, final counts, and skip policy.

## Developer Experience Contract

The first useful run should be copy-pasteable from the README. Target time to hello world: under 10 minutes when Docker and Dagger are already installed, under 20 minutes from a clean machine.

Use one base URL contract everywhere:

```text
TUS_BASE_URL=http://tus:8080/files
```

`tests/scripts/run-suite.sh`, Hurl `base_url`, and every Python probe must use `TUS_BASE_URL`. Raw socket probes may parse it into host, port, and path internally, but they must not maintain a separate default.

Every runner or probe error should use this shape:

```text
Problem: <what failed>
Likely cause: <why this usually happens>
Fix: <one concrete next action>
Docs: <README or tests/README anchor>
```

## Server Non-Compliance Policy

Do not add a skip because a Dagger test fails. A skip requires all of this evidence:

- A failing Dagger run for the specific server with the new test path visible in the report.
- A source-code check of the server implementation confirming the behavior is absent or intentionally different.
- A `docs/server-noncompliance.md` entry with server, test path, observed failure, source URL or local clone path, upstream commit SHA, file/line evidence, and decision.
- A matching exact path entry in `tests/skips/<server>.txt` with a comment referencing the markdown section.

Do not add a skip for an extension a server does not advertise. Unsupported extension tests must be listed in `results/unsupported-<server>.txt`, not `tests/skips/<server>.txt`.

## Status-Code Assertion Policy

For negative tests, assert an exact status code only when tus 1.0.0 or the relevant extension explicitly requires that status. If the spec only requires rejection, assert a narrow allowed status set and add a follow-up `HEAD` or equivalent probe to prove no upload state was mutated. Every new negative test should include a short spec citation in the file comment explaining why its status assertion is exact or ranged.

Use these source clones in `/tmp/opencode` for verification:

```bash
mkdir -p /tmp/opencode/tus-source-audit
git clone --depth=1 https://github.com/tus/tusd.git /tmp/opencode/tus-source-audit/tusd
git clone --depth=1 https://github.com/s3rius/rustus.git /tmp/opencode/tus-source-audit/rustus
git clone --depth=1 https://github.com/tus/tus-node-server.git /tmp/opencode/tus-source-audit/tus-node-server
```

The markdown entry format is:

```markdown
## <server>: <short behavior name>

Test: `<relative/test/path.hurl>`
Observed: `<dagger command>` failed with `<status/header detail>` in `<results path>`.
Spec: `<one sentence and spec section>`.
Source evidence: `<repo file>:<line>` shows `<implementation behavior>`.
Source revision: `<commit SHA or immutable source URL>`.
Suggested fix: `<what the upstream server likely needs to change>`.
Docs: `<link to the relevant test or troubleshooting section>`.
Decision: skipped for `<server>` in `tests/skips/<server>.txt` until upstream behavior changes.
```

## Task 1: Add Dagger Skip And Probe Infrastructure

**Files:**
- Modify: `dagger.dang`
- Create: `tests/Dockerfile.runner`
- Create: `tests/scripts/run-suite.sh`
- Create: `tests/skips/tusd.txt`
- Create: `tests/skips/rustus.txt`
- Create: `tests/skips/tus-node-server.txt`
- Create: `docs/server-noncompliance.md`
- Modify: `docs/protocol-coverage-audit.md`
- Modify: `README.md`
- Modify: `tests/README.md`

- [x] **Step 1: Read Dang references before editing**

Run these read-only commands or equivalent fetches before changing `dagger.dang`:

```bash
curl -fsSL https://raw.githubusercontent.com/vito/dang/refs/heads/main/pkg/dang/dang.peg -o /tmp/opencode/dang.peg
curl -fsSL https://raw.githubusercontent.com/vito/dang/main/pkg/dang/stdlib.go -o /tmp/opencode/dang-stdlib.go
```

Expected: both files exist in `/tmp/opencode` and can be consulted while editing.

- [x] **Step 2: Create the Python-capable test runner image**

Create `tests/Dockerfile.runner`:

```dockerfile
FROM python:3.13-slim

ARG HURL_VERSION=7.1.0
ARG HURL_SHA256=<fill from the official release artifact before commit>

RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates curl \
  && curl -fsSL "https://github.com/Orange-OpenSource/hurl/releases/download/${HURL_VERSION}/hurl_${HURL_VERSION}_amd64.deb" -o /tmp/hurl.deb \
  && echo "${HURL_SHA256}  /tmp/hurl.deb" | sha256sum -c - \
  && apt-get install -y /tmp/hurl.deb \
  && rm -rf /var/lib/apt/lists/* /tmp/hurl.deb
```

Before committing, replace `<fill from the official release artifact before commit>` with the release checksum from the Hurl release page. Do not leave the placeholder in the committed Dockerfile.

- [x] **Step 3: Create empty skip manifests**

Create these files with comment-only contents:

```text
# Exact relative .hurl or probe paths skipped for this server after source verification.
# Each skip must have a matching entry in docs/server-noncompliance.md.
```

Files:

```text
tests/skips/tusd.txt
tests/skips/rustus.txt
tests/skips/tus-node-server.txt
```

- [x] **Step 4: Create the non-compliance log**

Create `docs/server-noncompliance.md`:

```markdown
# Server Non-Compliance Notes

This file records source-verified deviations found while running the tus compliance suite against bundled server implementations. Do not add entries for unsupported extensions that a server does not advertise.

## Verification Rules

- A failing test alone is not enough for a skip.
- Verify behavior in the server source code before adding a skip.
- Record the upstream commit SHA or immutable source URL used for the evidence.
- Link every skip in `tests/skips/<server>.txt` to an entry in this file.
```

- [x] **Step 4.5: Create the initial coverage audit**

Create `docs/protocol-coverage-audit.md` before adding new tests:

```markdown
# tus Protocol Coverage Audit

This file maps each reviewed tus 1.0.0 coverage gap to spec evidence and concrete test or probe paths. Keep it updated as each implementation task lands.

| Finding | Spec Clause | Current Gap | Coverage Added | Verification |
|---|---|---|---|---|
| X-HTTP-Method-Override | Requests MAY use `X-HTTP-Method-Override` to override POST. | No method override coverage. | Planned: `tests/core/cp-override/cp-override-001-post-overrides-patch.hurl`, `tests/extensions/termination/ext-term-006-post-overrides-delete.hurl` | Dagger matrix |
```

Add one row for each of the 13 findings before implementing the corresponding task. Update `Coverage Added` from `Planned:` to concrete paths when files are created.

- [x] **Step 4.75: Add minimal quickstart and troubleshooting docs**

Update `README.md` before the runner lands with:

- Prerequisites: Dagger, Docker, and where Hurl/Python are provided by the runner image.
- Hello world command: `dagger call run --server=TUSD --report=JUNIT export --path results/tusd-hello`.
- Expected duration and expected result files: `all-tusd.txt`, `unsupported-tusd.txt`, `skipped-tusd.txt`, `active-tusd.txt`, `status-tusd.txt`.
- A short explanation of raw vs unsupported vs skipped vs active results.
- Troubleshooting anchors for capability discovery failure, server startup failure, probe failure, and source-verified skip policy.

Update `tests/README.md` with a configuration table covering `TUS_BASE_URL`, `TUS_SERVER_NAME`, `RESULTS_DIR`, report env vars, `TUS_EXPIRATION_WAIT_SECONDS`, `TUS_EXPIRATION_GRACE_SECONDS`, and `LIST_ONLY`.

- [x] **Step 5: Create `tests/scripts/run-suite.sh`**

Use this script content:

```sh
#!/bin/sh
set -eu

server_name="${TUS_SERVER_NAME:-custom}"
case "$server_name" in
  *[!A-Za-z0-9._-]*|"")
    printf 'invalid TUS_SERVER_NAME: %s\n' "$server_name" >&2
    exit 2
    ;;
esac
results_dir="${RESULTS_DIR:-results}"
mkdir -p "$results_dir"

all_files="$(mktemp)"
raw_active_files="$(mktemp)"
active_files="$(mktemp)"
unsupported_files="$(mktemp)"
skip_patterns="$(mktemp)"
advertised_extensions="$(mktemp)"
probe_files="$(mktemp)"
failed=0

for path in "$@"; do
  if [ -d "$path" ]; then
    find "$path" -name '*.hurl' -type f
  elif [ -f "$path" ]; then
    printf '%s\n' "$path"
  fi
done | sort > "$all_files"

cp "$all_files" "$results_dir/all-${server_name}.txt"

if ! curl -fsS -X OPTIONS "${TUS_BASE_URL:-http://tus:8080/files}" -o /dev/null -D "$results_dir/options-${server_name}.headers" 2>"$results_dir/options-${server_name}.error"; then
  : > "$advertised_extensions"
  printf 'OPTIONS discovery failed; treating server as advertising no extensions. See options-%s.error.\n' "$server_name" > "$results_dir/capability-${server_name}.txt"
else
  tr -d '\r' < "$results_dir/options-${server_name}.headers" \
    | awk 'BEGIN { IGNORECASE=1 } /^Tus-Extension:/ { sub(/^[^:]*:[[:space:]]*/, ""); gsub(/,/, "\n"); print }' \
    | awk '{ gsub(/^[[:space:]]+|[[:space:]]+$/, ""); if (NF) print $1 }' \
    | sort -u > "$advertised_extensions"
fi

while IFS= read -r file; do
  case "$file" in
    tests/extensions/*/*.hurl)
      ext="${file#tests/extensions/}"
      ext="${ext%%/*}"
      if ! grep -F -x "$ext" "$advertised_extensions" >/dev/null 2>&1; then
        printf '%s\n' "$file" >> "$unsupported_files"
      else
        printf '%s\n' "$file" >> "$raw_active_files"
      fi
      ;;
    *)
      printf '%s\n' "$file" >> "$raw_active_files"
      ;;
  esac
done < "$all_files"

cp "$unsupported_files" "$results_dir/unsupported-${server_name}.txt"

skip_file="tests/skips/${server_name}.txt"
if [ -f "$skip_file" ]; then
  awk 'NF && $1 !~ /^#/ {print $1}' "$skip_file" > "$skip_patterns"
else
  : > "$skip_patterns"
fi

if [ -s "$skip_patterns" ]; then
  grep -F -x -f "$skip_patterns" "$raw_active_files" > "$results_dir/skipped-${server_name}.txt" || true
  grep -F -x -v -f "$skip_patterns" "$raw_active_files" > "$active_files" || true
else
  : > "$results_dir/skipped-${server_name}.txt"
  cp "$raw_active_files" "$active_files"
fi

cp "$raw_active_files" "$results_dir/raw-active-${server_name}.txt"
cp "$active_files" "$results_dir/active-${server_name}.txt"

if [ "${LIST_ONLY:-false}" = "true" ]; then
  printf '%s\n' "0" > "$results_dir/status-${server_name}.txt"
  exit 0
fi

if [ -s "$active_files" ]; then
  hurl_args="--verbose --variable tus_version=1.0.0 --variable base_url=${TUS_BASE_URL:-http://tus:8080/files} --test"
  if [ "${REPORT_HTML:-false}" = "true" ]; then
    hurl_args="$hurl_args --report-html $results_dir/html/"
  fi
  if [ "${REPORT_JSON:-false}" = "true" ]; then
    hurl_args="$hurl_args --report-json $results_dir/json/"
  fi
  if [ "${REPORT_JUNIT:-false}" = "true" ]; then
    hurl_args="$hurl_args --report-junit $results_dir/results-junit.xml"
  fi
  if [ "${REPORT_TAP:-false}" = "true" ]; then
    hurl_args="$hurl_args --report-tap $results_dir/report.tap"
  fi
  # File paths are generated by find from repository paths and do not contain spaces.
  # shellcheck disable=SC2046,SC2086
  hurl $hurl_args $(cat "$active_files") || failed=$?
fi

for path in "$@"; do
  if [ -d "$path" ] && [ "$path" = "tests/probes" ]; then
    find "$path" -name '*.py' -type f
  elif [ -f "$path" ] && [ "${path%.py}" != "$path" ]; then
    printf '%s\n' "$path"
  fi
done | sort > "$probe_files"

if [ -s "$probe_files" ]; then
  while IFS= read -r probe; do
    if grep -F -x "$probe" "$skip_patterns" >/dev/null 2>&1; then
      printf '%s\n' "$probe" >> "$results_dir/skipped-${server_name}.txt"
      continue
    fi
    python3 "$probe" || failed=$?
  done < "$probe_files"
fi

printf '%s\n' "$failed" > "$results_dir/status-${server_name}.txt"
exit "$failed"
```

Runner requirements that must hold even if the exact script changes during implementation:

- Treat failed OPTIONS discovery or a missing `Tus-Extension` header as “no extensions advertised,” not “run every extension.”
- Validate `TUS_SERVER_NAME` before using it in result filenames or skip paths.
- Keep probes first-class: only run probes passed through `paths`, include probe paths in `all-*`, `unsupported-*`, `skipped-*`, `raw-active-*`, and `active-*` handling, and write explicit status via `results/status-<server>.txt`.
- Add shell-level fixture tests for unsupported filtering, skip ordering, missing skip files, failed OPTIONS discovery, exact path matching, and probe path selection before relying on full Dagger server behavior.

- [x] **Step 6: Update `dagger.dang` to pass server identity and paths**

Replace the current Hurl image with the runner image:

```dang
let ctr = tests.dockerBuild(dockerfile: "Dockerfile.runner")
  .withWorkdir("/workspace")
  .withDirectory("/workspace/results", directory)
  .withMountedDirectory("/workspace/tests", tests)
```

Modify `run` so each server call passes a normalized server name:

```dang
test(mapService(s), serverName: toString(s).trim("\"").toLower().replace("_", "-"), report: report)
```

Modify `test` to accept `serverName: String! = "custom"`, build a `paths` array instead of a direct Hurl `--glob` argument list, and execute:

```dang
ctr
  .withServiceBinding("tus", service)
  .withEnvVariable("TUS_SERVER_NAME", serverName)
  .withEnvVariable("RESULTS_DIR", "results")
  .withEnvVariable("REPORT_HTML", report.contains(ReportFormat.HTML).toString())
  .withEnvVariable("REPORT_JSON", report.contains(ReportFormat.JSON).toString())
  .withEnvVariable("REPORT_JUNIT", report.contains(ReportFormat.JUNIT).toString())
  .withEnvVariable("REPORT_TAP", report.contains(ReportFormat.TAP).toString())
  .withExec(["sh", "tests/scripts/run-suite.sh"] + paths + probePaths, redirectStderr: "results/stderr.log")
  .directory("results")
```

Do not keep `expect: ReturnType.ANY` unless the Dang implementation also reads `results/status-<server>.txt` and fails explicitly when the status is nonzero. Exporting results must not be confused with a passing suite.

Build `paths` as:

```dang
let paths = []
if (!disableCore) {
  paths += ["tests/core"]
}
extension.each { ext =>
  let extName = toString(ext).trim("\"").toLower().replace("_", "-")
  paths += ["tests/extensions/" + extName]
}
```

Include `tests/probes` only when running the full suite or when the selected extension has registered probes. A core-only run must not execute checksum or expiration probes.

Build `probePaths` explicitly. At minimum, include `tests/probes` for the default full-suite run. If implementing per-extension probe registration, map `CHECKSUM` to `tests/probes/checksum_trailer.py`, `EXPIRATION` to `tests/probes/expiration_lifecycle.py`, and `CREATION` to `tests/probes/options_headers.py`.

- [x] **Step 6.5: Add runner fixture tests**

Create shell-level fixture tests for `tests/scripts/run-suite.sh` before relying on Dagger server behavior. These tests may use temporary directories under `/tmp/opencode` and fake OPTIONS header files or a tiny local HTTP server. Cover:

- Failed OPTIONS discovery treats all extension tests as unsupported instead of active.
- A server advertising only `creation` marks `checksum`, `termination`, and other extension files unsupported.
- `tests/skips/<server>.txt` applies only after unsupported filtering and matches exact paths.
- Missing skip files produce an empty skipped report, not a failure.
- Probe paths run only when selected and are included in skipped/status handling.
- Invalid `TUS_SERVER_NAME` is rejected.

If `report.contains(...)` is not valid Dang after checking the stdlib, replace it with an explicit `report.each` loop that sets booleans before `withEnvVariable`.

- [ ] **Step 7: Verify runner still runs the existing suite**

Run:

```bash
dagger call run --server=TUSD --report=JUNIT export --path results/tusd-baseline
```

Expected: Dagger completes and writes `results/tusd-baseline/all-tusd.txt`, `results/tusd-baseline/unsupported-tusd.txt`, `results/tusd-baseline/skipped-tusd.txt`, and `results/tusd-baseline/active-tusd.txt`. Existing server failures are acceptable at this step only if they also occur before adding the new tests.

Attempted: `dagger call run --server=TUSD --report=JUNIT export --path results/tusd-infra-verify-2`. The runner no longer fails on missing planned probe paths; execution reached the existing suite and reported 87/98 active files passing. Export still exits nonzero because current TUSD compliance failures are not skipped yet and `dagger.dang` intentionally does not hide failures with `ReturnType.ANY`.

- [x] **Step 8: Commit infrastructure**

```bash
git add dagger.dang tests/Dockerfile.runner tests/scripts/run-suite.sh tests/skips docs/server-noncompliance.md docs/protocol-coverage-audit.md
git commit -m "test: add server-specific compliance skip infrastructure"
```

## Task 2: Add Core Method Override And Version Mutation Tests

**Files:**
- Create: `tests/core/cp-override/cp-override-001-post-overrides-patch.hurl`
- Create: `tests/extensions/termination/ext-term-006-post-overrides-delete.hurl`
- Create: `tests/core/cp-opt/cp-opt-006-ignore-tus-resumable.hurl`
- Create: `tests/core/cp-ver/cp-ver-004-unsupported-post-no-location.hurl`
- Create: `tests/core/cp-ver/cp-ver-005-unsupported-patch-no-mutation.hurl`

- [x] **Step 1: Add POST override for PATCH**

Create `tests/core/cp-override/cp-override-001-post-overrides-patch.hurl`:

````hurl
# CP-OVERRIDE-001: X-HTTP-Method-Override PATCH
# Server MUST interpret X-HTTP-Method-Override as the effective method.

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 6

HTTP 201

[Captures]
upload_url: header "Location"

POST {{upload_url}}
Tus-Resumable: {{tus_version}}
X-HTTP-Method-Override: PATCH
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
12345
```

HTTP 204

[Asserts]
header "Upload-Offset" == "6"
````

- [x] **Step 2: Add POST override for DELETE**

Create `tests/extensions/termination/ext-term-006-post-overrides-delete.hurl`:

```hurl
# EXT-TERM-006: X-HTTP-Method-Override DELETE
# Termination implementations MUST honor method override for DELETE.

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

POST {{upload_url}}
Tus-Resumable: {{tus_version}}
X-HTTP-Method-Override: DELETE

HTTP 204

HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP *
[Asserts]
status toString matches /^(404|410)$/
```

- [x] **Step 3: Add OPTIONS ignore invalid Tus-Resumable**

Create `tests/core/cp-opt/cp-opt-006-ignore-tus-resumable.hurl`:

```hurl
# CP-OPT-006: OPTIONS ignores Tus-Resumable when present
# Server MUST ignore Tus-Resumable on OPTIONS, even if the value is unsupported.

OPTIONS {{base_url}}
Tus-Resumable: 99.99.99

HTTP *
[Asserts]
status toString matches /^(200|204)$/
header "Tus-Version" exists
```

- [x] **Step 4: Add unsupported POST no-location test**

Create `tests/core/cp-ver/cp-ver-004-unsupported-post-no-location.hurl`:

```hurl
# CP-VER-004: Unsupported Tus-Resumable on POST is not processed

POST {{base_url}}
Tus-Resumable: 99.99.99
Upload-Length: 100

HTTP 412
[Asserts]
header "Tus-Version" exists
header "Location" notExists
```

- [x] **Step 5: Add unsupported PATCH no-mutation test**

Create `tests/core/cp-ver/cp-ver-005-unsupported-patch-no-mutation.hurl`:

````hurl
# CP-VER-005: Unsupported Tus-Resumable on PATCH does not mutate upload

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 12

HTTP 201
[Captures]
upload_url: header "Location"

PATCH {{upload_url}}
Tus-Resumable: 99.99.99
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
Hello, tus!
```

HTTP 412
[Asserts]
header "Tus-Version" exists

HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP *
[Asserts]
status toString matches /^(200|204)$/
header "Upload-Offset" == "0"
````

- [x] **Step 6: Run core verification**

Run:

```bash
dagger call run --server=TUSD --report=JUNIT export --path results/tusd-core-method-version
```

Expected: new core tests pass or failing server behavior is source-verified and recorded before adding a skip.

- [x] **Step 7: Commit core method and version tests**

```bash
git add tests/core/cp-override tests/core/cp-opt/cp-opt-006-ignore-tus-resumable.hurl tests/core/cp-ver/cp-ver-004-unsupported-post-no-location.hurl tests/core/cp-ver/cp-ver-005-unsupported-patch-no-mutation.hurl tests/extensions/termination/ext-term-006-post-overrides-delete.hurl docs/server-noncompliance.md tests/skips
git commit -m "test: cover tus method override and version mutation rules"
```

## Task 3: Add Header Grammar And Tus-Resumable Response Tests

**Files:**
- Create: `tests/core/cp-patch/cp-patch-011-upload-offset-negative.hurl`
- Create: `tests/core/cp-patch/cp-patch-012-upload-offset-non-integer.hurl`
- Create: `tests/core/cp-err/cp-err-003-upload-length-non-integer.hurl`
- Create: `tests/extensions/creation/ext-create-011-returns-tus-resumable.hurl`
- Create: `tests/extensions/termination/ext-term-007-returns-tus-resumable.hurl`
- Create: `tests/extensions/checksum/ext-csum-009-error-returns-tus-resumable.hurl`

- [x] **Step 1: Add negative Upload-Offset grammar tests**

Create `cp-patch-011-upload-offset-negative.hurl` with `Upload-Offset: -1` and expect `HTTP 400`.

Create `cp-patch-012-upload-offset-non-integer.hurl` with `Upload-Offset: abc` and expect `HTTP 400`.

Both files should create a fresh upload first, send a bad `PATCH`, then `HEAD` and assert `Upload-Offset == "0"`.

- [x] **Step 2: Add non-integer Upload-Length test**

Create `tests/core/cp-err/cp-err-003-upload-length-non-integer.hurl`:

```hurl
# CP-ERR-003: Upload-Length must be a non-negative integer

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: abc

HTTP 400
```

- [x] **Step 3: Add POST Tus-Resumable response test**

Create `tests/extensions/creation/ext-create-011-returns-tus-resumable.hurl`:

```hurl
# EXT-CREATE-011: Successful POST returns Tus-Resumable

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201
[Asserts]
header "Tus-Resumable" == "{{tus_version}}"
```

- [x] **Step 4: Add DELETE Tus-Resumable response test**

Create `tests/extensions/termination/ext-term-007-returns-tus-resumable.hurl` with a normal create/delete flow and assert `header "Tus-Resumable" == "{{tus_version}}"` on the `204` delete response.

- [x] **Step 5: Add checksum error Tus-Resumable response test**

Create `tests/extensions/checksum/ext-csum-009-error-returns-tus-resumable.hurl` with a checksum mismatch and assert `HTTP 460` plus `header "Tus-Resumable" == "{{tus_version}}"`.

- [x] **Step 6: Run Dagger verification**

Run:

```bash
dagger call run --server=TUSD --report=JUNIT export --path results/tusd-header-grammar
dagger call run --server=RUSTUS --report=JUNIT export --path results/rustus-header-grammar
dagger call run --server=TUS_NODE_SERVER --report=JUNIT export --path results/tus-node-header-grammar
```

Expected: every failure is either a real test bug fixed in this task or a source-verified server non-compliance recorded and skipped.

- [x] **Step 7: Commit header tests**

```bash
git add tests/core/cp-patch/cp-patch-011-upload-offset-negative.hurl tests/core/cp-patch/cp-patch-012-upload-offset-non-integer.hurl tests/core/cp-err/cp-err-003-upload-length-non-integer.hurl tests/extensions/creation/ext-create-011-returns-tus-resumable.hurl tests/extensions/termination/ext-term-007-returns-tus-resumable.hurl tests/extensions/checksum/ext-csum-009-error-returns-tus-resumable.hurl docs/server-noncompliance.md tests/skips
git commit -m "test: cover tus header grammar and response version headers"
```

## Task 4: Add Creation, Defer-Length, Max-Size, And Metadata Coverage

**Files:**
- Create: `tests/extensions/creation/ext-create-012-requires-length-or-defer.hurl`
- Create: `tests/extensions/creation-defer-length/ext-defer-006-invalid-value-zero.hurl`
- Create: `tests/extensions/creation-defer-length/ext-defer-007-invalid-value-token.hurl`
- Create: `tests/extensions/creation/ext-create-013-metadata-exact-head.hurl`
- Create: `tests/extensions/creation/ext-create-014-metadata-empty-key-rejected.hurl`
- Create: `tests/extensions/creation/ext-create-015-metadata-comma-key-rejected.hurl`
- Create: `tests/probes/options_headers.py`

- [x] **Step 1: Add missing length/defer creation test**

Create `ext-create-012-requires-length-or-defer.hurl`:

```hurl
# EXT-CREATE-012: Creation requires Upload-Length or Upload-Defer-Length

POST {{base_url}}
Tus-Resumable: {{tus_version}}

HTTP 400
```

- [x] **Step 2: Add invalid defer value tests**

Create `ext-defer-006-invalid-value-zero.hurl` with `Upload-Defer-Length: 0` and `HTTP 400`.

Create `ext-defer-007-invalid-value-token.hurl` with `Upload-Defer-Length: true` and `HTTP 400`.

- [x] **Step 3: Add exact metadata echo test**

Create `ext-create-013-metadata-exact-head.hurl` with `Upload-Metadata: filename dGVzdC50eHQ=,filetype dGV4dC9wbGFpbg==` and assert on `HEAD`:

```hurl
header "Upload-Metadata" == "filename dGVzdC50eHQ=,filetype dGV4dC9wbGFpbg=="
```

- [x] **Step 4: Add invalid metadata key tests**

Create `ext-create-014-metadata-empty-key-rejected.hurl` with `Upload-Metadata:  dGVzdA==` and expect `HTTP 400`.

Create `ext-create-015-metadata-comma-key-rejected.hurl` with `Upload-Metadata: bad,key dGVzdA==` and expect `HTTP 400`.

- [x] **Step 5: Add optional OPTIONS header probe**

Create `tests/probes/options_headers.py` to request `OPTIONS ${TUS_BASE_URL:-http://tus:8080/files}`, then validate only headers that are present:

```python
import http.client
import os
import re
from urllib.parse import urlparse

BASE_URL = os.environ.get("TUS_BASE_URL", "http://tus:8080/files")
parsed = urlparse(BASE_URL)
host = parsed.hostname or "tus"
port = parsed.port or (443 if parsed.scheme == "https" else 80)
path = parsed.path or "/files"

conn = http.client.HTTPConnection(host, port, timeout=10)
conn.request("OPTIONS", path)
res = conn.getresponse()
headers = {k.lower(): v for k, v in res.getheaders()}
body = res.read()

if res.status not in (200, 204):
    raise SystemExit(f"OPTIONS returned {res.status}: {body!r}")
if "tus-version" not in headers:
    raise SystemExit("OPTIONS missing Tus-Version")
if "tus-max-size" in headers and not re.fullmatch(r"[0-9]+", headers["tus-max-size"]):
    raise SystemExit(f"Invalid Tus-Max-Size: {headers['tus-max-size']!r}")
if "tus-extension" in headers:
    token = r"[A-Za-z0-9-]+"
    extensions = {part.strip() for part in headers["tus-extension"].split(",")}
    if "" in extensions or any(not re.fullmatch(token, ext) for ext in extensions):
        raise SystemExit(f"Invalid Tus-Extension format: {headers['tus-extension']!r}")
    if "creation-with-upload" in extensions and "creation" not in extensions:
        raise SystemExit("creation-with-upload advertised without creation")
```

- [x] **Step 6: Tighten max-size enforcement if advertised**

Extend `tests/probes/options_headers.py` to validate `Tus-Max-Size` whenever present, and create an upload with `Upload-Length: Tus-Max-Size + 1` to assert `413` when `creation` is advertised. Leave `tests/extensions/creation/ext-create-007-exceeds-max-size.hurl` as the broad smoke test unless the probe reveals a test-runner bug.

- [x] **Step 7: Run Dagger verification**

```bash
dagger call run --server=TUSD --report=JUNIT export --path results/tusd-creation-strict
dagger call run --server=RUSTUS --report=JUNIT export --path results/rustus-creation-strict
dagger call run --server=TUS_NODE_SERVER --report=JUNIT export --path results/tus-node-creation-strict
```

- [x] **Step 8: Commit creation coverage**

```bash
git add tests/extensions/creation tests/extensions/creation-defer-length tests/probes/options_headers.py docs/server-noncompliance.md tests/skips
git commit -m "test: cover creation header validation and metadata rules"
```

## Task 5: Add Checksum And Checksum-Trailer Coverage

**Files:**
- Create: `tests/extensions/checksum/ext-csum-010-malformed-missing-space.hurl`
- Create: `tests/extensions/checksum/ext-csum-011-malformed-base64.hurl`
- Create: `tests/extensions/checksum/ext-csum-012-unknown-algorithm-no-offset-update.hurl`
- Create: `tests/probes/checksum_trailer.py`

- [x] **Step 1: Add malformed checksum format tests**

Create `ext-csum-010-malformed-missing-space.hurl` with `Upload-Checksum: sha1E7X121m3do5RTtnrOi5XTG9Uq0A=` and expect `HTTP 400`.

Create `ext-csum-011-malformed-base64.hurl` with `Upload-Checksum: sha1 not_base64!!!` and expect `HTTP 400`.

- [x] **Step 2: Add unsupported algorithm no-offset test**

Create `ext-csum-012-unknown-algorithm-no-offset-update.hurl` by copying the flow from `ext-csum-006-unknown-algorithm.hurl`, then add a `HEAD` request and assert `Upload-Offset == "0"`.

- [x] **Step 3: Add raw checksum trailer probe**

Create `tests/probes/checksum_trailer.py` with raw socket logic:

```python
import base64
import hashlib
import http.client
import os
import socket
from urllib.parse import urlparse

BASE_URL = os.environ.get("TUS_BASE_URL", "http://tus:8080/files")
parsed = urlparse(BASE_URL)
HOST = parsed.hostname or "tus"
PORT = parsed.port or (443 if parsed.scheme == "https" else 80)
BASE = parsed.path or "/files"
BODY = b"Hello, tus!\n"

def options_extensions():
    conn = http.client.HTTPConnection(HOST, PORT, timeout=10)
    conn.request("OPTIONS", BASE)
    res = conn.getresponse()
    headers = {k.lower(): v for k, v in res.getheaders()}
    res.read()
    return set(headers.get("tus-extension", "").split(",")) if headers.get("tus-extension") else set()

def create_upload():
    conn = http.client.HTTPConnection(HOST, PORT, timeout=10)
    conn.request("POST", BASE, headers={"Tus-Resumable": "1.0.0", "Upload-Length": str(len(BODY))})
    res = conn.getresponse()
    location = res.getheader("Location")
    res.read()
    if res.status != 201 or not location:
        raise SystemExit(f"create failed: {res.status} location={location!r}")
    return location if location.startswith("/") else "/" + location.split("/", 3)[3]

def raw_patch_with_trailer(path, checksum):
    request = (
        f"PATCH {path} HTTP/1.1\r\n"
        f"Host: {HOST}:{PORT}\r\n"
        "Tus-Resumable: 1.0.0\r\n"
        "Upload-Offset: 0\r\n"
        "Content-Type: application/offset+octet-stream\r\n"
        "Transfer-Encoding: chunked\r\n"
        "Trailer: Upload-Checksum\r\n"
        "\r\n"
    ).encode("ascii")
    request += f"{len(BODY):X}\r\n".encode("ascii") + BODY + b"\r\n"
    request += b"0\r\n"
    request += f"Upload-Checksum: sha1 {checksum}\r\n\r\n".encode("ascii")
    with socket.create_connection((HOST, PORT), timeout=10) as sock:
        sock.sendall(request)
        chunks = []
        while True:
            chunk = sock.recv(4096)
            if not chunk:
                break
            chunks.append(chunk)
            if b"\r\n\r\n" in b"".join(chunks):
                break
        response = b"".join(chunks).decode("iso-8859-1", errors="replace")
    return response

if "checksum-trailer" not in options_extensions():
    raise SystemExit(0)

upload_path = create_upload()
valid = base64.b64encode(hashlib.sha1(BODY).digest()).decode("ascii")
response = raw_patch_with_trailer(upload_path, valid)
status_line = response.split("\r\n", 1)[0]
if " 204 " not in status_line:
    raise SystemExit(f"checksum trailer PATCH failed: {response}")
if "Upload-Offset: 12" not in response and "upload-offset: 12" not in response.lower():
    raise SystemExit(f"checksum trailer response missing Upload-Offset 12: {response}")
```

Implementation note: parse response headers case-insensitively and do not assume one `recv(4096)` contains the full response header block.

- [x] **Step 4: Run Dagger verification**

```bash
dagger call run --server=TUSD --report=JUNIT export --path results/tusd-checksum-strict
dagger call run --server=RUSTUS --report=JUNIT export --path results/rustus-checksum-strict
dagger call run --server=TUS_NODE_SERVER --report=JUNIT export --path results/tus-node-checksum-strict
```

Expected: if a server advertises `checksum-trailer` and fails the probe, verify source before adding a skip. If a server does not advertise `checksum-trailer`, the probe exits successfully without testing behavior.

- [x] **Step 5: Commit checksum coverage**

```bash
git add tests/extensions/checksum tests/probes/checksum_trailer.py docs/server-noncompliance.md tests/skips
git commit -m "test: cover checksum validation and trailer behavior"
```

## Task 6: Add Concatenation And Termination Edge Coverage

**Files:**
- Modify: `tests/extensions/concatenation/ext-concat-001-create-partial.hurl`
- Modify: `tests/extensions/concatenation/ext-concat-002-create-final.hurl`
- Modify: `tests/extensions/concatenation/ext-concat-005-patch-final-forbidden.hurl`
- Modify: `tests/extensions/termination/ext-term-003-deleted-404-410.hurl`
- Create: `tests/extensions/concatenation/ext-concat-011-final-head-exact-concat.hurl`
- Create: `tests/extensions/concatenation/ext-concat-012-final-does-not-inherit-partial-metadata.hurl`

- [ ] **Step 1: Assert Upload-Concat in partial creation response**

Add this assertion to `ext-concat-001-create-partial.hurl`:

```hurl
header "Upload-Concat" == "partial"
```

- [ ] **Step 2: Assert Upload-Concat in final creation response**

In `ext-concat-002-create-final.hurl`, capture `final_url` and assert:

```hurl
header "Upload-Concat" == "final;{{partial1_url}} {{partial2_url}}"
```

- [ ] **Step 3: Add exact final HEAD echo test**

Create `ext-concat-011-final-head-exact-concat.hurl` with one completed partial, final creation `Upload-Concat: final;{{partial_url}}`, and final `HEAD` assertion:

```hurl
header "Upload-Concat" == "final;{{partial_url}}"
```

- [ ] **Step 4: Add final PATCH no-mutation checks**

Extend `ext-concat-005-patch-final-forbidden.hurl` after the `HTTP 403` response:

````hurl
HEAD {{final_url}}
Tus-Resumable: {{tus_version}}

HTTP *
[Asserts]
status toString matches /^(200|204)$/
header "Upload-Offset" == "6"
header "Upload-Length" == "6"

HEAD {{partial_url}}
Tus-Resumable: {{tus_version}}

HTTP *
[Asserts]
status toString matches /^(200|204)$/
header "Upload-Offset" == "6"
````

- [ ] **Step 5: Add final metadata non-transfer test**

Create `ext-concat-012-final-does-not-inherit-partial-metadata.hurl` with a partial upload containing `Upload-Metadata: filename cGFydGlhbC50eHQ=`, a final upload without metadata, and final `HEAD` assertion:

```hurl
header "Upload-Metadata" notExists
```

- [ ] **Step 6: Add PATCH after DELETE test**

Extend `ext-term-003-deleted-404-410.hurl` after the existing post-delete `HEAD` check:

````hurl
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
data
```

HTTP *
[Asserts]
status toString matches /^(404|410)$/
````

- [ ] **Step 7: Run Dagger verification**

```bash
dagger call run --server=TUSD --report=JUNIT export --path results/tusd-concat-term-strict
dagger call run --server=RUSTUS --report=JUNIT export --path results/rustus-concat-term-strict
dagger call run --server=TUS_NODE_SERVER --report=JUNIT export --path results/tus-node-concat-term-strict
```

- [ ] **Step 8: Commit concatenation and termination coverage**

```bash
git add tests/extensions/concatenation tests/extensions/termination/ext-term-003-deleted-404-410.hurl docs/server-noncompliance.md tests/skips
git commit -m "test: cover concatenation headers and termination follow-up requests"
```

## Task 7: Add Expiration Lifecycle Coverage

**Files:**
- Modify: `tests/extensions/expiration/ext-expire-001-post-response.hurl`
- Modify: `tests/extensions/expiration/ext-expire-002-patch-response.hurl`
- Create: `tests/probes/expiration_lifecycle.py`
- Modify: `dagger.dang` server configuration if a bundled server supports short expiration configuration.

- [ ] **Step 1: Correct the expiration Hurl comments and assertions**

Keep `ext-expire-001-post-response.hurl` as a creation smoke test and update its comments to say strict creation-time `Upload-Expires` validation lives in `tests/probes/expiration_lifecycle.py` when the server exposes a known expiration at creation.

For `ext-expire-002-patch-response.hurl`, assert `header "Upload-Expires" exists` and RFC 9110 date format after `PATCH` for servers that advertise `expiration` and are configured to expire unfinished uploads.

- [ ] **Step 2: Add expiration lifecycle probe**

Create `tests/probes/expiration_lifecycle.py`:

```python
import http.client
import os
import re
import time
from urllib.parse import urlparse

BASE_URL = os.environ.get("TUS_BASE_URL", "http://tus:8080/files")
parsed = urlparse(BASE_URL)
HOST = parsed.hostname or "tus"
PORT = parsed.port or (443 if parsed.scheme == "https" else 80)
BASE = parsed.path or "/files"
HTTP_DATE = re.compile(r"^(Mon|Tue|Wed|Thu|Fri|Sat|Sun), [0-9]{2} (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) [0-9]{4} [0-9]{2}:[0-9]{2}:[0-9]{2} GMT$")

def request(method, path, headers=None, body=None):
    conn = http.client.HTTPConnection(HOST, PORT, timeout=10)
    conn.request(method, path, body=body, headers=headers or {})
    res = conn.getresponse()
    data = res.read()
    return res.status, {k.lower(): v for k, v in res.getheaders()}, data

status, headers, _ = request("OPTIONS", BASE)
extensions = set(headers.get("tus-extension", "").split(",")) if headers.get("tus-extension") else set()
if "expiration" not in extensions:
    raise SystemExit(0)

status, headers, _ = request("POST", BASE, {"Tus-Resumable": "1.0.0", "Upload-Length": "100"})
if status != 201 or "location" not in headers:
    raise SystemExit(f"create failed: {status} {headers}")
upload_path = headers["location"] if headers["location"].startswith("/") else "/" + headers["location"].split("/", 3)[3]

status, headers, _ = request(
    "PATCH",
    upload_path,
    {"Tus-Resumable": "1.0.0", "Upload-Offset": "0", "Content-Type": "application/offset+octet-stream"},
    b"partial data\n",
)
if status != 204:
    raise SystemExit(f"patch failed: {status} {headers}")
expires = headers.get("upload-expires")
if not expires or not HTTP_DATE.fullmatch(expires):
    raise SystemExit(f"PATCH missing valid Upload-Expires: {headers}")

wait_seconds = int(os.environ.get("TUS_EXPIRATION_WAIT_SECONDS", "0"))
if wait_seconds <= 0:
    raise SystemExit(0)
deadline = time.monotonic() + wait_seconds + int(os.environ.get("TUS_EXPIRATION_GRACE_SECONDS", "5"))
time.sleep(wait_seconds)

last_status = None
while time.monotonic() <= deadline:
    status, headers, _ = request("HEAD", upload_path, {"Tus-Resumable": "1.0.0"})
    last_status = status
    if status in (404, 410):
        raise SystemExit(0)
    time.sleep(1)

raise SystemExit(f"expired upload returned {last_status}, expected 404 or 410 before deadline")
```

Implementation note: use polling with a small grace period instead of a single `sleep` plus one `HEAD`, because expiration checks can be delayed under CI load.

- [ ] **Step 3: Configure existing servers for expiration where possible**

Inspect source/docs for tusd, rustus, and tus-node-server to find whether a short unfinished-upload expiration can be configured. If a server can be configured, modify `mapService` for that server to set a short expiration only when running expiration tests. If a server advertises expiration but cannot satisfy the probe, verify the source and add a skip.

- [ ] **Step 4: Run expiration verification**

```bash
dagger call run --server=TUSD --report=JUNIT export --path results/tusd-expiration-strict
dagger call run --server=RUSTUS --report=JUNIT export --path results/rustus-expiration-strict
dagger call run --server=TUS_NODE_SERVER --report=JUNIT export --path results/tus-node-expiration-strict
```

- [ ] **Step 5: Commit expiration coverage**

```bash
git add tests/extensions/expiration tests/probes/expiration_lifecycle.py dagger.dang docs/server-noncompliance.md tests/skips
git commit -m "test: cover expiration headers and lifecycle behavior"
```

## Task 8: Full Server Matrix Verification And Source Review

**Files:**
- Modify: `docs/server-noncompliance.md`
- Modify: `tests/skips/tusd.txt`
- Modify: `tests/skips/rustus.txt`
- Modify: `tests/skips/tus-node-server.txt`

- [ ] **Step 1: Run full Dagger matrix**

```bash
dagger call run --server=TUSD --report=JUNIT export --path results/tusd-full
dagger call run --server=RUSTUS --report=JUNIT export --path results/rustus-full
dagger call run --server=TUS_NODE_SERVER --report=JUNIT export --path results/tus-node-full
```

- [ ] **Step 2: Classify each failure**

For every failing test, classify it as one of:

```text
TEST_BUG: the compliance test is wrong or too strict for the spec.
UNSUPPORTED_EXTENSION: the server does not advertise the extension; do not run that extension for the server.
SERVER_NONCOMPLIANCE: the server advertises/supports the behavior but violates the spec.
ENVIRONMENT_GAP: the Dagger server config does not enable the feature needed for the test.
```

- [ ] **Step 3: Verify server non-compliance in source**

For each `SERVER_NONCOMPLIANCE`, inspect the corresponding source clone under `/tmp/opencode/tus-source-audit`. Use content search for the protocol header or method, then read the relevant implementation file. Record exact source file and line references in `docs/server-noncompliance.md`.

- [ ] **Step 4: Add skips only for source-verified server non-compliance**

Add exact relative paths to the relevant skip file:

```text
# See docs/server-noncompliance.md#<server-short-behavior>
tests/path/to/failing-test.hurl
tests/probes/failing_probe.py
```

- [ ] **Step 5: Re-run full matrix after skips**

```bash
dagger call run --server=TUSD --report=JUNIT export --path results/tusd-full-after-skips
dagger call run --server=RUSTUS --report=JUNIT export --path results/rustus-full-after-skips
dagger call run --server=TUS_NODE_SERVER --report=JUNIT export --path results/tus-node-full-after-skips
```

Expected: remaining failures are test bugs or environment gaps to fix before proceeding. `results/*/skipped-<server>.txt` lists only source-verified skips.

- [ ] **Step 6: Commit server notes and skips**

```bash
git add docs/server-noncompliance.md tests/skips
git commit -m "test: document source-verified server compliance skips"
```

## Task 9: Documentation And Audit Checklist

**Files:**
- Modify: `README.md`
- Modify: `tests/README.md`
- Create: `docs/protocol-coverage-audit.md`

- [ ] **Step 1: Update README Dagger commands**

Document:

```bash
dagger call run export --path results/all
dagger call run --server=TUSD --report=JUNIT export --path results/tusd
dagger call run --server=RUSTUS --report=JUNIT export --path results/rustus
dagger call run --server=TUS_NODE_SERVER --report=JUNIT export --path results/tus-node-server
```

- [ ] **Step 2: Document skip policy**

Add a section explaining that `tests/skips/<server>.txt` is not a convenience ignore list. Every entry must link to `docs/server-noncompliance.md` with source evidence.

- [ ] **Step 3: Finalize protocol coverage audit**

Update `docs/protocol-coverage-audit.md` with a table mapping the 13 findings to implemented test paths:

```markdown
# tus Protocol Coverage Audit

| Finding | Coverage Added | Verification |
|---|---|---|
| X-HTTP-Method-Override | `tests/core/cp-override/cp-override-001-post-overrides-patch.hurl`, `tests/extensions/termination/ext-term-006-post-overrides-delete.hurl` | Dagger matrix |
| OPTIONS ignores Tus-Resumable | `tests/core/cp-opt/cp-opt-006-ignore-tus-resumable.hurl` | Dagger matrix |
```

Complete the table for every finding from the review.

- [ ] **Step 4: Commit docs**

```bash
git add README.md tests/README.md docs/protocol-coverage-audit.md
git commit -m "docs: document tus compliance coverage and skip policy"
```

## Task 10: Final Verification

**Files:**
- Read: `results/`
- Read: `docs/protocol-coverage-audit.md`
- Read: `docs/server-noncompliance.md`

- [ ] **Step 1: Run syntax checks for Hurl files**

```bash
hurl --check tests/**/*.hurl
```

Expected: no syntax errors.

- [ ] **Step 2: Run full Dagger verification**

```bash
dagger call run --report=JUNIT export --path results/final-all
```

Expected: Dagger completes. Any skipped test appears in `results/final-all/<server>/skipped-<server>.txt` and has a matching source-verified entry in `docs/server-noncompliance.md`.

- [ ] **Step 3: Verify coverage audit has no gaps**

Read `docs/protocol-coverage-audit.md` and confirm each original finding has at least one concrete test or probe path.

- [ ] **Step 4: Commit final verification updates if any**

```bash
git add docs/server-noncompliance.md docs/protocol-coverage-audit.md tests/skips
git commit -m "test: finalize tus compliance coverage audit"
```

Skip this commit if those files did not change during final verification.

## Self-Review Notes

- Spec coverage: all 13 confirmed findings are represented by tasks.
- Dagger verification: every implementation task includes at least one Dagger run, and Task 10 runs the full matrix.
- Server non-compliance handling: the plan requires source-code verification before a skip and records evidence in `docs/server-noncompliance.md`.
- Hurl limitations: checksum trailers and real expiration timing use probe scripts run through Dagger.
- Ambiguity resolved: unsupported extensions are not treated as non-compliance; advertised but broken behavior is.

---

## GSTACK AUTOPLAN REVIEW

Status: Phase 1 CEO review in progress. Premise gate pending.

Base branch: `main`

UI scope: no. The plan mentions generated reports and docs but does not introduce application screens, interactive UI, or frontend components.

DX scope: yes. This repository is a developer-facing compliance test suite with Dagger commands, shell runner behavior, server matrix workflows, documentation, and onboarding impact.

Codex preflight: unavailable. `codex` binary was not found, so all Codex voice slots are marked unavailable and the review proceeds with Claude subagent only.

### Phase 1, Step 0A: Premise Challenge

| Premise | Assessment | Evidence | Risk if Wrong | Decision |
|---|---|---|---|---|
| The existing suite has real tus 1.0.0 coverage gaps. | Valid. | Existing `tests/README.md` lists many related tests, but examples like `tests/core/cp-opt/cp-opt-005-tus-max-size.hurl` only verify OPTIONS succeeds and do not validate conditional `Tus-Max-Size` format or enforcement. `tests/extensions/checksum-trailer/ext-csum-tr-001-checksum-trailer.hurl` checks advertisement only, not trailer behavior. | The work could add churn without improving conformance. | Accept. |
| Strict tests should not be weakened to keep bundled servers green. | Valid. | The plan explicitly rejects broad status ranges and requires source-verified skips. This matches the product goal of conformance rather than compatibility theater. | The suite becomes a server demo instead of a compliance suite. | Accept. |
| Server-specific skip manifests are enough to handle bundled server differences. | Incomplete. | Current `dagger.dang` defaults to `Extension.values`, which runs every extension directory for every server unless callers override `extension`. The plan says unsupported extensions are not non-compliance, but static skip files only model known failures, not unsupported capabilities. | Unsupported extension failures get mislabeled as non-compliance or hidden in skip manifests, eroding trust. | Expand: add first-class capability gating and separate unsupported reports. |
| Raw Python probes are needed for cases Hurl cannot express reliably. | Valid. | HTTP trailers require raw chunked framing, and expiration lifecycle needs real waits and server timing behavior. Existing Hurl files do not cover those behaviors. | Hurl-only coverage claims 100 percent while leaving protocol behavior untested. | Accept. |
| Source evidence can use local clones under `/tmp/opencode`. | Valid but needs a durability rule. | The plan requires source verification and file/line evidence, but local clone paths and line numbers drift unless paired with commit SHAs or immutable source URLs. | Skip evidence rots, and future maintainers cannot verify why a server was skipped. | Expand: require source commit SHA plus file/line evidence for every server note. |
| The scope is large but appropriate for the goal. | Valid. | The goal is full compliance coverage, and the plan touches Dagger, docs, Hurl files, Python probes, and server notes. This is broad but coherent. | Under-scoping leaves hidden gaps that the suite claims to close. | Accept, with sequencing and validation guardrails. |

### Phase 1, Step 0B: Existing Code Leverage Map

| Sub-problem | Existing Code | Reuse Strategy | Gap |
|---|---|---|---|
| Dagger server matrix | `dagger.dang` `Server`, `Extension`, `ReportFormat`, `run`, `test`, `mapService` | Reuse the existing matrix and report plumbing. Replace only the test runner container and command assembly. | Needs server name, capability gating, skip manifests, probe execution, and unsupported reports. |
| Local/manual runner | `run-tests.sh` | Keep as reference for path categories and docs. Do not make it the primary matrix runner. | Uses shell category routing, not server capability filtering. |
| Core Hurl patterns | `tests/core/cp-*/*.hurl` | Copy the existing create/capture/PATCH/HEAD patterns for new mutation and grammar tests. | Needs method override, unsupported-version no-mutation, and integer grammar additions. |
| Extension Hurl patterns | `tests/extensions/*/*.hurl` | Extend existing extension-specific flows instead of introducing a new DSL. | Some tests are smoke tests or optional guidance instead of strict conditional protocol checks. |
| Server definitions | `compose.yaml`, `dagger.dang`, `servers/Dockerfile.tus-node-server` | Keep existing server images and config as the bundled matrix baseline. | Dagger server names and service capabilities are not represented as data. |
| Documentation | `README.md`, `tests/README.md` | Update current Quick Start and catalog rather than adding detached docs. | Current README has incomplete numbering and no skip policy, raw-vs-filtered report model, or external server examples. |

### Phase 1, Step 0C: Dream State Diagram

```text
CURRENT
  Existing Hurl suite + Dagger matrix
  Runs broad test directories against bundled servers
  Some tests are smoke checks or optional notes
  No first-class skip/capability/report model
    |
    v
THIS PLAN, AFTER REVIEW ADJUSTMENTS
  Spec-traced strict tests + Python probes
  Dagger runner applies capability manifests before non-compliance skips
  Raw results and filtered results are both visible
  Server non-compliance notes include source commit SHA evidence
  Coverage audit maps every known gap to concrete test/probe paths
    |
    v
12-MONTH IDEAL
  Trusted tus conformance product
  Any server can run against the suite with one documented command
  Machine-readable conformance report, spec clause map, badges, CI template
  Bundled server matrix acts as regression evidence, not the whole product
```

Dream state delta: this plan can become a trusted conformance suite if it adds spec traceability, capability gating, and raw-vs-filtered reporting now. Full external packaging, badges, and a standalone CLI are useful 12-month product moves but are outside the immediate blast radius.

### Phase 1, Step 0C-bis: Implementation Alternatives

| Approach | Effort | Risk | Pros | Cons | Decision |
|---|---:|---|---|---|---|
| Hurl-only strict tests with no runner changes | Low | High | Smallest diff and familiar workflow. | Cannot express HTTP trailers or real expiration lifecycle, and does not solve server-specific unsupported extension handling. | Reject. |
| Current plan plus capability gating, raw-vs-filtered reports, source SHA evidence | Medium | Medium | Keeps Hurl as the main test language, uses Python only for protocol gaps, and makes server results defensible. | Adds runner complexity and requires one more manifest/report concept. | Choose. |
| Full conformance product now with standalone CLI, JSON schema, badges, GitHub Action, and public scorecards | High | Medium | Best long-term adoption path and stronger competitive positioning. | Expands beyond this repo's immediate compliance coverage objective and adds distribution scope. | Defer to `TODOS.md`. |

### Phase 1, Step 0D: Mode-Specific Analysis

Mode: SELECTIVE EXPANSION.

Auto-approved in blast radius:

| Expansion | Principle | Rationale | Files Likely Affected |
|---|---|---|---|
| Add server capability manifests or equivalent Dagger capability map. | P1, P2, P5 | Unsupported extensions are not server non-compliance. The runner needs to classify them before skip manifests are considered. | `dagger.dang`, `tests/scripts/run-suite.sh`, `tests/capabilities/*`, `README.md`, `tests/README.md` |
| Emit separate `unsupported-<server>.txt`, `skipped-<server>.txt`, and active test lists. | P1, P5 | A filtered pass is useful, but raw unsupported and known-broken behavior must stay visible. | `tests/scripts/run-suite.sh`, `README.md`, `docs/server-noncompliance.md` |
| Require source commit SHA or immutable URL for every server non-compliance entry. | P1, P3 | File and line evidence without a revision will rot. | `docs/server-noncompliance.md`, `tests/skips/*` |
| Move the coverage audit skeleton earlier, before or during Task 1. | P1, P3 | The 13 findings are the source of truth for the plan, so they should exist before implementation relies on them. | `docs/protocol-coverage-audit.md`, plan task order |

Deferred to TODOs, not this implementation pass:

| Deferred Item | Reason |
|---|---|
| Standalone `tus-compliance run --base-url ...` CLI. | Useful external adoption path, but it introduces packaging and distribution scope beyond the current Dagger/Hurl test suite. |
| Public conformance badges and hosted scorecards. | Strong 12-month product direction, but not required to make the suite strict and source-verifiable. |
| Spec-generated tests from protocol clauses. | Attractive long-term traceability, but this plan can achieve the current goal with explicit Hurl/probe tests plus coverage audit. |

### Phase 1, Step 0E: Temporal Interrogation

| Time | What Happens | Failure Mode | Rescue |
|---|---|---|---|
| Hour 1 | Runner image, skip files, and script are added. | Dang syntax or runner path assumptions break all tests. | Verify against one baseline server before adding new tests. |
| Hour 2 | Core and header grammar tests land. | Tests assume status codes stricter than the spec or fail to verify no mutation. | Pair each rejection test with a follow-up `HEAD` where mutation risk exists. |
| Hour 3 | Creation, metadata, checksum, and trailer coverage lands. | Hurl cannot express a conditional assertion, so the suite silently under-tests. | Use Python probes for conditional OPTIONS validation and raw trailer behavior. |
| Hour 4 | Concatenation, termination, and expiration coverage lands. | Expiration behavior depends on server configuration and timing. | Only assert lifecycle when expiration is advertised and wait config is explicitly enabled. |
| Hour 5 | Full bundled matrix runs. | Unsupported extensions inflate failure counts or get added to skip files. | Capability gating must classify unsupported extension tests separately from source-verified non-compliance. |
| Hour 6+ | Docs and final audit are updated. | Future maintainers cannot tell whether a green result is raw, filtered, or skip-assisted. | Publish raw, unsupported, skipped, and filtered result files with documentation. |

### Phase 1, Step 0F: Mode Selection Confirmation

Mode remains SELECTIVE EXPANSION. The plan's baseline scope is accepted, but four blast-radius expansions are required to make the plan trustworthy: capability gating, raw-vs-filtered reporting, durable source evidence, and earlier coverage audit setup.

### Phase 1, Step 0.5: Dual Voices

Codex: unavailable, binary not found.

Claude subagent findings:

| Severity | Finding | Recommended Fix |
|---|---|---|
| High | The problem is framed as missing coverage rather than trusted tus conformance. | Reframe the plan around a spec-traceable conformance suite with reproducible server reports. |
| High | The 13 findings are referenced but not preserved as evidence. | Move the findings into the plan or create the coverage audit before implementation. |
| Critical | Server-specific skips can become a legitimacy trap. | Separate raw conformance results from filtered known-noncompliance results. |
| High | Optional extension gating is under-designed. | Add extension capability metadata and unsupported-extension reports. |
| Medium | Alternatives are too weak. | Compare against manifest-driven tests, generated spec tests, upstream integration, and standalone runner. |
| Medium | Six-month regret is brittle maintenance. | Add source SHAs, skip validation, probe conventions, and matrix refresh mechanics. |
| High | External adoption path is missing. | Defer a minimal external-facing runner/report path to TODO unless scope expands. |

CEO dual voices consensus table:

| Dimension | Claude | Codex | Consensus |
|---|---|---|---|
| Premises valid? | Partly. Coverage gap premise valid, skip/capability premise incomplete. | N/A | N/A, single voice flags premise gap. |
| Right problem to solve? | Broaden from missing tests to trusted conformance. | N/A | N/A, single voice strategic expansion. |
| Scope calibration correct? | Mostly, but needs capability/report guardrails. | N/A | N/A, single voice high-confidence issue. |
| Alternatives sufficiently explored? | No. Real alternatives were not compared. | N/A | N/A. |
| Competitive/market risks covered? | No. External adoption path is missing. | N/A | N/A. |
| 6-month trajectory sound? | At risk from stale skips and source evidence. | N/A | N/A. |

### Phase 1 Required Premise Gate

Passed. User approved the adjusted premises: keep the original strict coverage goal, but add capability gating, raw-vs-filtered reports, durable source evidence, and earlier coverage audit setup.

### Phase 1 Sections 1-10: CEO Review Findings

#### Section 1: Problem And User Outcome

Examined `README.md`, `tests/README.md`, `dagger.dang`, and the implementation plan. The plan solves a real gap, but the user-visible outcome should be stronger than “more tests exist.” The outcome should be: a server author can run the suite and understand whether failures are protocol non-compliance, unsupported extensions, environment gaps, or test bugs.

Finding: `README.md` currently sells a “comprehensive test suite” with 123 tests, while the plan adds strict coverage and source-verified skips without initially naming the result model. Auto-decision: update the plan toward conformance reporting, not just test count growth.

#### Section 2: Error And Rescue Registry

| Error / Rescue Case | Trigger | What User Sees | Rescue Path | Plan Change |
|---|---|---|---|---|
| Unsupported extension treated as failure | Runner sends `tests/extensions/<ext>` to a server that does not advertise `<ext>` | Dagger fails or a maintainer adds a bad skip | Put file in `results/unsupported-<server>.txt`, not `tests/skips/<server>.txt` | Added capability gating to runner plan. |
| Source evidence rots | Upstream server code changes after local line evidence was recorded | `docs/server-noncompliance.md` points to wrong code | Record commit SHA or immutable source URL | Added source revision requirement. |
| Filtered pass hides raw failure | Server passes after skips | Maintainer cannot tell whether the server is compliant or accepted-known-broken | Publish raw, unsupported, skipped, and active lists | Added separate result files. |
| Probe silently no-ops | Probe exits 0 when extension is absent or wait config disabled | Coverage appears present but behavior was not tested | Probe must state its skip reason in report/log when possible | Carry into Eng review as implementation requirement. |
| Hurl conditional limitation hides invalid header | Hurl cannot assert “if header present, validate value” | Bad `Tus-Max-Size` or `Tus-Extension` format passes | Use `options_headers.py` probe | Already in plan, now tied to coverage audit. |

#### Section 3: Scope Calibration

Examined planned file count and blast radius. The scope is large but coherent because the goal is full conformance coverage. Reducing scope would leave precisely the hidden edge cases that motivated this plan.

Auto-decision: do not reduce the implementation tasks. Add guardrails inside Task 1 and Task 9 because they are in the runner/docs blast radius and prevent false confidence.

#### Section 4: Trust Model

The trust boundary is not security authentication; it is report interpretation. A compliance suite loses trust if a reader cannot distinguish raw failures from accepted upstream non-compliance.

Auto-decision: require every final Dagger result to surface `all-*`, `unsupported-*`, `skipped-*`, and `active-*` lists. A “green” filtered result is acceptable only when the hidden parts are inspectable.

#### Section 5: Alternatives Review

| Alternative | Assessment | Decision |
|---|---|---|
| Weaken tests with broad status ranges | Makes bundled servers green but destroys conformance value. | Reject. |
| Manual checklist for Hurl gaps | Documents gaps but does not prevent regressions. | Reject. |
| Hurl-only strict suite | Insufficient for trailers and timing-dependent expiration behavior. | Reject. |
| Manifest/capability-driven runner plus Hurl/probes | Best fit for current repo and Dagger matrix. | Choose. |
| Generated tests from spec clauses | Strong future direction but requires a source-of-truth spec model not present today. | Defer. |
| Standalone CLI and badges | Strong external adoption path but expands beyond immediate coverage closure. | Defer. |

#### Section 6: Competitive And Adoption Risk

The plan does not need to ship a public product now, but it should avoid painting itself into an internal-only corner. The smallest adoption hedge is a spec coverage audit plus a Dagger command that arbitrary server implementers can understand.

Auto-decision: keep standalone CLI and badges out of current scope, but make README updates include a clear “run against bundled servers” path and result interpretation policy. If later work adds arbitrary external server targets, it should build on the same result model.

#### Section 7: Maintenance Risk

The highest 6-month risk is stale skips and unclear probe semantics. Python probes must be small, deterministic, and documented by their path and report behavior.

Auto-decision: require probe behavior to be represented in `docs/protocol-coverage-audit.md` and source skip evidence to include revisions. Add skip validation to Phase 3 as an engineering review issue.

#### Section 8: Sequencing Risk

Task order mostly works, but the coverage audit cannot wait until Task 9 because implementation depends on the list of 13 findings. Creating the audit early gives every task a checklist to update.

Auto-decision: Task 1 now creates the initial `docs/protocol-coverage-audit.md`. Task 9 remains responsible for final polish and completeness verification.

#### Section 9: Stakeholder Communication

The plan now has two audiences: maintainers implementing tests and server authors reading reports. Docs must avoid implying server-specific skips are convenience ignores.

Auto-decision: README and `tests/README.md` must explain that `unsupported-*` means “server did not advertise this extension,” while `skipped-*` means “server advertised or supports behavior but source evidence confirms known non-compliance.”

#### Section 10: Launch Readiness

Launch readiness is not just “Dagger exits successfully.” It requires final evidence files and an audit table that maps every coverage finding to implemented paths.

Auto-decision: final verification must check `docs/protocol-coverage-audit.md`, `docs/server-noncompliance.md`, and result files for each bundled server. Dagger green without those artifacts is incomplete.

### Phase 1 NOT In Scope

| Item | Rationale |
|---|---|
| Standalone CLI package | Valuable for broad adoption, but adds packaging, installation, and distribution concerns beyond this plan. |
| Public badges or hosted scorecards | Useful later once report schema stabilizes. Not required for strict bundled-matrix verification. |
| Spec-generated test framework | Long-term traceability improvement, but explicit Hurl/probe tests plus coverage audit are enough for this lake. |
| Arbitrary remote server target support | The current plan validates bundled servers. External target support should reuse the result model later. |

### Phase 1 What Already Exists

| Capability | Existing Location | How The Plan Uses It |
|---|---|---|
| Server matrix | `dagger.dang` `Server` enum and `mapService` | Keep server setup, add server identity and runner script. |
| Report formats | `dagger.dang` `ReportFormat` enum | Preserve HTML/JSON/JUnit/TAP support through env vars. |
| Core protocol structure | `tests/core/*` | Add focused Hurl files in existing categories. |
| Extension structure | `tests/extensions/*` | Add and update focused extension tests. |
| Local runner categories | `run-tests.sh` | Use as reference for docs, not the primary matrix runner. |
| Server docs | `README.md`, `tests/README.md` | Update existing docs instead of creating a parallel manual. |

### Phase 1 Failure Modes Registry

| Failure Mode | Severity | Detection | Mitigation |
|---|---|---|---|
| Unsupported extension failures are added to skip manifests. | Critical | `results/unsupported-*` empty but extension directories fail for unadvertised capabilities. | Capability gating before skip filtering. |
| Source evidence no longer matches upstream. | High | Server note has no commit SHA or immutable URL. | Make source revision required. |
| Probes fail due to environment rather than protocol behavior. | High | Probe error lacks problem/cause/fix or server capability context. | Engineering review must require actionable probe errors. |
| Dagger runner builds but silently drops tests. | High | `active-*` count lower than expected with no unsupported or skipped explanation. | Emit `all-*`, `raw-active-*`, `unsupported-*`, `skipped-*`, `active-*`. |
| Final documentation claims full compliance without caveats. | Medium | README lacks raw-vs-filtered explanation. | Add result interpretation section. |

### Phase 1 Completion Summary

| Area | Result |
|---|---|
| Premises | Approved with guardrails. |
| Mode | SELECTIVE EXPANSION. |
| Codex voice | Unavailable, binary not found. |
| Claude subagent | 7 findings, 1 critical, 4 high, 2 medium. |
| Consensus | Single-model mode, no Codex confirmations. |
| Decisions logged | 6 so far. |
| Open user challenges | None. |
| Taste decisions | None. |

**Phase 1 complete.** Codex: unavailable. Claude subagent: 7 issues. Consensus: 0/6 confirmed because only one outside voice was available. Passing to Phase 2.

### Phase 2: Design Review

Phase 2 skipped. No UI scope was detected: the plan changes a developer-facing test suite, Dagger runner, Hurl files, Python probes, and documentation, but does not add or modify application screens, visual components, layout, responsive behavior, or interaction design.

Design completion summary: skipped, no UI scope.

### Phase 3: Engineering Review

#### Phase 3 Step 0: Scope Challenge With Actual Code Analysis

Read actual repo files: `dagger.dang`, `run-tests.sh`, `README.md`, `tests/README.md`, `compose.yaml`, `servers/Dockerfile.tus-node-server`, representative Hurl tests under `tests/core`, `tests/extensions/checksum`, `tests/extensions/checksum-trailer`, `tests/extensions/expiration`, `tests/extensions/concatenation`, and `tests/extensions/termination`.

The plan touches more than eight files, but that is not overbuilt for the stated goal. The existing suite already has many focused Hurl tests, and the missing behaviors span core protocol, creation, checksum, trailers, concatenation, termination, expiration, runner behavior, and docs. The safer reduction is not fewer test categories. The safer design is to make the runner/report model explicit so the large coverage expansion does not hide failures.

Concrete scope finding: `dagger.dang` currently runs `Extension.values` by default and appends every extension directory through `args += ["--glob", "tests/extensions/" + extName + "/**/*.hurl"]`. That design cannot distinguish unsupported extension tests from non-compliance. The reviewed plan now changes runner behavior before adding new strict tests.

#### Phase 3 Step 0.5: Dual Voices

CODEX SAYS (eng - architecture challenge): unavailable, binary not found.

CLAUDE SUBAGENT (eng - independent review):

| Severity | Finding | Fix Applied To Plan |
|---|---|---|
| P1 | Failed OPTIONS or missing `Tus-Extension` made every extension active. | Runner now treats failed discovery or missing extensions as no advertised extensions and writes discovery evidence. |
| P1 | Probes were outside the capability/report model. | Runner requirements now make probes first-class selected paths with status and result-list handling. |
| P1 | `expect: ReturnType.ANY` could hide real test failures. | Plan now forbids keeping it unless Dagger explicitly checks `status-<server>.txt`. |
| P1 | Runner filtering lacked direct tests. | Added shell-level fixture tests for runner filtering and skip ordering. |
| P2 | Expiration lifecycle would be flaky under load. | Expiration probe now polls until deadline with grace. |
| P2 | Checksum trailer probe read only one socket chunk. | Probe now reads until response headers are complete. |
| P2 | `Tus-Extension` parser rejected optional whitespace. | Parser now splits on comma and trims whitespace per token. |
| P2 | `TUS_SERVER_NAME` was used in paths without validation. | Runner now validates server names. |
| P2 | Runner image downloaded Hurl without integrity verification. | Dockerfile plan now requires SHA256 verification. |
| P2 | Targeted Dagger runs executed unrelated probes. | Plan now requires explicit `probePaths` and no checksum/expiration probes for core-only runs. |
| P3 | Coverage audit was specified twice as create. | Task 9 now finalizes the audit created in Task 1. |
| P3 | Several negative tests asserted exact `400` without status audit. | Added status-code assertion policy. |

ENG DUAL VOICES - CONSENSUS TABLE:

| Dimension | Claude | Codex | Consensus |
|---|---|---|---|
| Architecture sound? | Needs runner semantics fixes, now applied. | N/A | N/A, single voice. |
| Test coverage sufficient? | Missing runner fixture tests, now added. | N/A | N/A. |
| Performance risks addressed? | Expiration timing flake risk, now mitigated by polling. | N/A | N/A. |
| Security threats covered? | Hurl download integrity and server-name path validation needed, now added. | N/A | N/A. |
| Error paths handled? | OPTIONS failure and probe failure semantics needed, now added. | N/A | N/A. |
| Deployment risk manageable? | Dagger could export failed results as if passing, now flagged. | N/A | N/A. |

#### Phase 3 Section 1: Architecture

ASCII dependency graph:

```text
dagger.dang
  |
  | builds
  v
tests/Dockerfile.runner
  |
  | runs
  v
tests/scripts/run-suite.sh
  |-- OPTIONS discovery -> advertised extension set
  |-- Hurl path discovery -> all-<server>.txt
  |-- capability filtering -> unsupported-<server>.txt
  |-- source-verified skip filtering -> skipped-<server>.txt
  |-- final runnable list -> active-<server>.txt
  |-- selected Python probes -> status-<server>.txt
  v
results/<server>/
  |-- hurl reports
  |-- raw/unsupported/skipped/active lists
  |-- stderr and status files
  v
docs/protocol-coverage-audit.md + docs/server-noncompliance.md
```

Architecture assessment: the right boundary is a thin runner script, not a second test DSL. Hurl remains the primary protocol assertion format, while Python probes cover protocol behavior Hurl cannot reliably express. The main coupling risk is between extension directory names and `Tus-Extension` tokens; the plan accepts this because the repo already uses extension directory names matching tus extension names. The runner must make that coupling visible in tests.

Security assessment: the new runner is not a network service, but it consumes `TUS_SERVER_NAME`, downloads a `.deb`, and parses server headers. The plan now validates server names, verifies Hurl release integrity, and treats OPTIONS parsing failures as explicit artifacts instead of silent broad execution.

#### Phase 3 Section 2: Code Quality

Code quality findings were applied to the plan body:

| Finding | Reason | Decision |
|---|---|---|
| Probe handling duplicated outside Hurl filtering. | Probes need the same selected/unsupported/skipped/status lifecycle as Hurl files. | Make probes first-class paths. |
| Result semantics were implicit. | A result directory can exist even when tests fail. | Require `status-<server>.txt` and fail Dagger unless intentionally exporting failed evidence. |
| Status assertions risk over-specifying `400`. | Some tus sections require rejection, not an exact status. | Add exact-vs-ranged status-code policy. |
| Coverage audit task duplicated create behavior. | Duplicate create instructions can overwrite implementation evidence. | Task 1 creates, Task 9 finalizes. |

No existing ASCII diagrams were found in touched files, so there are no stale diagrams to update.

#### Phase 3 Section 3: Test Review

Test diagram mapping codepaths to coverage:

| New Codepath / Branch | Test Type | Existing Coverage | Gap Before Review | Plan Requirement |
|---|---|---|---|---|
| Runner receives failed OPTIONS discovery | Shell fixture | None | Would run every extension | Fixture must assert all extension tests become unsupported and discovery error is written. |
| Runner receives no `Tus-Extension` header | Shell fixture | None | Would run every extension | Fixture must assert no extensions are active. |
| Runner receives partial advertised extensions | Shell fixture | None | Unsupported extension classification untested | Fixture must assert only advertised extension dirs stay active. |
| Skip file contains active path | Shell fixture | None | Skip ordering untested | Fixture must assert exact active path goes to skipped list. |
| Skip file contains unsupported path | Shell fixture | None | Unsupported tests could become skips | Fixture must assert unsupported wins before skipped. |
| Missing skip file | Shell fixture | Existing happy-path Dagger only | Could fail script or hide empty skipped file | Fixture must assert empty skipped report. |
| Invalid `TUS_SERVER_NAME` | Shell fixture | None | Path traversal or bad result filenames | Fixture must assert nonzero exit before reading skip path. |
| Core-only run | Shell fixture or Dagger targeted run | Current Dagger can target extensions but no probes exist | Unrelated probes could run | Fixture must assert checksum/expiration probes do not run. |
| Probe selected and skipped | Shell fixture | None | Probe skip semantics untested | Fixture must assert probe path appears in skipped list and does not execute. |
| Method override PATCH/DELETE | Hurl + Dagger | No current coverage | Override behavior untested | New Hurl tests plus Dagger task run. |
| Unsupported version no mutation | Hurl + Dagger | Existing HEAD unsupported version only | POST/PATCH mutation risk untested | New Hurl tests with follow-up `HEAD`. |
| Header integer grammar | Hurl + Dagger | Missing negative offset and non-integer length | Bad grammar may mutate state | Negative tests with status policy plus no-mutation checks. |
| Conditional OPTIONS headers | Python probe | Hurl cannot conditional assert | Bad optional header values pass | `options_headers.py`. |
| Checksum trailer raw behavior | Python probe | Existing test only checks advertisement | Trailer behavior not exercised | `checksum_trailer.py`, first-class probe path. |
| Expiration lifecycle | Python probe | Existing Hurl comments/smoke tests | Timing behavior flaky or untested | Polling `expiration_lifecycle.py` with per-server wait config. |
| Server non-compliance skip evidence | Docs + fixture/manual check | None | Skips can drift or lack source revision | Require commit SHA and exact doc link. |

Test plan artifact written: `/home/laborant/.gstack/projects/tus-compliance-tests/laborant-main-test-plan-20260506-094818.md`.

#### Phase 3 Section 4: Performance

The suite runs many small HTTP tests and some Python probes. The main performance risk is CI time from running the full matrix repeatedly, but this is acceptable for a compliance suite. The plan keeps task-level Dagger runs for fast feedback and a full matrix at the end.

Specific performance risk: expiration lifecycle waits can dominate runtime and flake under load. The plan now requires per-server wait config, polling with grace, and no-op behavior when expiration is not advertised or wait is disabled. Checksum trailer probes should use bounded socket timeouts and read only response headers needed for assertions.

#### Phase 3 NOT In Scope

| Item | Rationale |
|---|---|
| Replacing Hurl with a custom protocol test DSL | Unnecessary. Existing Hurl structure is useful and readable. |
| Full property-based protocol test generation | Useful later, but explicit coverage is enough here. |
| Benchmarking upload throughput | This suite validates protocol compliance, not server performance. |

#### Phase 3 What Already Exists

| Existing Piece | Engineering Use |
|---|---|
| `dagger.dang` enums and service bindings | Keep as server and report control plane. |
| `tests/core` and `tests/extensions` directory taxonomy | Keep as source of test organization and extension mapping. |
| Hurl capture/assert patterns | Reuse for all ordinary protocol checks. |
| `compose.yaml` and server Dockerfile | Use as cross-check for Dagger bundled server config. |
| `tests/README.md` catalog | Update counts and strict coverage notes after implementation. |

#### Phase 3 Failure Modes Registry

| Failure Mode | Critical Gap? | Mitigation |
|---|---|---|
| Dagger exports result directory after failed tests and caller assumes pass. | Yes | Remove `ReturnType.ANY` or explicitly assert `status-<server>.txt`. |
| Failed OPTIONS activates every extension. | Yes | Treat discovery failure as no extensions and write error artifact. |
| Probe exits success for unsupported behavior without report visibility. | Yes | Make probe paths first-class in result lists and skip/status handling. |
| Raw socket probe reads partial response. | No | Read until header terminator or connection close. |
| Expiration probe flakes due to timing. | No | Poll with deadline and grace. |
| Hurl `.deb` supply-chain integrity is unchecked. | No | Verify SHA256. |
| Negative tests assert the wrong exact status. | No | Enforce status-code assertion policy and no-mutation checks. |

#### Phase 3 Completion Summary

| Area | Result |
|---|---|
| Codex voice | Unavailable, binary not found. |
| Claude subagent | 12 findings, 4 P1, 6 P2, 2 P3. |
| Architecture | Sound after runner/report semantics were tightened. |
| Test review | Added mandatory runner fixture tests and wrote test plan artifact. |
| Critical gaps | 3 identified and patched in plan: Dagger failure semantics, OPTIONS capability handling, first-class probes. |
| Open user challenges | None. |
| Taste decisions | None. |

**Phase 3 complete.** Codex: unavailable. Claude subagent: 12 issues. Consensus: 0/6 confirmed because only one outside voice was available. Passing to Phase 3.5 (DX Review).

### Phase 3.5: Developer Experience Review

Product type: developer-facing conformance test suite. Primary surfaces are Dagger commands, runner env vars, result files, Hurl/probe paths, skip manifests, and documentation.

#### DX Step 0: Scope Assessment

Initial DX completeness: 5/10 before review. The plan was technically complete but too implementer-oriented. A new contributor could follow task steps, but a server author or maintainer would not get a clear hello-world path, expected output, configuration table, or troubleshooting flow until late in the plan.

Target TTHW: under 10 minutes with Docker and Dagger already installed, under 20 minutes from a clean machine.

Developer journey map:

| Stage | Developer Goal | Plan Support After Review | Remaining Risk |
|---|---|---|---|
| Discover | Understand what this suite validates | README goal and protocol coverage audit | README final wording still must be updated in implementation. |
| Evaluate | See one command and expected result | Task 1 quickstart requirement | Dagger install itself may still be external friction. |
| Install | Know prerequisites | README prerequisites requirement | Clean-machine setup depends on Docker/Dagger docs. |
| Hello world | Run one bundled server | `dagger call run --server=TUSD --report=JUNIT export --path results/tusd-hello` | Server image pull time can dominate first run. |
| Interpret | Know raw vs unsupported vs skipped vs active | Result-file explanation required in Task 1 | Must avoid jargon-only docs. |
| Configure | Override base URL, reports, waits | Config table required in `tests/README.md` | Raw socket probes must parse `TUS_BASE_URL` consistently. |
| Debug | Fix capability/probe/server failures | Error shape and troubleshooting anchors required | Implementation must actually link errors to anchors. |
| Verify | Run full matrix and audit | Tasks 8-10 | Full matrix can be slow. |
| Maintain | Update skips and source evidence | Source revision, suggested fix, docs fields required | Upstream source line drift still needs periodic refresh. |

Developer empathy narrative:

I open the README because I want to know if my tus server follows the protocol. Today it says the suite is comprehensive and gives `dagger call run`, but it does not show what files prove success or what to do if a server does not support an extension. With the reviewed plan, I should see one hello-world command for `TUSD`, know it may take a few minutes to pull images, and then inspect `results/tusd-hello/status-tusd.txt`. If something fails, I should not need to reverse-engineer Dagger or Hurl. The output should tell me whether the server did not advertise an extension, whether a test failed because the server is source-verified non-compliant, or whether the runner could not discover capabilities. The difference matters: unsupported is fine, skipped is a known upstream behavior, and active failures need investigation.

#### DX Step 0.5: Dual Voices

CODEX SAYS (DX - developer experience challenge): unavailable, binary not found.

CLAUDE SUBAGENT (DX - independent review):

| Severity | Finding | Fix Applied To Plan |
|---|---|---|
| Critical | No zero-to-hello-world path. | Added Developer Experience Contract and Task 1 quickstart docs. |
| High | `TUS_BASE_URL` override inconsistent across runner, Hurl, and probes. | Added one base URL contract and patched runner/probe examples. |
| High | Error paths were not actionable. | Added required Problem/Cause/Fix/Docs error shape. |
| High | Dagger command surface lacked progressive disclosure. | Task 1 now requires hello-world and result-file explanation; Task 9 finalizes docs. |
| Medium | Server naming consistency was fragile. | DX checklist requires a server name mapping table. |
| Medium | Docs were planned too late. | Minimal docs moved into Task 1. |
| Medium | Expected output examples were thin. | Quickstart now requires expected result files and sample interpretation. |
| Medium | No dry-run/list path. | Added `LIST_ONLY=true` runner behavior. |
| Medium | Escape hatches were partial and undocumented. | Task 1 configuration table now required. |
| Medium | Server non-compliance notes did not include upstream fix guidance. | Added `Suggested fix` and `Docs` fields. |

DX DUAL VOICES - CONSENSUS TABLE:

| Dimension | Claude | Codex | Consensus |
|---|---|---|---|
| Getting started < 5 min? | No; target under 10 min with prerequisites. | N/A | N/A, single voice. |
| API/CLI naming guessable? | Partly; needs mapping and progressive commands. | N/A | N/A. |
| Error messages actionable? | Not before review; now required shape. | N/A | N/A. |
| Docs findable and complete? | Docs moved earlier but implementation must write them. | N/A | N/A. |
| Upgrade path safe? | N/A for this plan, but source evidence refresh matters. | N/A | N/A. |
| Dev environment friction-free? | Acceptable with Dagger/Docker installed. | N/A | N/A. |

#### DX Passes 1-8 Scorecard

| Dimension | Score | What Makes It A 10 | Plan Fix |
|---|---:|---|---|
| Getting started | 7/10 | One command, expected output tree, troubleshooting in the first README screen. | Task 1 quickstart requirement. |
| API/CLI ergonomics | 7/10 | Progressive commands for bundled matrix, one server, one extension, external server, and list-only mode. | `LIST_ONLY` and docs requirements. |
| Error quality | 8/10 | Every runner/probe error gives problem, cause, fix, docs. | Error shape contract. |
| Documentation | 7/10 | README has quickstart and result interpretation before deep catalog details. | Minimal Task 1 docs plus Task 9 final polish. |
| Configuration | 8/10 | One table for every env var and default. | Config table requirement. |
| Result interpretation | 8/10 | Raw, unsupported, skipped, active, and status files explained with examples. | Result-file explanation required. |
| Maintainability | 8/10 | Skip evidence includes source revision, suggested fix, docs link. | Non-compliance entry format updated. |
| Desirability | 6/10 | A polished public runner, badges, and CI template. | Deferred to `TODOS.md`. |

Overall DX score after review changes: 7.4/10. This is good enough for implementation. The 10/10 path is productization: standalone runner, public badges, CI templates, and hosted scorecards.

#### DX Implementation Checklist

- Add README quickstart in Task 1, not only Task 9.
- Use `TUS_BASE_URL` everywhere, including Python probes.
- Add `LIST_ONLY=true` behavior for selection preview.
- Add result artifact explanation with sample output tree.
- Add troubleshooting anchors and make runner/probe errors link to them.
- Add server name mapping table: Dagger enum, normalized result name, skip file, result directory.
- Add configuration table for runner env vars and Dagger report options.
- Add `Suggested fix` and `Docs` fields to non-compliance entries.

**Phase 3.5 complete.** DX overall: 7.4/10. TTHW: unspecified -> target under 10 minutes with prerequisites. Codex: unavailable. Claude subagent: 10 issues. Consensus: 0/6 confirmed because only one outside voice was available. Passing to Phase 4 (Final Gate).

### Cross-Phase Themes

| Theme | Phases | Signal | Plan Response |
|---|---|---|---|
| Trustworthy conformance reporting, not just more tests | CEO, Eng, DX | CEO flagged raw-vs-filtered legitimacy; Eng flagged hidden failures; DX flagged result interpretation. | Added raw, unsupported, skipped, active, and status artifacts plus README result explanations. |
| Capability gating before skip handling | CEO, Eng | CEO flagged unsupported-extension legitimacy risk; Eng found failed OPTIONS would activate every extension. | Runner now discovers capabilities, treats failed discovery as no extensions, and filters unsupported before source-verified skips. |
| Probes must be first-class tests | CEO, Eng, DX | CEO flagged silent probe no-ops; Eng found probes outside reports; DX flagged hard-coded probe base URL and weak errors. | Probes now use `TUS_BASE_URL`, selected probe paths, result-list handling, status files, and actionable error shape. |
| Developer trust depends on docs being early | CEO, DX | CEO found adoption risk; DX found no hello-world path. | Minimal quickstart, config table, result interpretation, and troubleshooting anchors moved into Task 1. |
| Evidence must stay durable | CEO, Eng | CEO flagged stale source line references; Eng flagged skip evidence drift. | Non-compliance entries now require source revision, suggested fix, and docs link. |

### Final Approval

Approved as-is at the `/autoplan` final gate. No user challenges or taste decisions remain open. Codex was unavailable, so review logs mark outside voices as `subagent-only`.

<!-- AUTONOMOUS DECISION LOG -->
## Decision Audit Trail

| # | Phase | Decision | Classification | Principle | Rationale | Rejected |
|---|---|---|---|---|---|---|
| 1 | Phase 0.5 | Proceed with Claude subagent only because Codex is unavailable. | Mechanical | P6 | The Codex binary is not installed, and the skill says to degrade rather than block. | Blocking review on Codex installation. |
| 2 | Phase 1 | Use SELECTIVE EXPANSION mode. | Mechanical | P1, P2 | The plan is directionally right, but blast-radius additions are needed to make it complete and trustworthy. | Scope reduction and full product expansion. |
| 3 | Phase 1 | Add first-class server capability gating before skip manifests. | Mechanical | P1, P5 | Unsupported extensions must be distinct from non-compliance or the skip policy becomes untrustworthy. | Treating unsupported extensions as source-verified skips. |
| 4 | Phase 1 | Separate raw, unsupported, skipped, and filtered result outputs. | Mechanical | P1, P5 | A green filtered run is useful only if raw failures and unsupported tests remain visible. | Reporting only the filtered pass/fail result. |
| 5 | Phase 1 | Require source commit SHA or immutable URL in non-compliance notes. | Mechanical | P1, P3 | File/line evidence without a revision will rot as upstream repos change. | Local clone path plus line number only. |
| 6 | Phase 1 | Move coverage audit skeleton earlier in the plan. | Mechanical | P1, P3 | The 13 findings are the input truth for this plan and should exist before implementation relies on them. | Creating the audit only after all tests are written. |
| 7 | Phase 3 | Treat failed OPTIONS or missing `Tus-Extension` as no advertised extensions. | Mechanical | P1, P5 | Running every extension on discovery failure creates false failures and bad skips. | Treating empty discovery as all extensions active. |
| 8 | Phase 3 | Make probes first-class selected tests. | Mechanical | P1, P5 | Probe paths need the same unsupported, skipped, active, and status semantics as Hurl files. | Running all probes as silent side effects. |
| 9 | Phase 3 | Add runner fixture tests before relying on the server matrix. | Mechanical | P1 | Filtering and skip ordering are new logic and need direct tests. | Only testing through full Dagger runs. |
| 10 | Phase 3 | Do not hide test failures behind `ReturnType.ANY`. | Mechanical | P1, P5 | Exported results must not imply the suite passed. | Always returning a directory regardless of status. |
| 11 | Phase 3 | Verify Hurl release SHA256 in the runner image. | Mechanical | P1 | Downloading and installing a release artifact without integrity verification is avoidable supply-chain risk. | Installing the downloaded `.deb` directly. |
| 12 | Phase 3 | Validate `TUS_SERVER_NAME` before using it in paths. | Mechanical | P1, P5 | The shell runner may be used outside Dagger and should reject path-control characters. | Trusting the environment variable. |
| 13 | Phase 3 | Use polling with grace for expiration lifecycle verification. | Mechanical | P3 | Single-shot timing checks are flaky under CI load. | One sleep followed by one HEAD. |
| 14 | Phase 3 | Read checksum trailer responses until headers are complete. | Mechanical | P5 | One socket receive can return partial headers and make the probe flaky. | Assuming `recv(4096)` is enough. |
| 15 | Phase 3 | Add status-code assertion policy for negative tests. | Mechanical | P1 | Exact status codes should be asserted only when the spec requires them. | Hard-coding `400` for every malformed request. |
| 16 | Phase 3 | Create `TODOS.md` for deferred productization scope. | Mechanical | P3 | Deferred work should be written down instead of staying in review prose. | Leaving deferred scope only in the plan review section. |
| 17 | Phase 3.5 | Move minimal README and tests README docs into Task 1. | Mechanical | P1, P5 | Developers need a hello-world path before implementing or running the new suite. | Waiting until Task 9 for all docs. |
| 18 | Phase 3.5 | Use `TUS_BASE_URL` consistently across runner, Hurl, and probes. | Mechanical | P5 | One base URL contract avoids broken custom-server and probe behavior. | Hard-coded probe host/port/path defaults. |
| 19 | Phase 3.5 | Add `LIST_ONLY=true` selection preview. | Mechanical | P3 | Developers need to debug capability and skip selection without running the whole suite. | Only writing selection files after execution. |
| 20 | Phase 3.5 | Require actionable runner/probe error format. | Mechanical | P1 | Errors should tell developers what failed, likely cause, fix, and docs link. | Short opaque error strings. |
| 21 | Phase 3.5 | Add suggested upstream fix and docs fields to non-compliance entries. | Mechanical | P1 | Server authors should be able to act on skip evidence without reverse-engineering tests. | Evidence-only server notes. |
