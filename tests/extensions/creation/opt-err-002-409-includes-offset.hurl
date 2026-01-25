# OPT-ERR-002: 409 Conflict includes current offset
# Spec: Doesn't require it
# Suggested Best Practice: Include Upload-Offset header in 409 response

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

# Upload some data
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
first chunk
```

HTTP 204

# Trigger 409 with wrong offset
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
wrong offset
```

HTTP 409

# Best practice: Include Upload-Offset header showing correct offset
# This helps clients recover without additional HEAD request
