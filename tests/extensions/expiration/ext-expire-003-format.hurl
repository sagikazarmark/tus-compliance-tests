# EXT-EXPIRE-003: Upload-Expires format
# Upload-Expires MUST use RFC 9110 datetime format when present.
# Hurl cannot conditionally assert an optional header; strict validation lives in tests/probes/expiration_lifecycle.py.
# Format example: "Sat, 18 Apr 2020 12:31:39 GMT"

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

# PATCH response smoke coverage. Configured expiration checks validate Upload-Expires format.
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
partial data
```

HTTP 204
