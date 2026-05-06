# CP-PATCH-001: PATCH requires Tus-Resumable
# Request without Tus-Resumable must be rejected without mutating upload state.
# Spec: "The Tus-Resumable header MUST be included in every request and response
#        except for OPTIONS requests."

# Step 1: Create an upload first
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

# Step 2: PATCH without Tus-Resumable header must be rejected.
# Spec: "The Tus-Resumable header MUST be included in every request and response
#        except for OPTIONS requests."
PATCH {{upload_url}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
test data
```

HTTP 412

HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP *

[Asserts]
status toString matches /^(200|204)$/
header "Upload-Offset" == "0"
