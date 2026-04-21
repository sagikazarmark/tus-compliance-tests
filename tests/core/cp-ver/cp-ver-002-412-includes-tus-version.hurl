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

# Step 2: Request with unsupported version - MUST return 412 with Tus-Version
# Spec: "If the version specified by the Client is not supported by the Server,
#        it MUST respond with the 412 Precondition Failed status and MUST include
#        the Tus-Version header into the response."
HEAD {{upload_url}}
Tus-Resumable: 0.0.1

HTTP 412

[Asserts]
header "Tus-Version" exists
header "Tus-Version" contains "1.0.0"
