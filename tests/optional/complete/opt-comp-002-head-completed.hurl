# OPT-COMP-002: HEAD on completed upload
# Spec: Doesn't distinguish complete vs incomplete
# Suggested Best Practice: Return Upload-Offset == Upload-Length

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

# HEAD on completed upload
HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP 200

[Asserts]
# Completion is indicated by Upload-Offset == Upload-Length
header "Upload-Offset" == "12"
header "Upload-Length" == "12"
