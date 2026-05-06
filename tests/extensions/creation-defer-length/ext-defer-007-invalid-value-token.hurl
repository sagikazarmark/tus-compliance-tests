# EXT-DEFER-007: Upload-Defer-Length rejects non-integer tokens
# Spec: values other than 1 should be rejected; exact status is not mandatory.

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Defer-Length: true

HTTP *

[Asserts]
status >= 400
status < 500
header "Location" not exists
