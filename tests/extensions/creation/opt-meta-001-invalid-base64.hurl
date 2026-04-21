# OPT-META-001: Invalid base64 in metadata value
# Spec Gap: Spec doesn't define the error response for invalid base64.
# Suggested Best Practice: return 400 Bad Request with a descriptive error.
# Alternative permissive behaviour: accept creation and treat the value as opaque.

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100
Upload-Metadata: filename not_valid_base64!!!

HTTP *

[Asserts]
# Accept 201 (lenient) or 400 (strict); other codes indicate a bug.
status toString matches /^(201|400)$/
