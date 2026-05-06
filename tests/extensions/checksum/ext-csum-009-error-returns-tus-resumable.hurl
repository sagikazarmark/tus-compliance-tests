# EXT-CSUM-009: Checksum error returns Tus-Resumable
# Error responses MUST include Tus-Resumable except for OPTIONS
# Spec: checksum mismatch requires HTTP 460 and non-OPTIONS responses include Tus-Resumable.

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
Upload-Checksum: sha1 AAAAAAAAAAAAAAAAAAAAAAAAAAA=

```
Hello, tus!
```

HTTP 460

[Asserts]
header "Tus-Resumable" == "{{tus_version}}"
