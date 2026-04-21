# CP-HEAD-006: HEAD returns Tus-Resumable
# Response MUST include Tus-Resumable header
# Spec: "The Server MUST always include the Tus-Resumable header in the response"

# Step 1: Create an upload
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

# Step 2: HEAD request to verify Tus-Resumable in response
HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP *

[Asserts]
status toString matches /^(200|204)$/
header "Tus-Resumable" exists
header "Tus-Resumable" == "{{tus_version}}"
