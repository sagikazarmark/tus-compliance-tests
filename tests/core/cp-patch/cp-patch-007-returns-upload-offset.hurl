# CP-PATCH-007: PATCH returns Upload-Offset
# Response MUST include updated Upload-Offset
# Spec: "The Server MUST include the Upload-Offset header in the response
#        containing the new offset"

# Step 1: Create an upload
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 12

HTTP 201

[Captures]
upload_url: header "Location"

# Step 2: PATCH and verify returned offset
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
Hello, tus!
```

HTTP 204

[Asserts]
header "Upload-Offset" exists
header "Upload-Offset" == "12"
