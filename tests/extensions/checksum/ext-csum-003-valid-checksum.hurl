# EXT-CSUM-003: Valid checksum accepted
# PATCH with correct checksum MUST succeed
# Spec: "If the checksums match, the Server MUST acknowledge the successful transfer"

# Create upload
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 12

HTTP 201

[Captures]
upload_url: header "Location"

# PATCH with correct SHA1 checksum
# SHA1 of "Hello, tus!\n" = E7X121m3do5RTtnrOi5XTG9Uq0A=
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream
Upload-Checksum: sha1 E7X121m3do5RTtnrOi5XTG9Uq0A=

```
Hello, tus!
```

HTTP 204

[Asserts]
header "Upload-Offset" == "12"
