# OPT-CONC-002: Concurrent HEAD during PATCH
# Spec: Can HEAD be served during active write?
# Suggested Best Practice: Return last committed offset
# Note: True concurrency requires external tooling

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

# Upload some data
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
test data
```

HTTP 204

# HEAD should return consistent offset
HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP 200

[Asserts]
header "Upload-Offset" exists
