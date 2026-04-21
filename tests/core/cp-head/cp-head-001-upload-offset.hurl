# CP-HEAD-001: HEAD returns Upload-Offset
# Response MUST include Upload-Offset header
# Spec: "The Server MUST always include the Upload-Offset header in the response"
# Prerequisite: Requires creation extension to create an upload first

# Step 1: Create an upload
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

# Step 2: HEAD request to verify Upload-Offset
HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP *

[Asserts]
status toString matches /^(200|204)$/
header "Upload-Offset" exists
header "Upload-Offset" matches "^[0-9]+$"
