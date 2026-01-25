# SCN-BASIC-002: Complete chunked upload
# Create upload, send bytes across multiple PATCH requests

# Step 1: Create upload for 33 bytes (3 chunks of 11 bytes each with newlines)
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 33

HTTP 201

[Captures]
upload_url: header "Location"

# Step 2: Upload first chunk (11 bytes with newline)
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

# Step 3: Upload second chunk (11 bytes with newline)
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

# Step 4: Upload third chunk (11 bytes with newline)
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

# Step 5: Verify completion
HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP 200

[Asserts]
header "Upload-Offset" == "33"
header "Upload-Length" == "33"
