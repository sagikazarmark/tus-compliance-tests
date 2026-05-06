# EXT-DEFER-007: Upload-Defer-Length rejects non-integer tokens
# Spec: Upload-Defer-Length MAY be set to 1; non-integer values are malformed and require HTTP 400 in this suite.

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Defer-Length: true

HTTP 400
