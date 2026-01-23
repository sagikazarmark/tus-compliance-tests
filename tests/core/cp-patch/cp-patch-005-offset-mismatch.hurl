# CP-PATCH-005: PATCH offset mismatch
# Mismatched offset MUST return 409 Conflict
# Spec: "If the offsets do not match, the Server MUST respond with
#        the 409 Conflict status without modifying the upload resource"

# Step 1: Create an upload
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

# Step 2: PATCH with wrong offset (server has 0, client claims 50)
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 50
Content-Type: application/offset+octet-stream

```
test data
```

HTTP 409
