# OPT-COMP-003: Upload completion notification
# Spec: No callback/webhook mechanism
# Suggested Best Practice: Optionally support Upload-Complete header or webhook
# This test documents expected completion state

# Create and complete upload
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 12

HTTP 201

[Captures]
upload_url: header "Location"

PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
Hello, tus!
```

HTTP 204

[Asserts]
header "Upload-Offset" == "12"

# Verify completion state
HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP 200

[Asserts]
header "Upload-Offset" == "12"
header "Upload-Length" == "12"
# Note: Some servers may include Upload-Complete: true header
