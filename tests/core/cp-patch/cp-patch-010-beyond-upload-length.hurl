# CP-PATCH-010: PATCH beyond Upload-Length
# Sending more bytes than declared MUST be rejected
# Spec: "The Client MUST NOT send more bytes than the Upload-Length header specified"

# Step 1: Create an upload with small length
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 5

HTTP 201

[Captures]
upload_url: header "Location"

# Step 2: Try to send more bytes than allowed (12 bytes when only 5 allowed)
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
Hello, tus!
```

HTTP 413
