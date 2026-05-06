# EXT-CONCAT-011: HEAD on final upload returns exact Upload-Concat value
# Spec: "Response to HEAD request against partial or final upload MUST include
#        the Upload-Concat header and its value as received in the upload
#        creation request."

# Create and complete a partial (6 bytes: AAAAA + newline)
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

# Create final from the completed partial.
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Concat: final;{{partial_url}}

HTTP 201

[Captures]
final_url: header "Location"

# HEAD on final MUST echo the exact Upload-Concat value from creation.
HEAD {{final_url}}
Tus-Resumable: {{tus_version}}

HTTP *

[Asserts]
status toString matches /^(200|204)$/
header "Upload-Concat" == "final;{{partial_url}}"
