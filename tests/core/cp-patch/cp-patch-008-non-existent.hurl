# CP-PATCH-008: PATCH on non-existent resource
# SHOULD return 404 Not Found
# Spec: "If the resource is not found, the Server SHOULD return 404 Not Found"

PATCH {{base_url}}/non-existent-upload-id-12345
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
test data
```

HTTP 404
