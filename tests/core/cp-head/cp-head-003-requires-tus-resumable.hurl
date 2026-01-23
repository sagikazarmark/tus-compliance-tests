# CP-HEAD-003: HEAD requires Tus-Resumable
# Request without Tus-Resumable MUST return 412 Precondition Failed
# Spec: "If the version specified by the Client is not supported by the Server,
#        it MUST respond with the 412 Precondition Failed status"

# Step 1: Create an upload first
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

# Step 2: HEAD without Tus-Resumable header - MUST return 412
# Spec: "If the version specified by the Client is not supported by the Server,
#        it MUST respond with the 412 Precondition Failed status"
# Missing Tus-Resumable header means no version specified, which is not supported.
HEAD {{upload_url}}

HTTP 412

[Asserts]
header "Tus-Version" exists
