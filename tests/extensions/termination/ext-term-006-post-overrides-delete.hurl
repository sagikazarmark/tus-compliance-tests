# EXT-TERM-006: X-HTTP-Method-Override DELETE
# Termination implementations MUST honor method override for DELETE.

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

POST {{upload_url}}
Tus-Resumable: {{tus_version}}
X-HTTP-Method-Override: DELETE

HTTP 204

HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP *
[Asserts]
status toString matches /^(404|410)$/
