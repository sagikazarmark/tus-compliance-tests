# EXT-CREATE-002: POST returns Location
# 201 response MUST include Location header with upload URL
# Spec: "The Server MUST set the Location header to the URL of the created resource"

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Asserts]
header "Location" exists
header "Location" matches "^https?://.+$"
