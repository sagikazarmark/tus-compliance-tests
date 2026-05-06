# EXT-CONCAT-012: Final upload does not inherit partial metadata
# Spec: Upload-Metadata is supplied during upload creation; final upload metadata
#       is independent from metadata supplied on partial uploads.

# Create and complete a partial with metadata (6 bytes: AAAAA + newline)
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 6
Upload-Concat: partial
Upload-Metadata: filename cGFydGlhbC50eHQ=

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

# Create final without metadata.
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Concat: final;{{partial_url}}

HTTP 201

[Captures]
final_url: header "Location"

# HEAD on final must not include metadata inherited from the partial upload.
HEAD {{final_url}}
Tus-Resumable: {{tus_version}}

HTTP *

[Asserts]
status toString matches /^(200|204)$/
header "Upload-Metadata" not exists
