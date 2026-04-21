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

[Asserts]
# Best practice: 409 response includes Upload-Offset showing the correct offset,
# so clients can recover without an additional HEAD request.
# We don't pin the exact offset: servers MAY partial-accept the earlier PATCH,
# so the correct value is whatever the server actually committed.
header "Upload-Offset" exists
header "Upload-Offset" matches "^[0-9]+$"
