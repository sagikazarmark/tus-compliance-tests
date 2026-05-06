# EXT-TERM-003: Deleted resource returns 404/410
# Subsequent HEAD/PATCH SHOULD return 404 or 410, but exact status is not mandatory.
# Spec: "Subsequent requests to the URL SHOULD return 404 Not Found or 410 Gone"

# Create upload
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

# Delete the upload
DELETE {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP 204

# Subsequent HEAD should return 404 or 410
HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP *

[Asserts]
status >= 400
status < 500

# Subsequent PATCH should return 404 or 410
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
data
```

HTTP *

[Asserts]
status >= 400
status < 500
