# CP-PATCH-006: PATCH success returns 204
# Successful PATCH MUST return 204 No Content
# Spec: "The Server MUST acknowledge successful PATCH request with the 204 No Content status"

# Step 1: Create an upload
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 12

HTTP 201

[Captures]
upload_url: header "Location"

# Step 2: Successful PATCH
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream
```
Hello, tus!
```

HTTP 204
