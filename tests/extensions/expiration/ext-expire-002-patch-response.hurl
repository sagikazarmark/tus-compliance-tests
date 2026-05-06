# EXT-EXPIRE-002: Upload-Expires in PATCH response
# Servers MUST return Upload-Expires on PATCH only if this upload is going to expire.
# Strict configured-expiration validation lives in tests/probes/expiration_lifecycle.py.

# Create upload
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

# PATCH and check for Upload-Expires
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
test data
```

HTTP 204
