# OPT-STORE-001: Storage full during upload
# Spec: No specific error code
# Suggested Best Practice: Return 507 Insufficient Storage or 413
# Note: Actual storage exhaustion requires server-specific setup

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

# Normal upload (documents expected success path)
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
test data
```

HTTP 204

# Note: To test storage full:
# 1. Configure server with limited storage
# 2. Fill storage near capacity
# 3. Attempt upload
# 4. Expected: 507 Insufficient Storage or 413 Request Entity Too Large
