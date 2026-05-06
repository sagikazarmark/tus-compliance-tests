# EXT-EXPIRE-001: expiration creation smoke test
# Spec: "The Server MAY add the Upload-Expires header to indicate when the upload expires"
# Strict creation-time Upload-Expires validation lives in tests/probes/expiration_lifecycle.py
# when the server exposes a known expiration at creation time.

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Asserts]
header "Location" exists
# Upload-Expires is optional but if present must be valid datetime format
