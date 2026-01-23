# SCN-RESUME-002: Resume from middle
# Upload 50%, simulate disconnect, HEAD, resume from reported offset

# Step 1: Create upload for 22 bytes (2 chunks of 11 bytes)
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 22

HTTP 201

[Captures]
upload_url: header "Location"

# Step 2: Upload first half (50%)
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
AAAAAAAAAA
```

HTTP 204

# Step 3: Simulate client reconnect - check current status
HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP 200

[Captures]
current_offset: header "Upload-Offset"

[Asserts]
header "Upload-Offset" == "11"

# Step 4: Resume from middle
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: {{current_offset}}
Content-Type: application/offset+octet-stream

```
BBBBBBBBBB
```

HTTP 204

[Asserts]
header "Upload-Offset" == "22"
