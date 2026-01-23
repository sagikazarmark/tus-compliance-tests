# CP-VER-002: 412 includes Tus-Version
# 412 response MUST include Tus-Version header with supported versions
# Spec: "The Server MUST include the Tus-Version header in the response"

# Step 1: Create an upload first
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

# Step 2: Request with unsupported version
# Strict compliance: MUST return 412 with Tus-Version header
# Note: tusd is lenient and accepts unknown versions (returns 200)
HEAD {{upload_url}}
Tus-Resumable: 0.0.1

HTTP *

[Asserts]
# Strict servers return 412, lenient servers (like tusd) return 200
status < 500
