# CP-PATCH-004: PATCH requires Upload-Offset
# Missing Upload-Offset header MUST be rejected
# Spec: "The Client MUST send the Upload-Offset header"

# Step 1: Create an upload
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

# Step 2: PATCH without Upload-Offset header - should fail
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Content-Type: application/offset+octet-stream

```
test data
```

HTTP 400
