# SCN-BASIC-001: Complete small upload
# Create upload, send all bytes in single PATCH, verify completion

# Step 1: Create upload
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 12

HTTP 201

[Captures]
upload_url: header "Location"

# Step 2: Upload all data in single PATCH
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
Hello, tus!
```

HTTP 204

[Asserts]
header "Upload-Offset" == "12"

# Step 3: Verify completion
HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP 200

[Asserts]
header "Upload-Offset" == "12"
header "Upload-Length" == "12"
