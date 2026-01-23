# EXT-CONCAT-006: HEAD on final returns concat info
# HEAD on final MUST include Upload-Concat header
# Spec: "HEAD requests for a final upload MUST include the Upload-Concat header"

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

# Create final
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Concat: final;{{partial_url}}

HTTP 201

[Captures]
final_url: header "Location"

# HEAD on final should include Upload-Concat
HEAD {{final_url}}
Tus-Resumable: {{tus_version}}

HTTP 200

[Asserts]
header "Upload-Concat" exists
header "Upload-Concat" startsWith "final"
