# SCN-BASIC-004: Zero-byte upload
# Create upload with Upload-Length: 0, verify immediate completion

# Step 1: Create zero-length upload
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 0

HTTP 201

[Captures]
upload_url: header "Location"

# Step 2: Verify immediate completion (no PATCH needed)
HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP 200

[Asserts]
header "Upload-Offset" == "0"
header "Upload-Length" == "0"
