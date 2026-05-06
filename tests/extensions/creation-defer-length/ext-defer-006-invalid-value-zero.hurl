# EXT-DEFER-006: Upload-Defer-Length only accepts 1
# Spec: Upload-Defer-Length MAY be set to 1; any other value is malformed and requires HTTP 400 in this suite.

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Defer-Length: 0

HTTP 400
