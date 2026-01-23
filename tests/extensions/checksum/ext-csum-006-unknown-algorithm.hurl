# EXT-CSUM-006: Unknown algorithm returns 400
# Server MUST return 400 for unsupported checksum algorithm
# Spec: "If the checksum algorithm is not supported, it MUST return 400 Bad Request"

# Create upload
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 12

HTTP 201

[Captures]
upload_url: header "Location"

# PATCH with unknown algorithm
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream
Upload-Checksum: unknownalgo AAAAAAAAAA

```
Hello, tus!
```

HTTP 400
