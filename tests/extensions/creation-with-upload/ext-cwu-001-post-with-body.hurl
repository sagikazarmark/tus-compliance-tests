# EXT-CWU-001: POST with body
# POST with request body MUST accept initial bytes
# Spec: "The Client MAY include parts of the upload in the initial Creation request"

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
header "Upload-Offset" exists
