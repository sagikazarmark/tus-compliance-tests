# OPT-STORE-002: Upload-Length change attempt
# Spec: Only "immutable once set" mentioned
# Suggested Best Practice: Return 400 with clear error message

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

# Attempt to change length via PATCH header
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Upload-Length: 200
Content-Type: application/offset+octet-stream

```
test
```

HTTP 400

# Note: Upload-Length is immutable once set
# Server should reject attempts to change it with 400 Bad Request
