# EXT-CSUM-010: Missing checksum tuple separator returns 400
# Upload-Checksum MUST be "algorithm base64-checksum" format.
# Spec requires 400 when the checksum algorithm cannot be parsed/supported.

# Create upload
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 12

HTTP 201

[Captures]
upload_url: header "Location"

# PATCH with missing space between algorithm and checksum
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream
Upload-Checksum: sha1E7X121m3do5RTtnrOi5XTG9Uq0A=

```
Hello, tus!
```

HTTP 400
