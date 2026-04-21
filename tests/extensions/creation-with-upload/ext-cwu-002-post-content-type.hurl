# EXT-CWU-002: POST body with wrong Content-Type is rejected
# POST with body MUST use Content-Type: application/offset+octet-stream.
# Spec: the same PATCH rules apply, so a wrong Content-Type on a creation-with-upload
# body MUST be rejected with 415 Unsupported Media Type.

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 12
Content-Type: text/plain

```
Hello, tus!
```

HTTP 415
