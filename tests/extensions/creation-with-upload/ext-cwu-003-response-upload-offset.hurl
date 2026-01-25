# EXT-CWU-003: Response includes Upload-Offset
# 201 response MUST include Upload-Offset with accepted byte count
# Spec: "The Server MUST include the Upload-Offset header in the response"

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 12
Content-Type: application/offset+octet-stream

```
Hello, tus!
```

HTTP 201

[Asserts]
header "Upload-Offset" exists
header "Upload-Offset" matches "^[0-9]+$"
# Should indicate 12 bytes received (or less if partial acceptance)
