# SCN-ERROR-003: Handle expired upload
# Attempt resume on expired upload, get 404/410, create new upload
# Note: This scenario requires server-side expiration configuration
#       Test documents the expected workflow

# Step 1: Create upload
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

# Step 2: Upload partial data
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
partial data
```

HTTP 204

# Step 3: Verify upload exists
HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP 200

# Note: In real expiration scenario:
# - Wait for server expiration timeout
# - HEAD would return 404 or 410
# - Client would then create new upload and restart

# Step 4: This documents the recovery pattern (without actual expiration)
# After receiving 404/410, client should create new upload
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
new_upload_url: header "Location"

[Asserts]
header "Location" exists
