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
