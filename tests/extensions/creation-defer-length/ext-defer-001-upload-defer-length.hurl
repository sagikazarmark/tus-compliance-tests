# EXT-DEFER-001: POST with Upload-Defer-Length
# POST with Upload-Defer-Length: 1 MUST succeed without Upload-Length
# Spec: "If the Upload-Defer-Length header is used, the Client MUST NOT include
#        the Upload-Length header in the creation request"

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Defer-Length: 1

HTTP 201

[Asserts]
header "Location" exists
