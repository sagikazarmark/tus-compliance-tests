# OPT-META-002: Duplicate metadata keys
# Spec: "All keys MUST be unique" but no error response is specified.
# Suggested Best Practice: return 400 Bad Request.
# Alternative permissive behaviour: accept the request and keep first or last value.

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100
Upload-Metadata: filename dGVzdC50eHQ=,filename ZHVwbGljYXRl

HTTP *

[Asserts]
# Accept 201 (lenient) or 400 (strict); any other code indicates a bug.
status toString matches /^(201|400)$/
