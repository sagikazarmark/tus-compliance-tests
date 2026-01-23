# CP-HEAD-004: HEAD Cache-Control header
# Response MUST include Cache-Control: no-store
# Spec: "The Server MUST prevent caching of the response by including
#        Cache-Control: no-store in the response"

# Step 1: Create an upload
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

# Step 2: HEAD request to verify Cache-Control
HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP 200

[Asserts]
header "Cache-Control" exists
header "Cache-Control" contains "no-store"
