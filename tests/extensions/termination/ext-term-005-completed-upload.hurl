# EXT-TERM-005: DELETE completed upload
# DELETE on completed upload SHOULD succeed
# Spec: Server should allow deletion of completed uploads

# Create and complete an upload
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 12

HTTP 201

[Captures]
upload_url: header "Location"

# Complete the upload
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
Hello, tus!
```

HTTP 204

# Verify upload is complete
HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP 200

[Asserts]
header "Upload-Offset" == "12"
header "Upload-Length" == "12"

# Delete the completed upload
DELETE {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP 204
