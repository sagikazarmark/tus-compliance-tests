# OPT-PARTIAL-002: Partial write response code
# Spec Gap: Should partial acceptance be 204 or different?
# Suggested Best Practice: Return 204 with accurate Upload-Offset

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
partial
```

HTTP 204

[Asserts]
header "Upload-Offset" exists
# Best practice: 204 indicates success, Upload-Offset shows actual progress
