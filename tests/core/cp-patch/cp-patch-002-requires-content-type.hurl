# CP-PATCH-002: PATCH requires Content-Type
# Missing Content-Type must be rejected without mutating upload state.
# Spec: "All PATCH requests MUST use Content-Type: application/offset+octet-stream,
#        otherwise the server SHOULD return a 415 Unsupported Media Type status."

# Step 1: Create an upload
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

# Step 2: PATCH without Content-Type must fail; exact status is not mandatory.
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0

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
