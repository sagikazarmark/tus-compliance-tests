# EXT-CWU-002: POST body Content-Type
# POST with body MUST use Content-Type: application/offset+octet-stream
# Spec: "If the request includes a body, the content type MUST be application/offset+octet-stream"

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 12
Content-Type: application/offset+octet-stream

```
Hello, tus!
```

HTTP 201

[Asserts]
header "Location" exists
