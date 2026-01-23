# EXT-CONCAT-003: Final no Upload-Length
# Final upload creation MUST NOT include Upload-Length
# Spec: "The Client MUST NOT include the Upload-Length header in the final upload creation"

# Create and complete partial upload (6 bytes: AAAAA + newline)
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 6
Upload-Concat: partial

HTTP 201

[Captures]
partial_url: header "Location"

PATCH {{partial_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
AAAAA
```

HTTP 204

# Create final WITHOUT Upload-Length (correct behavior)
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Concat: final;{{partial_url}}

HTTP 201

[Asserts]
header "Location" exists
