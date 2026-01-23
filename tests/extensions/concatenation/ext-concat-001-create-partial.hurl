# EXT-CONCAT-001: Create partial upload
# POST with Upload-Concat: partial MUST succeed
# Spec: "A partial upload represents a chunk of a file"

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 10
Upload-Concat: partial

HTTP 201

[Asserts]
header "Location" exists
