# SCN-ERROR-001: Recover from offset mismatch
# Attempt PATCH with wrong offset, get 409, HEAD to correct, retry

# Step 1: Create upload (22 bytes: 2 chunks of 11 bytes each)
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 22

HTTP 201

[Captures]
upload_url: header "Location"

# Step 2: Upload first chunk
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
AAAAAAAAAA
```

HTTP 204

# Step 3: Client has stale offset (thinks 0), server has 11
# This simulates client retry without checking offset first
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
WRONGOFFSET
```

HTTP 409

# Step 4: Client recovers by checking current offset
HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP 200

[Captures]
correct_offset: header "Upload-Offset"

[Asserts]
header "Upload-Offset" == "11"

# Step 5: Retry with correct offset
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: {{correct_offset}}
Content-Type: application/offset+octet-stream

```
BBBBBBBBBB
```

HTTP 204

[Asserts]
header "Upload-Offset" == "22"
