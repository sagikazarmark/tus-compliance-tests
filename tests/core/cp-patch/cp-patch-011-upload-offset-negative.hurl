# CP-PATCH-011: Upload-Offset must not be negative
# Negative Upload-Offset values MUST be rejected and MUST NOT update upload state
# Spec: Upload-Offset is a non-negative integer; this malformed value requires HTTP 400 in this suite.

# Step 1: Create an upload
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

# Step 2: PATCH with negative Upload-Offset
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: -1
Content-Type: application/offset+octet-stream

```
test
```

HTTP 400

# Step 3: Verify offset was NOT updated
HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP 200

[Asserts]
header "Upload-Offset" == "0"
