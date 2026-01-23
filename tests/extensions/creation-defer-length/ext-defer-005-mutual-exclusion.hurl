# EXT-DEFER-005: Defer and Length mutual exclusion
# POST with both Upload-Defer-Length and Upload-Length MUST be rejected
# Spec: "If the Upload-Defer-Length header is used, the Client MUST NOT include
#        the Upload-Length header in the creation request"

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Defer-Length: 1
Upload-Length: 100

HTTP 400
