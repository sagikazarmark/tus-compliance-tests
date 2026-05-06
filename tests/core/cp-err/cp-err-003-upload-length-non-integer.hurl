# CP-ERR-003: Upload-Length must be a non-negative integer
# Spec: invalid Upload-Length grammar is malformed; exact status is not specified.

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: abc

HTTP *

[Asserts]
status >= 400
status < 500
header "Location" not exists
