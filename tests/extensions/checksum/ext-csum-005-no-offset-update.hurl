# EXT-CSUM-005: Failed checksum does not update offset
# Server MUST NOT accept bytes when checksum fails
# Spec: "The Server MUST NOT accept the transferred bytes when the checksum fails"

# Create upload
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

# PATCH with wrong checksum
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream
Upload-Checksum: sha1 AAAAAAAAAAAAAAAAAAAAAAAAAAAA

```
test data
```

HTTP 460

# Verify offset was NOT updated
HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP 200

[Asserts]
header "Upload-Offset" == "0"
