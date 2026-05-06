# EXT-CREATE-012: Creation requires Upload-Length or Upload-Defer-Length
# Spec: creation requests must include either Upload-Length or Upload-Defer-Length; exact status is not specified.

POST {{base_url}}
Tus-Resumable: {{tus_version}}

HTTP *

[Asserts]
status >= 400
status < 500
header "Location" not exists
