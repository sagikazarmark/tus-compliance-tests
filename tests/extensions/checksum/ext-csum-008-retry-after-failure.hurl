# EXT-CSUM-008: Retry after checksum failure
# Client can retry with correct checksum after 460 error

# Create upload
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 12

HTTP 201

[Captures]
upload_url: header "Location"

# First attempt with wrong checksum
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream
Upload-Checksum: sha1 AAAAAAAAAAAAAAAAAAAAAAAAAAAA

```
Hello, tus!
```

HTTP 460

# Retry with correct checksum
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
