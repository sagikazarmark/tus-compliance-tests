# EXT-CWU-005: Complete upload in POST
# If body size equals Upload-Length, upload is complete
# Spec: The upload is complete when the entire body is received

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 12
Content-Type: application/offset+octet-stream

```
Hello, tus!
```

HTTP 201

[Captures]
upload_url: header "Location"

[Asserts]
header "Upload-Offset" == "12"

# Verify upload is complete
HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP 200

[Asserts]
header "Upload-Offset" == "12"
header "Upload-Length" == "12"
