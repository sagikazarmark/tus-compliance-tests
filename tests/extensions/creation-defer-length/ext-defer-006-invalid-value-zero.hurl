# EXT-DEFER-006: Upload-Defer-Length only accepts 1
# Spec: values other than 1 should be rejected; exact status is not mandatory.

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Defer-Length: 0

HTTP *

[Asserts]
status >= 400
status < 500
header "Location" not exists
