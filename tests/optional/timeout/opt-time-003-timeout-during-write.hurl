# OPT-TIME-003: Timeout during write
# Spec: What happens to partial data?
# Suggested Best Practice: Store received bytes; client can resume
# Note: This documents expected behavior

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

# Upload partial data
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
partial data here
```

HTTP 204

[Captures]
current_offset: header "Upload-Offset"

# Simulate "reconnect after timeout" - verify data was stored
HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP 200

[Asserts]
header "Upload-Offset" == "{{current_offset}}"

# Note: If timeout occurred during write, best practice is to:
# 1. Store whatever bytes were received
# 2. Allow client to resume from actual stored offset
