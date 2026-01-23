# EXT-TERM-002: DELETE requires Tus-Resumable
# DELETE without Tus-Resumable MUST return 412 Precondition Failed
# Spec: "If the version specified by the Client is not supported by the Server,
#        it MUST respond with the 412 Precondition Failed status"

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

[Asserts]
header "Tus-Version" exists
