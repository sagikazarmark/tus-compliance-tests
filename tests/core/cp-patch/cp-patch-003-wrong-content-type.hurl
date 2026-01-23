# CP-PATCH-003: PATCH wrong Content-Type
# Wrong Content-Type MUST return 415 Unsupported Media Type
# Spec: "All PATCH requests MUST use Content-Type: application/offset+octet-stream"

# Step 1: Create an upload
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

# Step 2: PATCH with wrong Content-Type - MUST return 415
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: text/plain

```
test data
```

HTTP 415
