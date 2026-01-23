# EXT-DEFER-003: PATCH sets Upload-Length
# First PATCH MAY include Upload-Length to set final size
# Spec: "The Client MUST set the Upload-Length header in the first PATCH request
#        if the length was deferred"

# Create upload with deferred length
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Defer-Length: 1

HTTP 201

[Captures]
upload_url: header "Location"

# PATCH with Upload-Length to set the final size
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Upload-Length: 12
Content-Type: application/offset+octet-stream

```
Hello, tus!
```

HTTP 204

[Asserts]
header "Upload-Offset" == "12"

# Verify length is now set
HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP 200

[Asserts]
header "Upload-Length" == "12"
