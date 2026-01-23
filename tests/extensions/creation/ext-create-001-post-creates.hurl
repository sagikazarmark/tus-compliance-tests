# EXT-CREATE-001: POST creates upload
# POST with Upload-Length MUST return 201 Created
# Spec: "The Server MUST acknowledge a successful upload creation with the 201 Created status"

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201
