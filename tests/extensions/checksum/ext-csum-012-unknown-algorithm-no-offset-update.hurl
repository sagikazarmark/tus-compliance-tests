# EXT-CSUM-012: Unknown algorithm does not update offset
# Server MUST return 400 for unsupported checksum algorithm.
# Rejected checksum PATCH requests MUST NOT advance the upload offset.

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

# Verify offset was NOT updated
HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP 200

[Asserts]
header "Upload-Offset" == "0"
