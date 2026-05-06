# EXT-CSUM-011: Malformed checksum base64 returns 400
# Upload-Checksum MUST contain a Base64 encoded checksum.
# Spec requires 400 when the checksum algorithm/checksum tuple is malformed.

# Create upload
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 12

HTTP 201

[Captures]
upload_url: header "Location"

# PATCH with invalid Base64 checksum value
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream
Upload-Checksum: sha1 not_base64!!!

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
