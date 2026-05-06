# EXT-CONCAT-005: PATCH on final forbidden
# PATCH on final upload MUST return 403 Forbidden
# Spec: "The Client MUST NOT send PATCH requests for final uploads"

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

# Attempt to PATCH the final upload - should be forbidden
PATCH {{final_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
data
```

HTTP 403

# Final and partial offsets should remain unchanged after the forbidden PATCH.
HEAD {{final_url}}
Tus-Resumable: {{tus_version}}

HTTP *

[Asserts]
status toString matches /^(200|204)$/
header "Upload-Offset" == "6"
header "Upload-Length" == "6"

HEAD {{partial_url}}
Tus-Resumable: {{tus_version}}

HTTP *

[Asserts]
status toString matches /^(200|204)$/
header "Upload-Offset" == "6"
