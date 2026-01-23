# EXT-DEFER-004: Upload-Length immutable
# Once Upload-Length set, subsequent changes MUST be rejected
# Spec: "Once the Upload-Length header has been set, it MUST NOT be changed"

# Create upload with deferred length
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Defer-Length: 1

HTTP 201

[Captures]
upload_url: header "Location"

# First PATCH sets the length
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Upload-Length: 100
Content-Type: application/offset+octet-stream

```
test
```

HTTP 204

# Try to change the length - should be rejected
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 5
Upload-Length: 200
Content-Type: application/offset+octet-stream

```
more
```

HTTP 400
