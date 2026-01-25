# SCN-RESUME-004: Multiple resume cycles
# Create, upload 25%, resume to 50%, resume to 75%, complete

# Step 1: Create upload for 44 bytes (4 chunks of 11 bytes each)
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 44

HTTP 201

[Captures]
upload_url: header "Location"

# Step 2: Upload 25% (11 bytes)
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

# Step 3: Disconnect, reconnect, check status
HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP 200

[Asserts]
header "Upload-Offset" == "11"

# Step 4: Resume to 50%
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

# Step 5: Another disconnect, check status
HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP 200

[Asserts]
header "Upload-Offset" == "22"

# Step 6: Resume to 75%
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 22
Content-Type: application/offset+octet-stream

```
CCCCCCCCCC
```

HTTP 204

[Asserts]
header "Upload-Offset" == "33"

# Step 7: Final disconnect, check status
HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP 200

[Asserts]
header "Upload-Offset" == "33"

# Step 8: Complete the upload
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 33
Content-Type: application/offset+octet-stream

```
DDDDDDDDDD
```

HTTP 204

[Asserts]
header "Upload-Offset" == "44"

# Step 9: Verify completion
HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP 200

[Asserts]
header "Upload-Offset" == "44"
header "Upload-Length" == "44"
