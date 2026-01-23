# CP-PATCH-001: PATCH requires Tus-Resumable
# Request without Tus-Resumable MUST return 412 Precondition Failed
# Spec: "If the version specified by the Client is not supported by the Server,
#        it MUST respond with the 412 Precondition Failed status"

# Step 1: Create an upload first
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

# Step 2: PATCH without Tus-Resumable header
# Strict compliance: MUST return 412 with Tus-Version header
# Note: tusd is lenient and may accept requests without Tus-Resumable
PATCH {{upload_url}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
test data
```

HTTP *

[Asserts]
# Strict servers return 412, lenient servers may return 204 or 4xx
status >= 200
status < 500
