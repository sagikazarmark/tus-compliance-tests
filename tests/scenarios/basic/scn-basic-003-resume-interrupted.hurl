# SCN-BASIC-003: Resume interrupted upload
# Create, partial PATCH, HEAD to get offset, resume with second PATCH

# Step 1: Create upload (22 bytes: 2 chunks of 11 bytes each)
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 22

HTTP 201

[Captures]
upload_url: header "Location"

# Step 2: Upload first part (simulating interrupted upload)
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
AAAAAAAAAA
```

HTTP 204

[Asserts]
header "Upload-Offset" == "11"

# Step 3: Client "reconnects" - check current offset via HEAD
HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP 200

[Asserts]
header "Upload-Offset" == "11"

# Step 4: Resume upload from offset 11
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 11
Content-Type: application/offset+octet-stream

```
BBBBBBBBBB
```

HTTP 204

[Asserts]
header "Upload-Offset" == "22"

# Step 5: Verify completion
HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP 200

[Asserts]
header "Upload-Offset" == "22"
header "Upload-Length" == "22"
