# OPT-PARTIAL-003: Client notification of partial
# Spec Gap: How to signal incomplete write?
# Suggested Best Practice: Upload-Offset in response reflects actual bytes stored

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

# Send data
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
test data
```

HTTP 204

[Captures]
reported_offset: header "Upload-Offset"

# Verify HEAD confirms the same offset
HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP 200

[Asserts]
header "Upload-Offset" == "{{reported_offset}}"
