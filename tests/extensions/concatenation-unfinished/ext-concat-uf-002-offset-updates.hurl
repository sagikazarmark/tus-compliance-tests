# EXT-CONCAT-UF-002: Final offset updates
# Final Upload-Offset MUST update as partials complete
# Spec: "As the partial uploads are completed, the final upload's Upload-Offset will be updated"

# Create partial with 100 byte length
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100
Upload-Concat: partial

HTTP 201

[Captures]
partial_url: header "Location"

# Upload first 11 bytes (0123456789 + newline)
PATCH {{partial_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
0123456789
```

HTTP 204

# Create final with incomplete partial
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Concat: final;{{partial_url}}

HTTP 201

[Captures]
final_url: header "Location"

# Check final offset (should be 11, partial progress)
HEAD {{final_url}}
Tus-Resumable: {{tus_version}}

HTTP 200

[Asserts]
header "Upload-Offset" == "11"

# Continue uploading to partial
PATCH {{partial_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 11
Content-Type: application/offset+octet-stream

```
0123456789
```

HTTP 204

# Check final offset again (should be 22 now)
HEAD {{final_url}}
Tus-Resumable: {{tus_version}}

HTTP 200

[Asserts]
header "Upload-Offset" == "22"
