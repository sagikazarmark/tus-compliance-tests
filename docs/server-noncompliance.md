# Server Noncompliance Registry

This registry is the only allowed source for server-specific skips in `tests/skips/<server>.txt`.

## Verification Rules

- A skip is allowed only after source verification against the server implementation, not from a failing test result alone.
- Each skip entry must name the exact relative `.hurl` or probe path skipped by the runner.
- Each skip entry must identify the server, protocol clause, observed behavior, source location or upstream issue, and reason the behavior is server noncompliance rather than test-suite looseness.
- Unsupported extension tests are not skips. They are filtered from active execution when `Tus-Extension` does not advertise the extension.
- Optional or ambiguous behavior should not be skipped unless the test path is intentionally classified as required compliance for this suite and the server source proves noncompliance.
- A skip must be removed when the server fixes the behavior or the test suite changes the asserted protocol interpretation.
- Probe skips follow the same policy as Hurl skips and must include the probe path exactly.

## Entries

## tusd: unsupported POST 412 omits Tus-Version

Test: `tests/core/cp-ver/cp-ver-004-unsupported-post-no-location.hurl`
Observed: `dagger call run --server=TUSD --report=JUNIT export --path results/tusd-core-method-version-2` failed because the `412 Precondition Failed` response omitted `Tus-Version`; isolated Hurl verification showed `Tus-Resumable: 1.0.0` and no `Location` header.
Spec: tus 1.0.0 requires a `412 Precondition Failed` response for unsupported protocol versions and requires the response to include `Tus-Version`.
Source evidence: `/tmp/opencode/tus-source-audit/tusd/pkg/handler/unrouted_handler.go:229`-`231` sets `Tus-Resumable` on tus v1 responses, `unrouted_handler.go:252` sets `Tus-Version` only for `OPTIONS`, and `unrouted_handler.go:271`-`272` rejects unsupported `Tus-Resumable` with `ErrUnsupportedVersion` without adding `Tus-Version`.
Source revision: `1215a10c30218b42ace3eed6db952928472d9545` from `tusproject/tusd:latest` (`tusd -version` reports v2.9.2).
Suggested fix: TUSD should add `Tus-Version: 1.0.0` to unsupported-version `412` responses.
Docs: `tests/core/cp-ver/cp-ver-004-unsupported-post-no-location.hurl`
Decision: skipped for `tusd` in `tests/skips/tusd.txt` until upstream behavior changes.

## tusd: unsupported PATCH 412 omits Tus-Version

Test: `tests/core/cp-ver/cp-ver-005-unsupported-patch-no-mutation.hurl`
Observed: `dagger call run --server=TUSD --report=JUNIT export --path results/tusd-core-method-version-2` failed because the unsupported-version `PATCH` response omitted `Tus-Version`.
Spec: tus 1.0.0 requires a `412 Precondition Failed` response for unsupported protocol versions and requires the response to include `Tus-Version`.
Source evidence: `/tmp/opencode/tus-source-audit/tusd/pkg/handler/unrouted_handler.go:229`-`231` sets `Tus-Resumable` on tus v1 responses, `unrouted_handler.go:252` sets `Tus-Version` only for `OPTIONS`, and `unrouted_handler.go:271`-`272` rejects unsupported `Tus-Resumable` with `ErrUnsupportedVersion` without adding `Tus-Version`.
Source revision: `1215a10c30218b42ace3eed6db952928472d9545` from `tusproject/tusd:latest` (`tusd -version` reports v2.9.2).
Suggested fix: TUSD should add `Tus-Version: 1.0.0` to unsupported-version `412` responses.
Docs: `tests/core/cp-ver/cp-ver-005-unsupported-patch-no-mutation.hurl`
Decision: skipped for `tusd` in `tests/skips/tusd.txt` until upstream behavior changes.

## tusd: missing HEAD Tus-Resumable is accepted

Test: `tests/core/cp-head/cp-head-003-requires-tus-resumable.hurl`
Observed: `dagger call run --server=TUSD --report=JUNIT export --path results/tusd-header-grammar` failed because `HEAD` without `Tus-Resumable` returned `200 OK` instead of rejecting the request.
Spec: tus 1.0.0 requires `Tus-Resumable` to be included in every non-`OPTIONS` request and response.
Source evidence: `/tmp/opencode/tus-source-audit/tusd/pkg/handler/unrouted_handler.go:268`-`272` excludes `HEAD` from tus version validation, and `unrouted_handler.go:668`-`705` returns normal `HEAD` metadata with `200 OK`.
Source revision: `1215a10c30218b42ace3eed6db952928472d9545` from `tusproject/tusd:latest` (`tusd -version` reports v2.9.2).
Suggested fix: TUSD should reject missing or invalid `Tus-Resumable` on tus `HEAD` requests while preserving browser `GET` handling if needed.
Docs: `tests/core/cp-head/cp-head-003-requires-tus-resumable.hurl`
Decision: skipped for `tusd` in `tests/skips/tusd.txt` until upstream behavior changes.

## tusd: unsupported HEAD version is accepted

Tests: `tests/core/cp-ver/cp-ver-001-unsupported-version.hurl`, `tests/core/cp-ver/cp-ver-002-412-includes-tus-version.hurl`
Observed: `dagger call run --server=TUSD --report=JUNIT export --path results/tusd-header-grammar` failed because `HEAD` with unsupported `Tus-Resumable` values returned `200 OK` instead of `412 Precondition Failed` with `Tus-Version`.
Spec: tus 1.0.0 requires unsupported client protocol versions to be rejected with `412 Precondition Failed`, include `Tus-Version`, and not process the request.
Source evidence: `/tmp/opencode/tus-source-audit/tusd/pkg/handler/unrouted_handler.go:268`-`272` skips unsupported-version validation for `HEAD`, and `unrouted_handler.go:252` sets `Tus-Version` only for `OPTIONS` responses.
Source revision: `1215a10c30218b42ace3eed6db952928472d9545` from `tusproject/tusd:latest` (`tusd -version` reports v2.9.2).
Suggested fix: TUSD should apply unsupported-version rejection to tus `HEAD` requests and include `Tus-Version` on the `412` response.
Docs: `tests/core/cp-ver/cp-ver-001-unsupported-version.hurl`, `tests/core/cp-ver/cp-ver-002-412-includes-tus-version.hurl`
Decision: skipped for `tusd` in `tests/skips/tusd.txt` until upstream behavior changes.

## tusd: final concat Upload-Length is accepted

Test: `tests/extensions/concatenation/ext-concat-003-final-no-length.hurl`
Observed: `dagger call run --server=TUSD --report=JUNIT export --path results/tusd-header-grammar` failed because final concatenation creation with `Upload-Length` returned `201 Created` instead of rejecting the forbidden header.
Spec: The concatenation extension says the client MUST NOT include `Upload-Length` in final upload creation.
Source evidence: `/tmp/opencode/tus-source-audit/tusd/pkg/handler/unrouted_handler.go:321`-`328` derives final upload size from partial uploads, while `unrouted_handler.go:333`-`337` validates `Upload-Length` only for non-final creations.
Source revision: `1215a10c30218b42ace3eed6db952928472d9545` from `tusproject/tusd:latest` (`tusd -version` reports v2.9.2).
Suggested fix: TUSD should reject final concatenation creation requests that include `Upload-Length`.
Docs: `tests/extensions/concatenation/ext-concat-003-final-no-length.hurl`
Decision: skipped for `tusd` in `tests/skips/tusd.txt` until upstream behavior changes.

## tusd: concat creation responses omit Upload-Concat

Tests: `tests/extensions/concatenation/ext-concat-001-create-partial.hurl`, `tests/extensions/concatenation/ext-concat-002-create-final.hurl`
Observed: `dagger call run --server=TUSD --report=JUNIT export --path results/tusd-task6-concat-term-final` failed because partial and final concatenation `POST` responses returned `201 Created` without the required `Upload-Concat` response header.
Spec: The concatenation extension requires creation responses for partial and final uploads to expose the corresponding `Upload-Concat` value.
Source evidence: `/tmp/opencode/tus-source-audit/tusd/pkg/handler/unrouted_handler.go:361`-`410` initializes the `POST` response headers and adds only `Location`; `unrouted_handler.go:420`-`433` performs final concatenation without adding `Upload-Concat`; `unrouted_handler.go:675`-`690` adds `Upload-Concat` only for `HEAD` responses.
Source revision: `1215a10c30218b42ace3eed6db952928472d9545` from `tusproject/tusd:latest` (`tusd -version` reports v2.9.2).
Suggested fix: TUSD should add `Upload-Concat: partial` to partial creation responses and `Upload-Concat: final;<urls>` to final creation responses.
Docs: `tests/extensions/concatenation/ext-concat-001-create-partial.hurl`, `tests/extensions/concatenation/ext-concat-002-create-final.hurl`
Decision: skipped for `tusd` in `tests/skips/tusd.txt` until upstream behavior changes.

## tusd: creation-with-upload wrong Content-Type is accepted

Test: `tests/extensions/creation-with-upload/ext-cwu-002-post-content-type.hurl`
Observed: `dagger call run --server=TUSD --report=JUNIT export --path results/tusd-header-grammar` failed because a creation-with-upload `POST` body with `Content-Type: text/plain` returned `201 Created` instead of rejecting the body.
Spec: The creation-with-upload extension applies PATCH-like body rules; upload data in the creation request must use `Content-Type: application/offset+octet-stream`.
Source evidence: `/tmp/opencode/tus-source-audit/tusd/pkg/handler/unrouted_handler.go:291`-`294` treats only `application/offset+octet-stream` as a chunk and ignores other content types, and `/tmp/opencode/tus-source-audit/tusd/pkg/handler/post_test.go:528`-`564` asserts `201 Created` for an incorrect content type with a body.
Source revision: `1215a10c30218b42ace3eed6db952928472d9545` from `tusproject/tusd:latest` (`tusd -version` reports v2.9.2).
Suggested fix: TUSD should reject creation-with-upload requests with a non-empty body and wrong `Content-Type`.
Docs: `tests/extensions/creation-with-upload/ext-cwu-002-post-content-type.hurl`
Decision: skipped for `tusd` in `tests/skips/tusd.txt` until upstream behavior changes.

## rustus: missing POST Tus-Resumable is accepted

Tests: `tests/core/cp-err/cp-err-001-response-format.hurl`, `tests/extensions/creation/ext-create-003-requires-tus-resumable.hurl`
Observed: `dagger call run --server=RUSTUS --report=JUNIT export --path results/rustus-header-grammar` failed because `POST` without `Tus-Resumable` returned `201 Created` instead of rejecting the request.
Spec: tus 1.0.0 requires `Tus-Resumable` to be included in every non-`OPTIONS` request and response.
Source evidence: `https://github.com/s3rius/rustus/blob/bec1b287621309616c314720061662de20062e08/src/protocol/creation/mod.rs#L12-L15` routes `POST` directly to `create_file`, and `https://github.com/s3rius/rustus/blob/bec1b287621309616c314720061662de20062e08/src/protocol/creation/routes.rs#L252-L264` creates the upload and returns `201` without request-version validation.
Source revision: `bec1b287621309616c314720061662de20062e08` from `s3rius/rustus:latest` source repository.
Suggested fix: RUSTUS should reject missing or unsupported `Tus-Resumable` values before upload creation.
Docs: `tests/core/cp-err/cp-err-001-response-format.hurl`, `tests/extensions/creation/ext-create-003-requires-tus-resumable.hurl`
Decision: skipped for `rustus` in `tests/skips/rustus.txt` until upstream behavior changes.

## rustus: Upload-Metadata HEAD reorders pairs

Test: `tests/extensions/creation/ext-create-013-metadata-exact-head.hurl`
Observed: `dagger call run --server=RUSTUS --report=JUNIT export --path results/rustus-expiration-strict-fix` failed because `HEAD` returned `Upload-Metadata: filetype dGV4dC9wbGFpbg==,filename dGVzdC50eHQ=` instead of the creation value `filename dGVzdC50eHQ=,filetype dGV4dC9wbGFpbg==`.
Spec: The creation extension says that if an upload contains metadata, `HEAD` responses MUST include `Upload-Metadata` with its value as specified by the client during creation.
Source evidence: `/tmp/opencode/tus-source-audit/rustus/src/protocol/creation/routes.rs:26`-`50` parses metadata into a `HashMap`, `/tmp/opencode/tus-source-audit/rustus/src/file_info.rs:24` stores metadata as a `HashMap`, and `/tmp/opencode/tus-source-audit/rustus/src/file_info.rs:69`-`84` reserializes by iterating the map instead of preserving the original header value or pair order.
Source revision: `bec1b287621309616c314720061662de20062e08` from `s3rius/rustus:latest` source repository.
Suggested fix: RUSTUS should preserve and return the client-provided metadata header value or otherwise preserve pair order when reserializing metadata.
Docs: `tests/extensions/creation/ext-create-013-metadata-exact-head.hurl`
Decision: skipped for `rustus` in `tests/skips/rustus.txt` until upstream behavior changes.

## rustus: missing HEAD Tus-Resumable is accepted

Test: `tests/core/cp-head/cp-head-003-requires-tus-resumable.hurl`
Observed: `dagger call run --server=RUSTUS --report=JUNIT export --path results/rustus-header-grammar` failed because `HEAD` without `Tus-Resumable` returned `200 OK` instead of rejecting the request.
Spec: tus 1.0.0 requires `Tus-Resumable` to be included in every non-`OPTIONS` request and response.
Source evidence: `https://github.com/s3rius/rustus/blob/bec1b287621309616c314720061662de20062e08/src/protocol/core/get_info.rs#L12-L27` loads file info without validating request `Tus-Resumable`, and `https://github.com/s3rius/rustus/blob/bec1b287621309616c314720061662de20062e08/src/protocol/core/get_info.rs#L43-L60` returns normal `200 OK` metadata.
Source revision: `bec1b287621309616c314720061662de20062e08` from `s3rius/rustus:latest` source repository.
Suggested fix: RUSTUS should reject missing or unsupported `Tus-Resumable` values before serving `HEAD` metadata.
Docs: `tests/core/cp-head/cp-head-003-requires-tus-resumable.hurl`
Decision: skipped for `rustus` in `tests/skips/rustus.txt` until upstream behavior changes.

## rustus: HEAD Cache-Control uses no-cache

Test: `tests/core/cp-head/cp-head-004-cache-control.hurl`
Observed: `dagger call run --server=RUSTUS --report=JUNIT export --path results/rustus-header-grammar` failed because successful `HEAD` returned `Cache-Control: no-cache` instead of including `no-store`.
Spec: tus 1.0.0 requires successful `HEAD` responses to prevent caching with `Cache-Control: no-store`.
Source evidence: `https://github.com/s3rius/rustus/blob/bec1b287621309616c314720061662de20062e08/src/protocol/core/mod.rs#L36-L40` wraps `HEAD` with a default `no-store`, but `https://github.com/s3rius/rustus/blob/bec1b287621309616c314720061662de20062e08/src/protocol/core/get_info.rs#L58-L60` inserts `Cache-Control: no-cache` in the handler response.
Source revision: `bec1b287621309616c314720061662de20062e08` from `s3rius/rustus:latest` source repository.
Suggested fix: RUSTUS should return `Cache-Control: no-store` on successful `HEAD` responses and avoid overriding it with `no-cache`.
Docs: `tests/core/cp-head/cp-head-004-cache-control.hurl`
Decision: skipped for `rustus` in `tests/skips/rustus.txt` until upstream behavior changes.

## rustus: missing PATCH Tus-Resumable mutates upload

Test: `tests/core/cp-patch/cp-patch-001-requires-tus-resumable.hurl`
Observed: `dagger call run --server=RUSTUS --report=JUNIT export --path results/rustus-header-grammar` failed because `PATCH` without `Tus-Resumable` returned `204 No Content` and wrote bytes instead of rejecting the request.
Spec: tus 1.0.0 requires `Tus-Resumable` to be included in every non-`OPTIONS` request and response; invalid protocol requests must not mutate upload state.
Source evidence: `https://github.com/s3rius/rustus/blob/bec1b287621309616c314720061662de20062e08/src/protocol/core/write_bytes.rs#L28-L38` validates `Content-Type` and `Upload-Offset` but not `Tus-Resumable`, and `write_bytes.rs#L112-L119` appends bytes and saves the new offset.
Source revision: `bec1b287621309616c314720061662de20062e08` from `s3rius/rustus:latest` source repository.
Suggested fix: RUSTUS should reject missing or unsupported `Tus-Resumable` before writing upload bytes.
Docs: `tests/core/cp-patch/cp-patch-001-requires-tus-resumable.hurl`
Decision: skipped for `rustus` in `tests/skips/rustus.txt` until upstream behavior changes.

## rustus: unsupported HEAD version is accepted

Tests: `tests/core/cp-ver/cp-ver-001-unsupported-version.hurl`, `tests/core/cp-ver/cp-ver-002-412-includes-tus-version.hurl`
Observed: `dagger call run --server=RUSTUS --report=JUNIT export --path results/rustus-header-grammar` failed because `HEAD` with unsupported `Tus-Resumable` values returned `200 OK` instead of `412 Precondition Failed` with `Tus-Version`.
Spec: tus 1.0.0 requires unsupported client protocol versions to be rejected with `412 Precondition Failed`, include `Tus-Version`, and not process the request.
Source evidence: `https://github.com/s3rius/rustus/blob/bec1b287621309616c314720061662de20062e08/src/protocol/core/get_info.rs#L12-L27` serves `HEAD` without request-version validation, while `https://github.com/s3rius/rustus/blob/bec1b287621309616c314720061662de20062e08/src/server.rs#L13-L18` only adds default response version headers.
Source revision: `bec1b287621309616c314720061662de20062e08` from `s3rius/rustus:latest` source repository.
Suggested fix: RUSTUS should reject unsupported `Tus-Resumable` values before serving `HEAD` metadata.
Docs: `tests/core/cp-ver/cp-ver-001-unsupported-version.hurl`, `tests/core/cp-ver/cp-ver-002-412-includes-tus-version.hurl`
Decision: skipped for `rustus` in `tests/skips/rustus.txt` until upstream behavior changes.

## rustus: PATCH beyond Upload-Length is accepted

Test: `tests/core/cp-patch/cp-patch-010-beyond-upload-length.hurl`
Observed: `dagger call run --server=RUSTUS --report=JUNIT export --path results/rustus-header-grammar` failed because a `PATCH` chunk exceeding the declared `Upload-Length` returned `204 No Content` instead of `413 Request Entity Too Large`.
Spec: Uploads must not exceed their declared `Upload-Length`; writes beyond the total length must be rejected without advancing the offset.
Source evidence: `https://github.com/s3rius/rustus/blob/bec1b287621309616c314720061662de20062e08/src/protocol/core/write_bytes.rs#L107-L119` only blocks already-complete uploads, then appends the chunk and increments offset without checking whether `offset + chunk_len` exceeds `length`.
Source revision: `bec1b287621309616c314720061662de20062e08` from `s3rius/rustus:latest` source repository.
Suggested fix: RUSTUS should reject chunks whose resulting offset would exceed the declared upload length.
Docs: `tests/core/cp-patch/cp-patch-010-beyond-upload-length.hurl`
Decision: skipped for `rustus` in `tests/skips/rustus.txt` until upstream behavior changes.

## rustus: checksum mismatch returns 417 instead of 460

Tests: `tests/extensions/checksum/ext-csum-004-mismatch-460.hurl`, `tests/extensions/checksum/ext-csum-005-no-offset-update.hurl`, `tests/extensions/checksum/ext-csum-008-retry-after-failure.hurl`, `tests/extensions/checksum/ext-csum-009-error-returns-tus-resumable.hurl`, `tests/extensions/checksum/scn-error-002-checksum-failure.hurl`
Observed: `dagger call run --server=RUSTUS --report=JUNIT export --path results/rustus-expiration-strict` failed because checksum mismatch `PATCH` requests returned `417 Expectation Failed` instead of `460 Checksum Mismatch`.
Spec: The checksum extension requires checksum mismatch responses to use `460 Checksum Mismatch`; failed checksum writes must not advance upload state.
Source evidence: `/tmp/opencode/tus-source-audit/rustus/src/protocol/core/write_bytes.rs:44`-`53` returns `RustusError::WrongChecksum` before writing bytes, and `/tmp/opencode/tus-source-audit/rustus/src/errors.rs:60`-`61` plus `errors.rs:129` map `WrongChecksum` to `StatusCode::EXPECTATION_FAILED` (`417`) instead of `460`.
Source revision: `bec1b287621309616c314720061662de20062e08` from `s3rius/rustus:latest` source repository.
Suggested fix: RUSTUS should map checksum mismatches to HTTP status `460` while preserving the existing no-mutation behavior.
Docs: `tests/extensions/checksum/ext-csum-004-mismatch-460.hurl`, `tests/extensions/checksum/ext-csum-005-no-offset-update.hurl`, `tests/extensions/checksum/ext-csum-008-retry-after-failure.hurl`, `tests/extensions/checksum/ext-csum-009-error-returns-tus-resumable.hurl`, `tests/extensions/checksum/scn-error-002-checksum-failure.hurl`
Decision: skipped for `rustus` in `tests/skips/rustus.txt` until upstream behavior changes.

## rustus: concat creation responses omit Upload-Concat

Tests: `tests/extensions/concatenation/ext-concat-001-create-partial.hurl`, `tests/extensions/concatenation/ext-concat-002-create-final.hurl`
Observed: `dagger call run --server=RUSTUS --report=JUNIT export --path results/rustus-expiration-strict` failed because partial and final concatenation creation responses returned `201 Created` without the required `Upload-Concat` response header.
Spec: The concatenation extension requires creation responses for partial and final uploads to expose the corresponding `Upload-Concat` value.
Source evidence: `/tmp/opencode/tus-source-audit/rustus/src/protocol/creation/routes.rs:129`-`144` records partial/final concatenation state, but `/tmp/opencode/tus-source-audit/rustus/src/protocol/creation/routes.rs:252`-`264` builds the creation response with `Location` and `Upload-Offset` only.
Source revision: `bec1b287621309616c314720061662de20062e08` from `s3rius/rustus:latest` source repository.
Suggested fix: RUSTUS should add `Upload-Concat: partial` to partial creation responses and `Upload-Concat: final;<urls>` to final creation responses.
Docs: `tests/extensions/concatenation/ext-concat-001-create-partial.hurl`, `tests/extensions/concatenation/ext-concat-002-create-final.hurl`
Decision: skipped for `rustus` in `tests/skips/rustus.txt` until upstream behavior changes.

## rustus: final concat Upload-Length is accepted

Test: `tests/extensions/concatenation/ext-concat-003-final-no-length.hurl`
Observed: `dagger call run --server=RUSTUS --report=JUNIT export --path results/rustus-expiration-strict` failed because final concatenation creation with `Upload-Length` returned `201 Created` instead of rejecting the forbidden header.
Spec: The concatenation extension says the client MUST NOT include `Upload-Length` in final upload creation.
Source evidence: `/tmp/opencode/tus-source-audit/rustus/src/protocol/creation/routes.rs:80`, `routes.rs:97`, `routes.rs:107`, and `routes.rs:174`-`197` accept final upload creation with `Upload-Length`; `/tmp/opencode/tus-source-audit/rustus/src/protocol/creation/routes.rs:452`-`461` has a unit test expecting success for this behavior.
Source revision: `bec1b287621309616c314720061662de20062e08` from `s3rius/rustus:latest` source repository.
Suggested fix: RUSTUS should reject final concatenation creation requests that include `Upload-Length`.
Docs: `tests/extensions/concatenation/ext-concat-003-final-no-length.hurl`
Decision: skipped for `rustus` in `tests/skips/rustus.txt` until upstream behavior changes.

## rustus: final HEAD reconstructs Upload-Concat

Test: `tests/extensions/concatenation/ext-concat-011-final-head-exact-concat.hurl`
Observed: `dagger call run --server=RUSTUS --report=JUNIT export --path results/rustus-expiration-strict` failed because final `HEAD` returned a reconstructed relative `Upload-Concat` value like `final; /files/<id>` instead of the exact absolute final creation value.
Spec: Concatenation metadata must let clients identify the final upload composition consistently; this suite asserts the final `HEAD` value preserves the final creation `Upload-Concat` URLs exactly.
Source evidence: `/tmp/opencode/tus-source-audit/rustus/src/protocol/creation/routes.rs:53`-`61` reduces final `Upload-Concat` URLs to file IDs, `routes.rs:139` stores only those IDs, and `/tmp/opencode/tus-source-audit/rustus/src/protocol/core/get_info.rs:31`-`41` reconstructs a relative header value.
Source revision: `bec1b287621309616c314720061662de20062e08` from `s3rius/rustus:latest` source repository.
Suggested fix: RUSTUS should preserve the client-provided final `Upload-Concat` URL list or reconstruct it exactly according to the externally visible upload URLs.
Docs: `tests/extensions/concatenation/ext-concat-011-final-head-exact-concat.hurl`
Decision: skipped for `rustus` in `tests/skips/rustus.txt` until upstream behavior changes.

## rustus: deferred length mutual exclusion is accepted

Test: `tests/extensions/creation-defer-length/ext-defer-005-mutual-exclusion.hurl`
Observed: `dagger call run --server=RUSTUS --report=JUNIT export --path results/rustus-expiration-strict` failed because creation with both `Upload-Length` and `Upload-Defer-Length: 1` returned `201 Created` instead of rejecting the mutually exclusive headers.
Spec: The creation-defer-length extension requires clients to send either `Upload-Length` or `Upload-Defer-Length: 1`, not both.
Source evidence: `/tmp/opencode/tus-source-audit/rustus/src/protocol/creation/routes.rs:79`-`89` parses both headers, while `/tmp/opencode/tus-source-audit/rustus/src/protocol/creation/routes.rs:104`-`108` only rejects missing length when defer is unavailable and has no branch rejecting both headers together.
Source revision: `bec1b287621309616c314720061662de20062e08` from `s3rius/rustus:latest` source repository.
Suggested fix: RUSTUS should reject creation requests that include both `Upload-Length` and `Upload-Defer-Length: 1`.
Docs: `tests/extensions/creation-defer-length/ext-defer-005-mutual-exclusion.hurl`
Decision: skipped for `rustus` in `tests/skips/rustus.txt` until upstream behavior changes.

## rustus: creation-with-upload wrong Content-Type is accepted

Test: `tests/extensions/creation-with-upload/ext-cwu-002-post-content-type.hurl`
Observed: `dagger call run --server=RUSTUS --report=JUNIT export --path results/rustus-expiration-strict` failed because a creation-with-upload `POST` body with `Content-Type: text/plain` returned `201 Created` instead of rejecting the body.
Spec: The creation-with-upload extension applies PATCH-like body rules; upload data in the creation request must use `Content-Type: application/offset+octet-stream`.
Source evidence: `/tmp/opencode/tus-source-audit/rustus/src/protocol/creation/routes.rs:206`-`221` writes bytes only when `Content-Type` is `application/offset+octet-stream`, `/tmp/opencode/tus-source-audit/rustus/src/protocol/creation/routes.rs:255`-`264` still returns `201 Created` afterward, and `/tmp/opencode/tus-source-audit/rustus/src/protocol/creation/routes.rs:355`-`380` has a unit test expecting wrong content type to create an upload with offset `0`.
Source revision: `bec1b287621309616c314720061662de20062e08` from `s3rius/rustus:latest` source repository.
Suggested fix: RUSTUS should reject creation-with-upload requests with a non-empty body and wrong `Content-Type`.
Docs: `tests/extensions/creation-with-upload/ext-cwu-002-post-content-type.hurl`
Decision: skipped for `rustus` in `tests/skips/rustus.txt` until upstream behavior changes.

## rustus: missing DELETE Tus-Resumable deletes upload

Test: `tests/extensions/termination/ext-term-002-requires-tus-resumable.hurl`
Observed: `dagger call run --server=RUSTUS --report=JUNIT export --path results/rustus-expiration-strict` failed because `DELETE` without `Tus-Resumable` returned `204 No Content` and deleted the upload instead of rejecting the request.
Spec: tus 1.0.0 requires `Tus-Resumable` to be included in every non-`OPTIONS` request; invalid protocol requests must not mutate upload state.
Source evidence: `/tmp/opencode/tus-source-audit/rustus/src/protocol/termination/routes.rs:16`-`20` defines `terminate` without a `Tus-Resumable` check, `/tmp/opencode/tus-source-audit/rustus/src/protocol/termination/routes.rs:39`-`58` removes upload info/data and returns `204`, and `/tmp/opencode/tus-source-audit/rustus/src/protocol/termination/routes.rs:75`-`79` has a unit test sending `DELETE` without `Tus-Resumable` and expecting `204`.
Source revision: `bec1b287621309616c314720061662de20062e08` from `s3rius/rustus:latest` source repository.
Suggested fix: RUSTUS should reject missing or unsupported `Tus-Resumable` before deleting uploads.
Docs: `tests/extensions/termination/ext-term-002-requires-tus-resumable.hurl`
Decision: skipped for `rustus` in `tests/skips/rustus.txt` until upstream behavior changes.

## rustus: unsupported POST version is accepted

Test: `tests/core/cp-ver/cp-ver-004-unsupported-post-no-location.hurl`
Observed: `dagger call run --server=RUSTUS --report=JUNIT export --path results/rustus-header-grammar-check` and targeted Hurl verification failed because `POST` with `Tus-Resumable: 99.99.99` returned `201 Created` instead of `412 Precondition Failed`.
Spec: tus 1.0.0 requires clients to send `Tus-Resumable: 1.0.0` on all requests except `OPTIONS`; unsupported versions must be rejected with `412 Precondition Failed` and not processed.
Source evidence: `https://github.com/s3rius/rustus/blob/bec1b287621309616c314720061662de20062e08/src/server.rs#L13-L18` only adds response `Tus-Resumable`/`Tus-Version` headers, `https://github.com/s3rius/rustus/blob/bec1b287621309616c314720061662de20062e08/src/protocol/creation/routes.rs#L73-L118` creates uploads from `Upload-Length` without validating request `Tus-Resumable`, and no request-version validation exists in the protocol route setup.
Source revision: `bec1b287621309616c314720061662de20062e08` from `s3rius/rustus:latest` source repository.
Suggested fix: RUSTUS should reject non-`1.0.0` `Tus-Resumable` request values before creating uploads.
Docs: `tests/core/cp-ver/cp-ver-004-unsupported-post-no-location.hurl`
Decision: skipped for `rustus` in `tests/skips/rustus.txt` until upstream behavior changes.

## rustus: unsupported PATCH version mutates upload

Test: `tests/core/cp-ver/cp-ver-005-unsupported-patch-no-mutation.hurl`
Observed: `dagger call run --server=RUSTUS --report=JUNIT export --path results/rustus-header-grammar-check` and targeted Hurl verification failed because `PATCH` with `Tus-Resumable: 99.99.99` returned `204 No Content` and accepted the chunk instead of rejecting the request without mutation.
Spec: tus 1.0.0 requires clients to send `Tus-Resumable: 1.0.0` on all requests except `OPTIONS`; unsupported versions must be rejected with `412 Precondition Failed` and not processed.
Source evidence: `https://github.com/s3rius/rustus/blob/bec1b287621309616c314720061662de20062e08/src/server.rs#L13-L18` only adds response `Tus-Resumable`/`Tus-Version` headers, while `https://github.com/s3rius/rustus/blob/bec1b287621309616c314720061662de20062e08/src/protocol/core/write_bytes.rs#L22-L55` validates content type, offset, and checksum but not request `Tus-Resumable` before accepting bytes.
Source revision: `bec1b287621309616c314720061662de20062e08` from `s3rius/rustus:latest` source repository.
Suggested fix: RUSTUS should reject non-`1.0.0` `Tus-Resumable` request values before writing upload bytes.
Docs: `tests/core/cp-ver/cp-ver-005-unsupported-patch-no-mutation.hurl`
Decision: skipped for `rustus` in `tests/skips/rustus.txt` until upstream behavior changes.

## tus-node-server: POST method override is not applied

Tests: `tests/core/cp-override/cp-override-001-post-overrides-patch.hurl`, `tests/extensions/termination/ext-term-006-post-overrides-delete.hurl`
Observed: `dagger call run --server=TUS_NODE_SERVER --report=JUNIT export --path results/tus-node-header-grammar-check` failed because `POST` with `X-HTTP-Method-Override: PATCH` returned `400 Bad Request` instead of applying the `PATCH` handler and returning `204 No Content`; after lowercase `Tus-Extension` discovery was fixed, `dagger call run --server=TUS_NODE_SERVER --report=JUNIT export --path results/tus-node-expiration-strict` also showed `POST` with `X-HTTP-Method-Override: DELETE` returned `400 Bad Request` instead of applying termination.
Spec: tus 1.0.0 requires `X-HTTP-Method-Override`, when present, to be interpreted as the request method while the actual method is ignored.
Source evidence: `https://github.com/tus/tus-node-server/blob/57b1be9bcb01c035bdc30aa1658db36197a409cb/packages/server/src/server.ts#L226-L241` dispatches only on `req.method` and has no `X-HTTP-Method-Override` branch, while `https://github.com/tus/tus-node-server/blob/57b1be9bcb01c035bdc30aa1658db36197a409cb/packages/server/src/test/Server.test.ts#L267-L278` keeps the upstream method-override test skipped.
Source revision: `57b1be9bcb01c035bdc30aa1658db36197a409cb` from `@tus/server@2.4.0` (`npm view @tus/server@2.4.0 gitHead`).
Suggested fix: tus-node-server should rewrite or dispatch the effective method from `X-HTTP-Method-Override` before validation and handler selection.
Docs: `tests/core/cp-override/cp-override-001-post-overrides-patch.hurl`, `tests/extensions/termination/ext-term-006-post-overrides-delete.hurl`
Decision: skipped for `tus-node-server` in `tests/skips/tus-node-server.txt` until upstream behavior changes.

## tus-node-server: creation-with-upload wrong Content-Type is accepted

Test: `tests/extensions/creation-with-upload/ext-cwu-002-post-content-type.hurl`
Observed: `dagger call run --server=TUS_NODE_SERVER --report=JUNIT export --path results/tus-node-expiration-strict` failed because a creation-with-upload `POST` body with `Content-Type: text/plain` returned `201 Created` instead of rejecting the body.
Spec: The creation-with-upload extension says that when a client includes upload bytes in the creation `POST`, similar PATCH rules apply and the client MUST include `Content-Type: application/offset+octet-stream`.
Source evidence: `/tmp/opencode/tus-source-audit/tus-node-server/packages/server/src/handlers/PostHandler.ts:128`-`135` writes upload bytes only when `validateHeader('content-type', req.headers.get('content-type'))` returns true; otherwise it still creates the upload and returns the default `201 Created` response without rejecting the non-empty body.
Source revision: `57b1be9bcb01c035bdc30aa1658db36197a409cb` from `@tus/server@2.4.0`.
Suggested fix: tus-node-server should reject creation-with-upload requests with a non-empty body and a wrong `Content-Type` instead of silently creating an empty upload.
Docs: `tests/extensions/creation-with-upload/ext-cwu-002-post-content-type.hurl`
Decision: skipped for `tus-node-server` in `tests/skips/tus-node-server.txt` until upstream behavior changes.

## tus-node-server: unsupported HEAD version returns 400 instead of 412

Tests: `tests/core/cp-ver/cp-ver-001-unsupported-version.hurl`, `tests/core/cp-ver/cp-ver-002-412-includes-tus-version.hurl`
Observed: `dagger call run --server=TUS_NODE_SERVER --report=JUNIT export --path results/tus-node-header-grammar-check` failed because `HEAD` with unsupported `Tus-Resumable` values returned `400 Bad Request` instead of `412 Precondition Failed` with `Tus-Version`.
Spec: tus 1.0.0 requires unsupported client protocol versions to be rejected with `412 Precondition Failed`, include `Tus-Version`, and not process the request.
Source evidence: `https://github.com/tus/tus-node-server/blob/57b1be9bcb01c035bdc30aa1658db36197a409cb/packages/server/src/validators/HeaderValidator.ts#L66-L72` validates `Tus-Resumable` by returning false for any value other than `1.0.0`; `https://github.com/tus/tus-node-server/blob/57b1be9bcb01c035bdc30aa1658db36197a409cb/packages/server/src/server.ts#L186-L210` converts any invalid header, including unsupported `Tus-Resumable`, into a generic `400` response instead of the required `412` plus `Tus-Version`.
Source revision: `57b1be9bcb01c035bdc30aa1658db36197a409cb` from `@tus/server@2.4.0` (`npm view @tus/server@2.4.0 gitHead`).
Suggested fix: tus-node-server should special-case unsupported `Tus-Resumable` values and return `412 Precondition Failed` with `Tus-Version: 1.0.0` before generic header validation.
Docs: `tests/core/cp-ver/cp-ver-001-unsupported-version.hurl`, `tests/core/cp-ver/cp-ver-002-412-includes-tus-version.hurl`
Decision: skipped for `tus-node-server` in `tests/skips/tus-node-server.txt` until upstream behavior changes.

## tus-node-server: unsupported POST version returns 400 instead of 412

Test: `tests/core/cp-ver/cp-ver-004-unsupported-post-no-location.hurl`
Observed: `dagger call run --server=TUS_NODE_SERVER --report=JUNIT export --path results/tus-node-header-grammar-check` failed because `POST` with `Tus-Resumable: 99.99.99` returned `400 Bad Request` instead of `412 Precondition Failed` with `Tus-Version`.
Spec: tus 1.0.0 requires unsupported client protocol versions to be rejected with `412 Precondition Failed`, include `Tus-Version`, and not process the request.
Source evidence: `https://github.com/tus/tus-node-server/blob/57b1be9bcb01c035bdc30aa1658db36197a409cb/packages/server/src/validators/HeaderValidator.ts#L66-L72` rejects unsupported `Tus-Resumable` values, and `https://github.com/tus/tus-node-server/blob/57b1be9bcb01c035bdc30aa1658db36197a409cb/packages/server/src/server.ts#L186-L210` maps that invalid header to a generic `400` response.
Source revision: `57b1be9bcb01c035bdc30aa1658db36197a409cb` from `@tus/server@2.4.0` (`npm view @tus/server@2.4.0 gitHead`).
Suggested fix: tus-node-server should reject unsupported `Tus-Resumable` before create handling with `412 Precondition Failed`, include `Tus-Version`, and avoid creating an upload.
Docs: `tests/core/cp-ver/cp-ver-004-unsupported-post-no-location.hurl`
Decision: skipped for `tus-node-server` in `tests/skips/tus-node-server.txt` until upstream behavior changes.

## tus-node-server: unsupported PATCH version returns 400 instead of 412

Test: `tests/core/cp-ver/cp-ver-005-unsupported-patch-no-mutation.hurl`
Observed: `dagger call run --server=TUS_NODE_SERVER --report=JUNIT export --path results/tus-node-header-grammar-check` failed because `PATCH` with `Tus-Resumable: 99.99.99` returned `400 Bad Request` instead of `412 Precondition Failed` with `Tus-Version`.
Spec: tus 1.0.0 requires unsupported client protocol versions to be rejected with `412 Precondition Failed`, include `Tus-Version`, and not process the request.
Source evidence: `https://github.com/tus/tus-node-server/blob/57b1be9bcb01c035bdc30aa1658db36197a409cb/packages/server/src/validators/HeaderValidator.ts#L66-L72` rejects unsupported `Tus-Resumable` values, and `https://github.com/tus/tus-node-server/blob/57b1be9bcb01c035bdc30aa1658db36197a409cb/packages/server/src/server.ts#L186-L210` maps that invalid header to a generic `400` response before `PatchHandler` can perform the required no-mutation rejection.
Source revision: `57b1be9bcb01c035bdc30aa1658db36197a409cb` from `@tus/server@2.4.0` (`npm view @tus/server@2.4.0 gitHead`).
Suggested fix: tus-node-server should reject unsupported `Tus-Resumable` before patch handling with `412 Precondition Failed`, include `Tus-Version`, and leave the upload offset unchanged.
Docs: `tests/core/cp-ver/cp-ver-005-unsupported-patch-no-mutation.hurl`
Decision: skipped for `tus-node-server` in `tests/skips/tus-node-server.txt` until upstream behavior changes.
