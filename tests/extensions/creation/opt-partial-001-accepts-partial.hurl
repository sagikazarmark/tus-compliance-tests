# OPT-PARTIAL-001: Server accepts partial PATCH
# Spec: Says "store maximum" but behavior unclear
# Suggested Best Practice: Accept partial data, update offset to bytes received

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 1000

HTTP 201

[Captures]
upload_url: header "Location"

# Send some data
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
test data chunk
```

HTTP 204

[Asserts]
header "Upload-Offset" exists
# Server should report actual bytes stored
