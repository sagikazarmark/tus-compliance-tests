# EXT-TERM-002: DELETE requires Tus-Resumable
# DELETE without Tus-Resumable must be rejected.
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

HTTP 412
