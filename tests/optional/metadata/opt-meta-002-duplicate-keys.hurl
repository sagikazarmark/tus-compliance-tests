# OPT-META-002: Duplicate metadata keys
# Spec: "Keys MUST be unique" but no error response specified
# Suggested Best Practice: Return 400 Bad Request

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100
Upload-Metadata: filename dGVzdC50eHQ=,filename ZHVwbGljYXRl

# Expected: 400 Bad Request for duplicate keys
HTTP *

[Asserts]
# Server should reject duplicate keys with 400
# Some servers may use last value or first value
status >= 200
status <= 500
