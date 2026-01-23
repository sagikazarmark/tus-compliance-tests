# EXT-CSUM-004: Checksum mismatch returns 460
# PATCH with wrong checksum MUST return 460 Checksum Mismatch
# Spec: "If the checksums do not match, the Server MUST return 460 Checksum Mismatch"

# Create upload
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 12

HTTP 201

[Captures]
upload_url: header "Location"

# PATCH with incorrect checksum
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream
Upload-Checksum: sha1 AAAAAAAAAAAAAAAAAAAAAAAAAAAA

```
Hello, tus!
```

HTTP 460
