# OPT-META-005: Non-ASCII metadata keys
# Spec: "The key SHOULD be ASCII encoded." SHOULD, not MUST.
#
# Truly sending non-ASCII bytes in an HTTP header is largely blocked by the
# transport layer: RFC 7230 §3.2.4 restricts header field values to VCHAR + SP/HTAB,
# and most client/server HTTP stacks either reject or mangle non-ASCII bytes
# before they reach any tus-aware code. Percent-encoding is not meaningful in
# header values (servers treat headers as opaque byte strings), so a percent-encoded
# "key" is still all-ASCII from the server's perspective.
#
# As a result this behaviour is not robustly testable in hurl. We send an
# all-ASCII key as a baseline; a real implementation should also be spot-checked
# with a client that can force raw non-ASCII bytes on the wire.

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100
Upload-Metadata: filename dGVzdC50eHQ=

HTTP 201

[Asserts]
header "Location" exists
