# EXT-TERM-002: DELETE requires Tus-Resumable
# DELETE without Tus-Resumable must be rejected without deleting the upload; exact status is not specified.
# Spec: "The Tus-Resumable header MUST be included in every request and response
#        except for OPTIONS requests."

# Create upload
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

# Delete without Tus-Resumable - should fail
DELETE {{upload_url}}

HTTP *

[Asserts]
status toString matches /^(400|412)$/

HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP *

[Asserts]
status toString matches /^(200|204)$/
