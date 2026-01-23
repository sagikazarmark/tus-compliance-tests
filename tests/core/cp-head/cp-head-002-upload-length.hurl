# CP-HEAD-002: HEAD returns Upload-Length
# Response MUST include Upload-Length if known
# Spec: "The Server MUST include the Upload-Length header in the response if the length is known"

# Step 1: Create an upload with known length
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

# Step 2: HEAD request to verify Upload-Length
HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP 200

[Asserts]
header "Upload-Length" exists
header "Upload-Length" == "100"
