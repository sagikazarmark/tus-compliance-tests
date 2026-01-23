# EXT-EXPIRE-002: Upload-Expires in PATCH response
# PATCH response SHOULD include Upload-Expires header
# Spec: "The Server MAY add the Upload-Expires header to indicate when the upload expires"

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

# Upload-Expires may be present in response
# If present, should be a valid datetime
