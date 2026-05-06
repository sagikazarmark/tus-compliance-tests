# CP-PATCH-004: PATCH requires Upload-Offset
# Missing Upload-Offset header must be rejected without mutating upload state.
# Spec: "The Client MUST send the Upload-Offset header"

# Step 1: Create an upload
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

# Step 2: PATCH without Upload-Offset header must fail; exact status is not specified.
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Content-Type: application/offset+octet-stream

```
test data
```

HTTP *

[Asserts]
status toString matches /^(400|403|415)$/

HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP *

[Asserts]
status toString matches /^(200|204)$/
header "Upload-Offset" == "0"
