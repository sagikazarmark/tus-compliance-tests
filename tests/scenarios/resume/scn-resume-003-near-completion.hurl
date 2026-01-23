# SCN-RESUME-003: Resume near completion
# Upload most bytes, disconnect, resume final bytes

# Step 1: Create upload for 103 bytes (101 + 2)
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 103

HTTP 201

[Captures]
upload_url: header "Location"

# Step 2: Upload 101 bytes (100 A's + newline)
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
```

HTTP 204

[Asserts]
header "Upload-Offset" == "101"

# Step 3: Check status
HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP 200

[Asserts]
header "Upload-Offset" == "101"

# Step 4: Upload final 2 bytes (Z + newline)
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 101
Content-Type: application/offset+octet-stream

```
Z
```

HTTP 204

[Asserts]
header "Upload-Offset" == "103"

# Step 5: Verify completion
HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP 200

[Asserts]
header "Upload-Offset" == "103"
header "Upload-Length" == "103"
