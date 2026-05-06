# Compliance Review Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Align the new tus compliance tests, probes, skips, and documentation with tus 1.0.0 requirements instead of over-stating SHOULD/MAY behavior as MUST failures.

**Architecture:** Keep compliance assertions strict only where tus 1.0.0 has a MUST. For SHOULD/MAY behavior, either relax Hurl status assertions or mark the case as advisory. Preserve runner classification boundaries: unsupported means not advertised, skipped means advertised but source-verified non-compliance.

**Tech Stack:** Hurl v7.1+, POSIX shell runner fixtures, Python standard-library probes, Dagger Dang runner, Markdown docs.

---

### Task 1: Add Probe URL Regression Coverage

**Files:**
- Modify: `tests/scripts/run-suite-fixture-tests.sh`
- Modify: `tests/probes/checksum_trailer.py`
- Modify: `tests/probes/expiration_lifecycle.py`

- [ ] **Step 1: Add failing fixture tests**

Add shell fixture tests that start two local HTTP servers: one for the base collection URL and one for the absolute `Location` authority. The base server returns `Location: http://127.0.0.1:<upload-port>/uploads/1`; the upload server records PATCH/HEAD requests. Run `sh tests/scripts/run-suite-fixture-tests.sh`; before implementation, the probes should send follow-up requests to the base authority and the tests should fail.

- [ ] **Step 2: Preserve absolute upload URLs in probes**

Change both probes to resolve `Location` against `TUS_BASE_URL` and carry scheme, host, port, and path into follow-up requests. `checksum_trailer.py` must open the raw socket to the resolved upload authority. `expiration_lifecycle.py` must create HTTP connections from the resolved URL for PATCH and HEAD.

- [ ] **Step 3: Verify fixture tests pass**

Run `sh tests/scripts/run-suite-fixture-tests.sh`. Expected: `run-suite fixture tests passed`.

### Task 2: Relax Over-Strict Hurl Assertions

**Files:**
- Modify: `tests/core/cp-head/cp-head-003-requires-tus-resumable.hurl`
- Modify: `tests/core/cp-patch/cp-patch-001-requires-tus-resumable.hurl`
- Modify: `tests/extensions/creation/ext-create-003-requires-tus-resumable.hurl`
- Modify: `tests/extensions/termination/ext-term-002-requires-tus-resumable.hurl`
- Modify: `tests/extensions/termination/ext-term-003-deleted-404-410.hurl`
- Modify: `tests/extensions/termination/ext-term-006-post-overrides-delete.hurl`
- Modify: `tests/extensions/concatenation/ext-concat-005-patch-final-forbidden.hurl`
- Modify: `tests/extensions/expiration/ext-expire-002-patch-response.hurl`
- Modify: `tests/extensions/expiration/ext-expire-003-format.hurl`
- Modify: `tests/extensions/creation/opt-store-003-very-large.hurl`
- Modify: `tests/extensions/checksum/ext-csum-010-malformed-missing-space.hurl`
- Modify: `tests/extensions/checksum/ext-csum-011-malformed-base64.hurl`

- [ ] **Step 1: Make missing `Tus-Resumable` status assertions reject broadly**

Use `HTTP *` plus `status toString matches /^(400|412)$/` for absent-header tests, and keep no-mutation checks where present. Do not relax unsupported-version tests because tus explicitly mandates `412` there.

- [ ] **Step 2: Downgrade SHOULD/MAY behavior**

For termination follow-up tests, assert a rejection class instead of exact `404|410`, and update comments to say `404/410` is the preferred SHOULD. For final concat, allow the partial `HEAD` to return `200|204|404|410` after final creation.

- [ ] **Step 3: Gate expiration assertions to configured lifecycle checks**

Keep creation/PATCH smoke tests focused on successful upload behavior. Move strict `Upload-Expires` validation to the Python lifecycle probe only when the server configuration has an expiration window.

- [ ] **Step 4: Strengthen weak assertions**

Restrict the very-large upload test to `201|413`. Add `HEAD` offset checks after malformed checksum requests so rejected chunks cannot advance state.

### Task 3: Correct Docs And Skip Classification

**Files:**
- Modify: `docs/server-noncompliance.md`
- Modify: `tests/skips/rustus.txt`
- Modify: `docs/protocol-coverage-audit.md`
- Modify: `tests/README.md`
- Modify: `README.md`

- [ ] **Step 1: Remove 400-vs-415 as a tus non-compliance skip reason**

Delete the two RUSTUS skip entries for malformed `Upload-Offset` if the Hurl tests no longer require exact `400`. Remove or rewrite the corresponding markdown entries so they do not claim tus requires `400`.

- [ ] **Step 2: Fix unsupported-vs-skipped wording**

Update audit rows so RUSTUS advertised extension failures are described as source-verified skips, not unsupported filtering. Keep unsupported wording only for servers that do not advertise the extension.

- [ ] **Step 3: Refresh public test catalog**

Add `CP-PATCH-011`, `CP-PATCH-012`, `CP-ERR-003`, and the newer creation extension rows to `tests/README.md`. Refresh top-level README counts by counting `*.hurl` files by prefix.

### Task 4: Verify

**Files:**
- No production edits.

- [ ] **Step 1: Run targeted fixture tests**

Run `sh tests/scripts/run-suite-fixture-tests.sh`. Expected: pass.

- [ ] **Step 2: Run static scans for stale strict claims**

Run targeted searches for stale exact-status claims and broad success ranges. Expected: no stale claims tied to fixed findings.

- [ ] **Step 3: Check worktree diff**

Run `git diff --stat` and inspect the changed files. Expected: only the planned tests/probes/docs changed.
