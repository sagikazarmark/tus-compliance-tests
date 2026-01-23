# EXT-TERM-001: DELETE returns 204
# Successful DELETE MUST return 204 No Content
# Spec: "The Server MUST acknowledge a successful request with the 204 No Content status"

# Create upload
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

# Delete the upload
DELETE {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP 204
