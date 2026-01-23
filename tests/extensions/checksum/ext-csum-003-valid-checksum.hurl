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
# SHA1 of "Hello, tus!\n" = jiVMcGsdc+pakQJdI4OKm+zKT3s=
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream
Upload-Checksum: sha1 jiVMcGsdc+pakQJdI4OKm+zKT3s=

```
Hello, tus!
```

HTTP 204

[Asserts]
header "Upload-Offset" == "12"
