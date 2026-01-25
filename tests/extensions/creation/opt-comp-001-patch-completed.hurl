# OPT-COMP-001: PATCH on completed upload
# Spec: Doesn't define behavior
# Behavior varies: some servers return 204 (no-op), others return 4xx

# Create and complete upload
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 12

HTTP 201

[Captures]
upload_url: header "Location"

PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
Hello, tus!
```

HTTP 204

# Attempt PATCH on completed upload (at final offset)
# Some servers return 204 (accept as no-op), others return 4xx
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 12
Content-Type: application/offset+octet-stream

HTTP *

[Asserts]
# Accept either success (204) or error (4xx) - behavior is undefined
status < 500
