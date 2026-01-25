# EXT-CSUM-007: Checksum format validation
# Upload-Checksum MUST be "algorithm base64-checksum" format
# Spec: "The header value MUST be a tuple of the algorithm name and the Base64 encoded checksum"

# Create upload
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 12

HTTP 201

[Captures]
upload_url: header "Location"

# PATCH with valid format checksum
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
