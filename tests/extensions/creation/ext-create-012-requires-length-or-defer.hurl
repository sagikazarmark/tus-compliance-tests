# EXT-CREATE-012: Creation requires Upload-Length or Upload-Defer-Length
# Spec: creation requests must include either Upload-Length or Upload-Defer-Length; missing both is malformed and requires HTTP 400 in this suite.

POST {{base_url}}
Tus-Resumable: {{tus_version}}

HTTP 400
