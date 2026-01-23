# EXT-CONCAT-UF-001: Final with incomplete partials
# Server MUST accept final creation while partials in progress
# Spec: "When this extension is supported, the Server MUST accept final upload creation
#        even if the partial uploads are not finished yet"

# Create a partial but don't complete it
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100
Upload-Concat: partial

HTTP 201

[Captures]
partial_url: header "Location"

# Upload only some data
PATCH {{partial_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
partial data
```

HTTP 204

# Create final with incomplete partial - should succeed with concatenation-unfinished
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Concat: final;{{partial_url}}

HTTP 201

[Asserts]
header "Location" exists
