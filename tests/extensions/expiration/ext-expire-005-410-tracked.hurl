# EXT-EXPIRE-005: 410 for tracked expirations
# If server tracks expired uploads, SHOULD return 410 Gone
# Spec: "If the Server is keeping track of expired uploads, it SHOULD use 410 Gone"
# Note: This is a documentation test - 410 vs 404 depends on server implementation

# Create upload
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

# Note: To test this:
# 1. Configure server with short expiration
# 2. Wait for expiration
# 3. Access the resource
# Expected: 410 Gone if server tracks expirations, otherwise 404 Not Found

# Verify upload exists for now
HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP 200
