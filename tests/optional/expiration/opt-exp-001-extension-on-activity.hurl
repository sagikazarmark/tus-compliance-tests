# OPT-EXP-001: Expiration extension on active upload
# Spec: Does activity extend expiration?
# Suggested Best Practice: Extend expiration on each successful PATCH

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

# First PATCH - note expiration (if present)
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
first chunk
```

HTTP 204

# Second PATCH - expiration may be extended
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 12
Content-Type: application/offset+octet-stream

```
second chunk
```

HTTP 204

# Note: Best practice is to extend expiration on activity
# Compare Upload-Expires between responses to verify extension
