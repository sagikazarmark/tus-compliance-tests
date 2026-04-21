# EXT-TERM-003: Deleted resource returns 404/410
# Subsequent HEAD/PATCH MUST return 404 or 410
# Spec: "Subsequent requests to the URL SHOULD return 404 Not Found or 410 Gone"

# Create upload
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

# Delete the upload
DELETE {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP 204

# Subsequent HEAD should return 404 or 410
HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP *

[Asserts]
status toString matches /^(404|410)$/
