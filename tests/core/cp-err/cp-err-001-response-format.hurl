# OPT-ERR-001: Error response format
# Spec: No error body format specified
# Suggested Best Practice: Return JSON: {"error": "description", "code": "ERROR_CODE"}

# Trigger an error (missing Tus-Resumable)
POST {{base_url}}
Upload-Length: 100

HTTP *

[Asserts]
status toString matches /^(400|412)$/
header "Location" not exists

# Note: Error response format is implementation-specific
# Best practice: Include machine-readable error code and human-readable message
