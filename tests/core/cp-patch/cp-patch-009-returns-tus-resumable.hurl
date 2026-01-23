# CP-PATCH-009: PATCH returns Tus-Resumable
# Response MUST include Tus-Resumable header
# Spec: "The Server MUST always include the Tus-Resumable header in the response"

# Step 1: Create an upload
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 12

HTTP 201

[Captures]
upload_url: header "Location"

# Step 2: PATCH and verify Tus-Resumable in response
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
Hello, tus!
```

HTTP 204

[Asserts]
header "Tus-Resumable" exists
header "Tus-Resumable" == "{{tus_version}}"
