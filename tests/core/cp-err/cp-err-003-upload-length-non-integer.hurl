# CP-ERR-003: Upload-Length must be a non-negative integer
# Spec: invalid Upload-Length grammar is a malformed creation request and requires HTTP 400 in this suite.

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: abc

HTTP 400
