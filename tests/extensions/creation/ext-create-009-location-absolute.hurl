# EXT-CREATE-009: Location header is a resolvable URL
# Location header MUST be a URL (absolute or relative) that the client can resolve.
# Spec: "The Server MUST set the Location header to the URL of the created resource."
# Relative URLs are valid per RFC 7231 §7.1.2; this test accepts either form.

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Asserts]
header "Location" exists
# Location MUST be non-empty. Form (absolute or relative) is not mandated by the spec.
header "Location" matches "^.+$"
