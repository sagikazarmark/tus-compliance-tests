# OPT-EXP-002: Completed upload expiration
# Spec: Do completed uploads expire?
# Suggested Best Practice: Different retention for complete vs incomplete

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

# Check completed upload status
HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP 200

[Asserts]
header "Upload-Offset" == "12"
header "Upload-Length" == "12"

# Note: Completed uploads may have different expiration policy
# Best practice: Longer retention for completed uploads, or no expiration
# If Upload-Expires is present, compare to incomplete upload expiration
