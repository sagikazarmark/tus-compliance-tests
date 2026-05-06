# CP-PATCH-012: Upload-Offset must be an integer
# Non-integer Upload-Offset values MUST be rejected and MUST NOT update upload state
# Spec: Upload-Offset is a non-negative integer; exact malformed-header status is not specified.

# Step 1: Create an upload
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

# Step 2: PATCH with non-integer Upload-Offset
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: abc
Content-Type: application/offset+octet-stream

```
test
```

HTTP *

[Asserts]
status >= 400
status < 500

# Step 3: Verify offset was NOT updated
HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP 200

[Asserts]
header "Upload-Offset" == "0"
