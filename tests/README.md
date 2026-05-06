# tus Protocol Compliance Test Suite Specification

## Overview

A comprehensive test suite for validating server implementations against the tus resumable upload protocol.

**Scope:**
- Server compliance testing (single implementation)
- Functional compliance tests (atomic + scenario-based)
- Modular extension support (manual config or auto-discovery via OPTIONS)
- Configurable authentication hooks
- Stress tests specified separately

## Protocol Reference

This test suite validates compliance with:
- **Official Protocol**: https://tus.io/protocols/resumable-upload
- **Protocol Version**: 1.0.0 (released 2016-03-25)
- **OpenAPI Spec**: https://github.com/tus/tus-resumable-upload-protocol/blob/main/OpenAPI/openapi3.yaml

### RFC 2119 Keywords

Test descriptions use RFC 2119 language:
- **MUST** / **MUST NOT**: Absolute requirements
- **SHOULD** / **SHOULD NOT**: Recommended but may be ignored with good reason
- **MAY**: Optional features

## Test Organization

Tests are organized by scope:

```
tests/
├── core/                          # Core protocol tests (required for all implementations)
│   ├── cp-err/                    # Error response tests
│   ├── cp-head/                   # HEAD request tests
│   ├── cp-opt/                    # OPTIONS request tests
│   ├── cp-patch/                  # PATCH request tests
│   └── cp-ver/                    # Version handling tests
└── extensions/                    # Extension tests (one directory per extension)
    ├── creation/                  # Creation extension (includes scenarios + optional)
    ├── creation-defer-length/     # Creation-Defer-Length extension
    ├── creation-with-upload/      # Creation-With-Upload extension
    ├── checksum/                  # Checksum extension
    ├── checksum-trailer/          # Checksum-Trailer extension
    ├── concatenation/             # Concatenation extension
    ├── concatenation-unfinished/  # Concatenation-Unfinished extension
    ├── termination/               # Termination extension
    └── expiration/                # Expiration extension
```

Each extension directory contains all tests for that extension:
- Atomic tests (ext-*): Individual protocol requirement tests
- Scenario tests (scn-*): End-to-end workflow tests
- Optional tests (opt-*): Undefined behavior and best practices

## Running Tests

### Runner Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `TUS_BASE_URL` | `http://tus:8080/files` | Base tus collection URL used for OPTIONS discovery and Hurl `base_url`. |
| `TUS_SERVER_NAME` | none | Required safe server id for report filenames and `tests/skips/<server>.txt`; allowed characters are letters, numbers, `.`, `_`, and `-`. |
| `RESULTS_DIR` | `results` | Directory where selection reports and Hurl reports are written. |
| `REPORT_HTML` | unset | Set to `true` to write Hurl HTML reports under `$RESULTS_DIR/html`. |
| `REPORT_JSON` | unset | Set to `true` to write Hurl JSON reports under `$RESULTS_DIR/json`. |
| `REPORT_JUNIT` | unset | Set to `true` to write `$RESULTS_DIR/results-junit.xml`. |
| `REPORT_TAP` | unset | Set to `true` to write `$RESULTS_DIR/report.tap`. |
| `TUS_EXPIRATION_WAIT_SECONDS` | probe-defined | Wait duration for expiration probes or tests that need server expiration windows. |
| `TUS_EXPIRATION_GRACE_SECONDS` | probe-defined | Additional grace duration for expiration timing variance. |
| `LIST_ONLY` | unset | Set to `true` to write selection reports and exit without running Hurl files or Python probes. |

Use `run` for the bundled server matrix or a selected bundled server:

```bash
# Run all bundled servers
dagger call run

# Run against a specific server
dagger call run --server=TUSD

# Export JUnit reports and runner selection files
dagger call run --server=TUSD --report=JUNIT export --path results/tusd
```

The lower-level `test` function accepts a Dagger `Service` plus optional `extension` and `disableCore` arguments for custom callers that need targeted suites.

### Compliance Levels

| Level | Requirements |
|-------|--------------|
| **Core** | All CP-* tests pass |
| **Core + Creation** | Core + all creation extension tests pass |
| **Core + [Extension]** | Core + specific extension tests pass |
| **Full** | All required tests for all advertised extensions pass |

## Core Protocol Tests

### CP-OPT: OPTIONS Request

| ID | Test Name | Type | Description |
|----|-----------|------|-------------|
| [CP-OPT-001](core/cp-opt/cp-opt-001-tus-version.hurl) | OPTIONS returns Tus-Version | Atomic | Server MUST return `Tus-Version` header with comma-separated versions |
| [CP-OPT-002](core/cp-opt/cp-opt-002-no-tus-resumable.hurl) | OPTIONS without Tus-Resumable | Atomic | Server MUST NOT require `Tus-Resumable` header on OPTIONS |
| [CP-OPT-003](core/cp-opt/cp-opt-003-version-preference.hurl) | Tus-Version preference order | Atomic | Versions MUST be ordered by server preference (most preferred first) |
| [CP-OPT-004](core/cp-opt/cp-opt-004-tus-extension.hurl) | Tus-Extension header present | Atomic | If extensions supported, `Tus-Extension` header MUST list them |
| [CP-OPT-005](core/cp-opt/cp-opt-005-tus-max-size.hurl) | Tus-Max-Size header format | Atomic | If present, `Tus-Max-Size` MUST be a non-negative integer |
| [CP-OPT-006](core/cp-opt/cp-opt-006-ignore-tus-resumable.hurl) | OPTIONS ignores Tus-Resumable | Atomic | Server MUST ignore `Tus-Resumable` on OPTIONS |

### CP-HEAD: HEAD Request

| ID | Test Name | Type | Description |
|----|-----------|------|-------------|
| [CP-HEAD-001](core/cp-head/cp-head-001-upload-offset.hurl) | HEAD returns Upload-Offset | Atomic | Response MUST include `Upload-Offset` header |
| [CP-HEAD-002](core/cp-head/cp-head-002-upload-length.hurl) | HEAD returns Upload-Length | Atomic | Response MUST include `Upload-Length` if known |
| [CP-HEAD-003](core/cp-head/cp-head-003-requires-tus-resumable.hurl) | HEAD requires Tus-Resumable | Atomic | Request without `Tus-Resumable` MUST be rejected |
| [CP-HEAD-004](core/cp-head/cp-head-004-cache-control.hurl) | HEAD Cache-Control header | Atomic | Response MUST include `Cache-Control: no-store` |
| [CP-HEAD-005](core/cp-head/cp-head-005-non-existent.hurl) | HEAD on non-existent resource | Atomic | SHOULD return 403, 404, or 410 without `Upload-Offset` |
| [CP-HEAD-006](core/cp-head/cp-head-006-tus-resumable.hurl) | HEAD returns Tus-Resumable | Atomic | Response MUST include `Tus-Resumable` header |
| [CP-HEAD-007](core/cp-head/cp-head-007-offset-zero.hurl) | HEAD offset zero for new upload | Atomic | New upload MUST report `Upload-Offset: 0` |

### CP-PATCH: PATCH Request

| ID | Test Name | Type | Description |
|----|-----------|------|-------------|
| [CP-PATCH-001](core/cp-patch/cp-patch-001-requires-tus-resumable.hurl) | PATCH requires Tus-Resumable | Atomic | Request without `Tus-Resumable` MUST be rejected without mutating offset |
| [CP-PATCH-002](core/cp-patch/cp-patch-002-requires-content-type.hurl) | PATCH requires Content-Type | Atomic | Missing `Content-Type` SHOULD be rejected without mutating offset |
| [CP-PATCH-003](core/cp-patch/cp-patch-003-wrong-content-type.hurl) | PATCH wrong Content-Type | Atomic | Wrong `Content-Type` SHOULD be rejected without mutating offset |
| [CP-PATCH-004](core/cp-patch/cp-patch-004-requires-upload-offset.hurl) | PATCH requires Upload-Offset | Atomic | Missing `Upload-Offset` header MUST be rejected |
| [CP-PATCH-005](core/cp-patch/cp-patch-005-offset-mismatch.hurl) | PATCH offset mismatch | Atomic | Mismatched offset MUST return 409 Conflict |
| [CP-PATCH-006](core/cp-patch/cp-patch-006-success-204.hurl) | PATCH success returns 204 | Atomic | Successful PATCH MUST return 204 No Content |
| [CP-PATCH-007](core/cp-patch/cp-patch-007-returns-upload-offset.hurl) | PATCH returns Upload-Offset | Atomic | Response MUST include updated `Upload-Offset` |
| [CP-PATCH-008](core/cp-patch/cp-patch-008-non-existent.hurl) | PATCH on non-existent resource | Atomic | SHOULD return 404 Not Found |
| [CP-PATCH-009](core/cp-patch/cp-patch-009-returns-tus-resumable.hurl) | PATCH returns Tus-Resumable | Atomic | Response MUST include `Tus-Resumable` header |
| [CP-PATCH-010](core/cp-patch/cp-patch-010-beyond-upload-length.hurl) | PATCH beyond Upload-Length | Atomic | Sending more bytes than declared MUST be rejected |
| [CP-PATCH-011](core/cp-patch/cp-patch-011-upload-offset-negative.hurl) | Upload-Offset rejects negative value | Atomic | Negative `Upload-Offset` MUST be rejected without mutating offset |
| [CP-PATCH-012](core/cp-patch/cp-patch-012-upload-offset-non-integer.hurl) | Upload-Offset rejects non-integer value | Atomic | Non-integer `Upload-Offset` MUST be rejected without mutating offset |

### CP-VER: Version Handling

| ID | Test Name | Type | Description |
|----|-----------|------|-------------|
| [CP-VER-001](core/cp-ver/cp-ver-001-unsupported-version.hurl) | Unsupported version rejected | Atomic | Unknown `Tus-Resumable` version MUST return 412 |
| [CP-VER-002](core/cp-ver/cp-ver-002-412-includes-tus-version.hurl) | 412 includes Tus-Version | Atomic | 412 response MUST include `Tus-Version` header with supported versions |
| [CP-VER-003](core/cp-ver/cp-ver-003-version-1.0.0.hurl) | Version 1.0.0 supported | Atomic | Server MUST support version 1.0.0 |
| [CP-VER-004](core/cp-ver/cp-ver-004-unsupported-post-no-location.hurl) | Unsupported POST version not processed | Atomic | Unsupported version MUST return 412 and not create an upload |
| [CP-VER-005](core/cp-ver/cp-ver-005-unsupported-patch-no-mutation.hurl) | Unsupported PATCH version no mutation | Atomic | Unsupported version MUST return 412 and not advance offset |

### CP-ERR: Error Response Handling

| ID | Test Name | Type | Description |
|----|-----------|------|-------------|
| [CP-ERR-001](core/cp-err/cp-err-001-response-format.hurl) | Error response format | Atomic | Error responses SHOULD include descriptive body |
| [CP-ERR-002](core/cp-err/cp-err-002-validation-errors.hurl) | Validation error details | Atomic | Validation errors SHOULD indicate which field/header failed |
| [CP-ERR-003](core/cp-err/cp-err-003-upload-length-non-integer.hurl) | Upload-Length rejects non-integer value | Atomic | Non-integer `Upload-Length` MUST be rejected without creating an upload |

## Extension Test Modules

### Creation Extension

**Prerequisite:** Server advertises `creation` in `Tus-Extension`

#### Atomic Tests

| ID | Test Name | Type | Description |
|----|-----------|------|-------------|
| [EXT-CREATE-001](extensions/creation/ext-create-001-post-creates.hurl) | POST creates upload | Atomic | POST with `Upload-Length` MUST return 201 Created |
| [EXT-CREATE-002](extensions/creation/ext-create-002-returns-location.hurl) | POST returns Location | Atomic | 201 response MUST include `Location` header with upload URL |
| [EXT-CREATE-003](extensions/creation/ext-create-003-requires-tus-resumable.hurl) | POST requires Tus-Resumable | Atomic | POST without `Tus-Resumable` MUST be rejected without creating an upload |
| [EXT-CREATE-004](extensions/creation/ext-create-004-upload-metadata.hurl) | POST with Upload-Metadata | Atomic | Server MUST accept valid `Upload-Metadata` header |
| [EXT-CREATE-005](extensions/creation/ext-create-005-metadata-key-format.hurl) | POST metadata key format | Atomic | Metadata keys MUST be ASCII, non-empty, unique |
| [EXT-CREATE-006](extensions/creation/ext-create-006-metadata-base64.hurl) | POST metadata value base64 | Atomic | Metadata values MUST be base64-encoded |
| [EXT-CREATE-007](extensions/creation/ext-create-007-exceeds-max-size.hurl) | POST exceeds Tus-Max-Size | Atomic | `Upload-Length` > `Tus-Max-Size` MUST return 413 |
| [EXT-CREATE-008](extensions/creation/ext-create-008-zero-length.hurl) | POST zero-length upload | Atomic | `Upload-Length: 0` MUST be accepted (empty file) |
| [EXT-CREATE-009](extensions/creation/ext-create-009-location-absolute.hurl) | Location URL is resolvable | Atomic | `Location` header MUST be a resolvable URL (absolute or relative) |
| [EXT-CREATE-010](extensions/creation/ext-create-010-metadata-head.hurl) | HEAD echoes Upload-Metadata | Atomic | HEAD response MUST include stored `Upload-Metadata` |
| [EXT-CREATE-011](extensions/creation/ext-create-011-returns-tus-resumable.hurl) | POST returns Tus-Resumable | Atomic | Creation response MUST include `Tus-Resumable` |
| [EXT-CREATE-012](extensions/creation/ext-create-012-requires-length-or-defer.hurl) | POST requires length or defer | Atomic | Creation request MUST include `Upload-Length` or `Upload-Defer-Length` |
| [EXT-CREATE-013](extensions/creation/ext-create-013-metadata-exact-head.hurl) | HEAD echoes metadata exactly | Atomic | HEAD response MUST include metadata value supplied during creation |
| [EXT-CREATE-014](extensions/creation/ext-create-014-metadata-empty-key-rejected.hurl) | Empty metadata key sentinel | Atomic | Empty metadata keys are invalid; servers may reject or ignore supplied metadata |
| [EXT-CREATE-015](extensions/creation/ext-create-015-metadata-comma-key-rejected.hurl) | Comma metadata key sentinel | Atomic | Metadata keys MUST NOT contain commas; parse-ambiguous input is tracked as a sentinel |

#### Scenario Tests

| ID | Test Name | Description |
|----|-----------|-------------|
| [SCN-BASIC-001](extensions/creation/scn-basic-001-complete-small.hurl) | Complete small upload | Create upload, send all bytes in single PATCH, verify completion |
| [SCN-BASIC-002](extensions/creation/scn-basic-002-chunked-upload.hurl) | Complete chunked upload | Create upload, send bytes across multiple PATCH requests |
| [SCN-BASIC-003](extensions/creation/scn-basic-003-resume-interrupted.hurl) | Resume interrupted upload | Create, partial PATCH, HEAD to get offset, resume with second PATCH |
| [SCN-BASIC-004](extensions/creation/scn-basic-004-zero-byte.hurl) | Zero-byte upload | Create upload with `Upload-Length: 0`, verify immediate completion |
| [SCN-RESUME-001](extensions/creation/scn-resume-001-from-zero.hurl) | Resume from zero | Create upload, never PATCH, HEAD returns offset 0, complete upload |
| [SCN-RESUME-002](extensions/creation/scn-resume-002-from-middle.hurl) | Resume from middle | Upload 50%, simulate disconnect, HEAD, resume from reported offset |
| [SCN-RESUME-003](extensions/creation/scn-resume-003-near-completion.hurl) | Resume near completion | Upload 99%, disconnect, resume final bytes |
| [SCN-RESUME-004](extensions/creation/scn-resume-004-multiple-cycles.hurl) | Multiple resume cycles | Create, upload 25%, resume to 50%, resume to 75%, complete |
| [SCN-ERROR-001](extensions/creation/scn-error-001-offset-mismatch.hurl) | Recover from offset mismatch | Attempt PATCH with wrong offset, get 409, HEAD to correct, retry |

#### Optional Tests

| ID | Test Name | Spec Gap | Suggested Best Practice |
|----|-----------|----------|------------------------|
| [OPT-META-001](extensions/creation/opt-meta-001-invalid-base64.hurl) | Invalid base64 in metadata value | Spec doesn't define error response | Return 400 Bad Request with descriptive error |
| [OPT-META-002](extensions/creation/opt-meta-002-duplicate-keys.hurl) | Duplicate metadata keys | "Keys MUST be unique" but no error specified | Return 400 Bad Request |
| [OPT-META-003](extensions/creation/opt-meta-003-empty-value.hurl) | Empty metadata value | Spec allows empty values but unclear | Accept empty base64-encoded values |
| [OPT-META-004](extensions/creation/opt-meta-004-size-limits.hurl) | Metadata size limits | No maximum metadata size specified | Document limits; return 413 if exceeded |
| [OPT-META-005](extensions/creation/opt-meta-005-non-ascii-keys.hurl) | Non-ASCII metadata keys | Spec says "ASCII" but no error specified | Return 400 Bad Request for non-ASCII keys |
| [OPT-META-006](extensions/creation/opt-meta-006-retrieval.hurl) | Metadata retrieval | Spec doesn't require returning metadata on HEAD | Return `Upload-Metadata` on HEAD for debugging |
| [OPT-URL-001](extensions/creation/opt-url-001-relative-location.hurl) | Relative Location header | Spec doesn't mandate absolute URLs | Always return absolute URLs for client compatibility |
| [OPT-URL-002](extensions/creation/opt-url-002-url-format.hurl) | URL format and structure | "Left for implementation to decide" | Use opaque, non-guessable identifiers |
| [OPT-URL-003](extensions/creation/opt-url-003-cross-origin.hurl) | Cross-origin Location | No CORS requirements specified | Support CORS headers if serving web clients |
| [OPT-PARTIAL-001](extensions/creation/opt-partial-001-accepts-partial.hurl) | Server accepts partial PATCH | Spec says "store maximum" but behavior unclear | Accept partial data, update offset to bytes received |
| [OPT-PARTIAL-002](extensions/creation/opt-partial-002-response-code.hurl) | Partial write response code | Should partial acceptance be 204 or different? | Return 204 with accurate `Upload-Offset` |
| [OPT-PARTIAL-003](extensions/creation/opt-partial-003-client-notification.hurl) | Client notification of partial | How to signal incomplete write? | `Upload-Offset` in response reflects actual bytes stored |
| [OPT-CONC-001](extensions/creation/opt-conc-001-concurrent-patch.hurl) | Concurrent PATCH requests | No concurrency requirements specified | Serialize writes; second request gets 409 or waits |
| [OPT-CONC-002](extensions/creation/opt-conc-002-head-during-patch.hurl) | Concurrent HEAD during PATCH | Can HEAD be served during active write? | Return last committed offset |
| [OPT-CONC-003](extensions/creation/opt-conc-003-concurrent-creation.hurl) | Concurrent upload creation | Same file uploaded twice simultaneously | Each gets unique upload URL |
| [OPT-COMP-001](extensions/creation/opt-comp-001-patch-completed.hurl) | PATCH on completed upload | Spec doesn't define behavior | Return 400 or 409; indicate upload is complete |
| [OPT-COMP-002](extensions/creation/opt-comp-002-head-completed.hurl) | HEAD on completed upload | Spec doesn't distinguish complete vs incomplete | Return `Upload-Offset` == `Upload-Length` |
| [OPT-COMP-003](extensions/creation/opt-comp-003-notification.hurl) | Upload completion notification | No callback/webhook mechanism | Optionally support `Upload-Complete` header or webhook |
| [OPT-ERR-002](extensions/creation/opt-err-002-409-includes-offset.hurl) | 409 Conflict includes current offset | Spec doesn't require it | Include `Upload-Offset` header in 409 response |
| [OPT-TIME-001](extensions/creation/opt-time-001-idle-timeout.hurl) | Idle connection timeout | No timeout requirements | Document timeouts; minimum 30 seconds recommended |
| [OPT-TIME-002](extensions/creation/opt-time-002-slow-client.hurl) | Slow client handling | No minimum transfer rate specified | Allow configurable minimum rate or timeout |
| [OPT-TIME-003](extensions/creation/opt-time-003-timeout-during-write.hurl) | Timeout during write | What happens to partial data? | Store received bytes; client can resume |
| [OPT-STORE-001](extensions/creation/opt-store-001-storage-full.hurl) | Storage full during upload | No specific error code | Return 507 Insufficient Storage or 413 |
| [OPT-STORE-002](extensions/creation/opt-store-002-length-change.hurl) | Upload-Length change attempt | Only "immutable once set" mentioned | Return 400 with clear error message |
| [OPT-STORE-003](extensions/creation/opt-store-003-very-large.hurl) | Very large Upload-Length | No maximum file size requirement beyond Tus-Max-Size | Validate against Tus-Max-Size; return 413 |

### Creation-Defer-Length Extension

**Prerequisite:** Server advertises `creation-defer-length` in `Tus-Extension`

| ID | Test Name | Type | Description |
|----|-----------|------|-------------|
| [EXT-DEFER-001](extensions/creation-defer-length/ext-defer-001-upload-defer-length.hurl) | POST with Upload-Defer-Length | Atomic | POST with `Upload-Defer-Length: 1` MUST succeed without `Upload-Length` |
| [EXT-DEFER-002](extensions/creation-defer-length/ext-defer-002-head-before-length.hurl) | HEAD before length known | Atomic | HEAD on deferred upload MUST NOT include `Upload-Length` |
| [EXT-DEFER-003](extensions/creation-defer-length/ext-defer-003-patch-sets-length.hurl) | PATCH sets Upload-Length | Atomic | First PATCH MAY include `Upload-Length` to set final size |
| [EXT-DEFER-004](extensions/creation-defer-length/ext-defer-004-length-immutable.hurl) | Upload-Length immutable | Atomic | Once `Upload-Length` set, subsequent changes MUST be rejected |
| [EXT-DEFER-005](extensions/creation-defer-length/ext-defer-005-mutual-exclusion.hurl) | Defer and Length mutual exclusion | Atomic | POST with both `Upload-Defer-Length` and `Upload-Length` MUST be rejected |
| [EXT-DEFER-006](extensions/creation-defer-length/ext-defer-006-invalid-value-zero.hurl) | Upload-Defer-Length rejects 0 | Atomic | Values other than `1` should be rejected |
| [EXT-DEFER-007](extensions/creation-defer-length/ext-defer-007-invalid-value-token.hurl) | Upload-Defer-Length rejects token | Atomic | Non-`1` token values should be rejected |

### Creation-With-Upload Extension

**Prerequisite:** Server advertises `creation-with-upload` in `Tus-Extension`

| ID | Test Name | Type | Description |
|----|-----------|------|-------------|
| [EXT-CWU-001](extensions/creation-with-upload/ext-cwu-001-post-with-body.hurl) | POST with body | Atomic | POST with request body MUST accept initial bytes |
| [EXT-CWU-002](extensions/creation-with-upload/ext-cwu-002-post-content-type.hurl) | POST body Content-Type | Atomic | POST with body MUST use `Content-Type: application/offset+octet-stream` |
| [EXT-CWU-003](extensions/creation-with-upload/ext-cwu-003-response-upload-offset.hurl) | Response includes Upload-Offset | Atomic | 201 response MUST include `Upload-Offset` with accepted byte count |
| [EXT-CWU-004](extensions/creation-with-upload/ext-cwu-004-partial-acceptance.hurl) | Partial body acceptance | Atomic | Server MAY accept fewer bytes than sent; offset indicates actual |
| [EXT-CWU-005](extensions/creation-with-upload/ext-cwu-005-complete-in-post.hurl) | Complete upload in POST | Atomic | If body size equals `Upload-Length`, upload is complete |

### Checksum Extension

**Prerequisite:** Server advertises `checksum` in `Tus-Extension`

#### Atomic Tests

| ID | Test Name | Type | Description |
|----|-----------|------|-------------|
| [EXT-CSUM-001](extensions/checksum/ext-csum-001-algorithm-header.hurl) | Tus-Checksum-Algorithm header | Atomic | OPTIONS MUST include `Tus-Checksum-Algorithm` with supported algorithms |
| [EXT-CSUM-002](extensions/checksum/ext-csum-002-sha1-support.hurl) | SHA1 algorithm support | Atomic | Server MUST support `sha1` algorithm at minimum |
| [EXT-CSUM-003](extensions/checksum/ext-csum-003-valid-checksum.hurl) | Valid checksum accepted | Atomic | PATCH with correct `Upload-Checksum` MUST succeed |
| [EXT-CSUM-004](extensions/checksum/ext-csum-004-mismatch-460.hurl) | Checksum mismatch returns 460 | Atomic | Incorrect checksum MUST return 460 Checksum Mismatch |
| [EXT-CSUM-005](extensions/checksum/ext-csum-005-no-offset-update.hurl) | Checksum failure no offset update | Atomic | Failed checksum MUST NOT update `Upload-Offset` |
| [EXT-CSUM-006](extensions/checksum/ext-csum-006-unknown-algorithm.hurl) | Unknown algorithm returns 400 | Atomic | Unsupported algorithm MUST return 400 Bad Request |
| [EXT-CSUM-007](extensions/checksum/ext-csum-007-format-validation.hurl) | Checksum format validation | Atomic | Format MUST be `algorithm base64-hash` (space-separated) |
| [EXT-CSUM-008](extensions/checksum/ext-csum-008-retry-after-failure.hurl) | Retry after checksum failure | Atomic | Client can retry same chunk after 460 response |
| [EXT-CSUM-009](extensions/checksum/ext-csum-009-error-returns-tus-resumable.hurl) | Checksum error returns Tus-Resumable | Atomic | Error response MUST include `Tus-Resumable` |
| [EXT-CSUM-010](extensions/checksum/ext-csum-010-malformed-missing-space.hurl) | Malformed checksum missing separator | Atomic | Malformed checksum tuple MUST be rejected without advancing offset |
| [EXT-CSUM-011](extensions/checksum/ext-csum-011-malformed-base64.hurl) | Malformed checksum base64 | Atomic | Malformed checksum value MUST be rejected without advancing offset |
| [EXT-CSUM-012](extensions/checksum/ext-csum-012-unknown-algorithm-no-offset-update.hurl) | Unknown checksum algorithm no offset update | Atomic | Unsupported algorithm MUST NOT advance offset |

#### Scenario Tests

| ID | Test Name | Description |
|----|-----------|-------------|
| [SCN-ERROR-002](extensions/checksum/scn-error-002-checksum-failure.hurl) | Recover from checksum failure | Send bad checksum, get 460, retry with correct checksum |

#### Optional Tests

| ID | Test Name | Spec Gap | Suggested Best Practice |
|----|-----------|----------|------------------------|
| [OPT-CSUM-001](extensions/checksum/opt-csum-001-empty-chunk.hurl) | Checksum on empty chunk | Spec doesn't address empty body with checksum | Accept; validate checksum of empty data |
| [OPT-CSUM-002](extensions/checksum/opt-csum-002-multiple-checksums.hurl) | Multiple checksums | Can client send multiple algorithms? | Accept first valid; ignore others |
| [OPT-CSUM-003](extensions/checksum/opt-csum-003-creation-with-upload.hurl) | Checksum on creation-with-upload | Checksum for POST body? | Support `Upload-Checksum` on POST with body |

### Checksum-Trailer Extension

**Prerequisite:** Server advertises `checksum-trailer` in `Tus-Extension`

| ID | Test Name | Type | Description |
|----|-----------|------|-------------|
| [EXT-CSUM-TR-001](extensions/checksum-trailer/ext-csum-tr-001-checksum-trailer.hurl) | Checksum as trailer | Atomic | Server MUST accept `Upload-Checksum` as HTTP trailer |
| [EXT-CSUM-TR-002](extensions/checksum-trailer/ext-csum-tr-002-chunked-encoding.hurl) | Trailer requires chunked encoding | Atomic | Trailer usage requires `Transfer-Encoding: chunked` |

### Termination Extension

**Prerequisite:** Server advertises `termination` in `Tus-Extension`

| ID | Test Name | Type | Description |
|----|-----------|------|-------------|
| [EXT-TERM-001](extensions/termination/ext-term-001-delete-204.hurl) | DELETE returns 204 | Atomic | Successful DELETE MUST return 204 No Content |
| [EXT-TERM-002](extensions/termination/ext-term-002-requires-tus-resumable.hurl) | DELETE requires Tus-Resumable | Atomic | DELETE without `Tus-Resumable` MUST be rejected without deleting the upload |
| [EXT-TERM-003](extensions/termination/ext-term-003-deleted-404-410.hurl) | Deleted resource remains unavailable | Atomic | Subsequent HEAD/PATCH SHOULD return 404 or 410 and must reject access |
| [EXT-TERM-004](extensions/termination/ext-term-004-non-existent.hurl) | DELETE non-existent resource | Atomic | DELETE on missing resource SHOULD return 404 |
| [EXT-TERM-005](extensions/termination/ext-term-005-completed-upload.hurl) | DELETE completed upload | Atomic | DELETE on completed upload SHOULD succeed |
| [EXT-TERM-006](extensions/termination/ext-term-006-post-overrides-delete.hurl) | POST overrides DELETE | Atomic | `X-HTTP-Method-Override: DELETE` MUST be honored |
| [EXT-TERM-007](extensions/termination/ext-term-007-returns-tus-resumable.hurl) | DELETE returns Tus-Resumable | Atomic | Successful DELETE response MUST include `Tus-Resumable` |

### Concatenation Extension

**Prerequisite:** Server advertises `concatenation` in `Tus-Extension`

#### Atomic Tests

| ID | Test Name | Type | Description |
|----|-----------|------|-------------|
| [EXT-CONCAT-001](extensions/concatenation/ext-concat-001-create-partial.hurl) | Create partial upload | Atomic | POST with `Upload-Concat: partial` MUST succeed |
| [EXT-CONCAT-002](extensions/concatenation/ext-concat-002-create-final.hurl) | Create final upload | Atomic | POST with `Upload-Concat: final;url1 url2` MUST succeed |
| [EXT-CONCAT-003](extensions/concatenation/ext-concat-003-final-no-length.hurl) | Final no Upload-Length | Atomic | Final upload creation MUST NOT include `Upload-Length` |
| [EXT-CONCAT-004](extensions/concatenation/ext-concat-004-final-offset-sum.hurl) | Final offset is sum of partials | Atomic | Final upload `Upload-Offset` MUST equal sum of partial sizes |
| [EXT-CONCAT-005](extensions/concatenation/ext-concat-005-patch-final-forbidden.hurl) | PATCH on final forbidden | Atomic | PATCH on final upload MUST return 403 Forbidden |
| [EXT-CONCAT-006](extensions/concatenation/ext-concat-006-head-concat-info.hurl) | HEAD on final returns concat info | Atomic | HEAD on final MUST include `Upload-Concat` header |
| [EXT-CONCAT-007](extensions/concatenation/ext-concat-007-partials-complete.hurl) | Partial uploads must be complete | Atomic | Final creation with incomplete partials MUST fail (unless `concatenation-unfinished`) |
| [EXT-CONCAT-008](extensions/concatenation/ext-concat-008-invalid-partial-url.hurl) | Invalid partial URL rejected | Atomic | Non-existent partial URL in final MUST be rejected |
| [EXT-CONCAT-009](extensions/concatenation/ext-concat-009-partial-head-concat.hurl) | HEAD on partial returns Upload-Concat | Atomic | HEAD on a partial upload MUST include `Upload-Concat: partial` |
| [EXT-CONCAT-010](extensions/concatenation/ext-concat-010-final-head-before-after.hurl) | HEAD on final after concatenation | Atomic | After concatenation, `Upload-Offset` and `Upload-Length` MUST be equal |
| [EXT-CONCAT-011](extensions/concatenation/ext-concat-011-final-head-exact-concat.hurl) | Final HEAD preserves Upload-Concat | Atomic | Final HEAD MUST include the final `Upload-Concat` value |
| [EXT-CONCAT-012](extensions/concatenation/ext-concat-012-final-does-not-inherit-partial-metadata.hurl) | Final metadata not inherited | Atomic | Final uploads SHALL NOT inherit partial upload metadata |

#### Scenario Tests

| ID | Test Name | Description |
|----|-----------|-------------|
| [SCN-CONCAT-001](extensions/concatenation/scn-concat-001-parallel-assembly.hurl) | Parallel upload assembly | Create 3 partials, upload in parallel, create final, verify size |
| [SCN-CONCAT-002](extensions/concatenation/scn-concat-002-sequential-partial.hurl) | Sequential partial upload | Create and complete partials sequentially, then concatenate |

### Concatenation-Unfinished Extension

**Prerequisite:** Server advertises `concatenation-unfinished` in `Tus-Extension`

| ID | Test Name | Type | Description |
|----|-----------|------|-------------|
| [EXT-CONCAT-UF-001](extensions/concatenation-unfinished/ext-concat-uf-001-incomplete-partials.hurl) | Final with incomplete partials | Atomic | Server MUST accept final creation while partials in progress |
| [EXT-CONCAT-UF-002](extensions/concatenation-unfinished/ext-concat-uf-002-offset-updates.hurl) | Final offset updates | Atomic | Final `Upload-Offset` MUST update as partials complete |

### Expiration Extension

**Prerequisite:** Server advertises `expiration` in `Tus-Extension`

#### Atomic Tests

| ID | Test Name | Type | Description |
|----|-----------|------|-------------|
| [EXT-EXPIRE-001](extensions/expiration/ext-expire-001-post-response.hurl) | Upload-Expires in POST response | Atomic | Creation response SHOULD include `Upload-Expires` header |
| [EXT-EXPIRE-002](extensions/expiration/ext-expire-002-patch-response.hurl) | Upload-Expires in PATCH response | Atomic | PATCH response MUST include `Upload-Expires` only for uploads that are going to expire |
| [EXT-EXPIRE-003](extensions/expiration/ext-expire-003-format.hurl) | Upload-Expires format | Atomic | `Upload-Expires` MUST use RFC 9110 datetime format when present |
| [EXT-EXPIRE-004](extensions/expiration/ext-expire-004-expired-404-410.hurl) | Expired upload returns 404/410 | Atomic | Access after expiration SHOULD return 404 or 410 |
| [EXT-EXPIRE-005](extensions/expiration/ext-expire-005-410-tracked.hurl) | 410 for tracked expirations | Atomic | If server tracks expired uploads, SHOULD return 410 Gone |

#### Scenario Tests

| ID | Test Name | Description |
|----|-----------|-------------|
| [SCN-ERROR-003](extensions/expiration/scn-error-003-expired-upload.hurl) | Handle expired upload | Attempt resume on expired upload, get 404/410, create new upload |

#### Optional Tests

| ID | Test Name | Spec Gap | Suggested Best Practice |
|----|-----------|----------|------------------------|
| [OPT-EXP-001](extensions/expiration/opt-exp-001-extension-on-activity.hurl) | Expiration extension on active upload | Does activity extend expiration? | Extend expiration on each successful PATCH |
| [OPT-EXP-002](extensions/expiration/opt-exp-002-completed-expiration.hurl) | Completed upload expiration | Do completed uploads expire? | Different retention for complete vs incomplete |
| [OPT-EXP-003](extensions/expiration/opt-exp-003-precision.hurl) | Expiration precision | Minimum granularity not specified | Second-level precision minimum |
