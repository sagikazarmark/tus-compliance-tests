# OPT-CSUM-002: Multiple checksums
# Spec: Can client send multiple algorithms?
# Suggested Best Practice: Accept first valid; ignore others
# Note: tus spec only defines single checksum per request

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 12

HTTP 201

[Captures]
upload_url: header "Location"

# Send single checksum (spec-compliant)
# "Hello, tus!\n" SHA1: E7X121m3do5RTtnrOi5XTG9Uq0A=
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream
Upload-Checksum: sha1 E7X121m3do5RTtnrOi5XTG9Uq0A=

```
Hello, tus!
```

HTTP 204

# Note: Spec defines single "algorithm base64" format
# Multiple algorithms would need extension or custom handling
