# CP-PATCH-001: PATCH requires Tus-Resumable
# Request without Tus-Resumable MUST return 412 Precondition Failed
# Spec: "If the version specified by the Client is not supported by the Server,
#        it MUST respond with the 412 Precondition Failed status"

# Step 1: Create an upload first
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

# Step 2: PATCH without Tus-Resumable header - MUST return 412
# Spec: "The Tus-Resumable header MUST be included in every request and response
#        except for OPTIONS requests."
# Spec: "If the version specified by the Client is not supported by the Server,
#        it MUST respond with the 412 Precondition Failed status and MUST include
#        the Tus-Version header into the response."
PATCH {{upload_url}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
test data
```

HTTP 412

[Asserts]
header "Tus-Version" exists
