# CP-VER-001: Unsupported version rejected
# Unknown Tus-Resumable version MUST return 412 Precondition Failed
# Spec: "If the version specified by the Client is not supported by the Server,
#        it MUST respond with the 412 Precondition Failed status"

# Step 1: Create an upload first (need valid upload to test against)
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

# Step 2: HEAD with unsupported version - MUST return 412
# Spec: "If the version specified by the Client is not supported by the Server,
#        it MUST respond with the 412 Precondition Failed status"
HEAD {{upload_url}}
Tus-Resumable: 99.99.99

HTTP 412

[Asserts]
header "Tus-Version" exists
