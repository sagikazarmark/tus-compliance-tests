# SCN-ERROR-002: Recover from checksum failure
# Send bad checksum, get 460, verify offset unchanged, retry with correct checksum
# Prerequisite: Server must support checksum extension

# Step 1: Create upload
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 12

HTTP 201

[Captures]
upload_url: header "Location"

# Step 2: Attempt upload with wrong checksum
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream
Upload-Checksum: sha1 AAAAAAAAAAAAAAAAAAAAAAAAAAAA

```
Hello, tus!
```

HTTP 460

# Step 3: Verify offset was not updated
HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP 200

[Asserts]
header "Upload-Offset" == "0"

# Step 4: Retry with correct checksum
# SHA1 of "Hello, tus!\n" = jiVMcGsdc+pakQJdI4OKm+zKT3s=
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream
Upload-Checksum: sha1 jiVMcGsdc+pakQJdI4OKm+zKT3s=

```
Hello, tus!
```

HTTP 204

[Asserts]
header "Upload-Offset" == "12"
