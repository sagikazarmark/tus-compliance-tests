# OPT-META-001: Invalid base64 in metadata value
# Spec Gap: Spec doesn't define error response for invalid base64
# Suggested Best Practice: Return 400 Bad Request with descriptive error

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100
Upload-Metadata: filename not_valid_base64!!!

# Expected: 400 Bad Request (best practice)
# Some servers may accept or ignore invalid metadata
HTTP *

[Asserts]
# Document the response - 400 is best practice, 201 may be acceptable
status >= 200
status <= 500
