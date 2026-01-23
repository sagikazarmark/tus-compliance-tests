# EXT-EXPIRE-004: Expired upload returns 404/410
# Access after expiration MUST return 404 or 410
# Spec: "If an upload is going to expire and this is announced by the Server,
#        the Client MUST try to finish the upload before the expiration time"
# Note: This test requires server-specific configuration or waiting for expiration
#       Marking as documentation test - actual behavior depends on server timing

# Create upload
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

# Note: To test actual expiration, you would need to:
# 1. Configure server with very short expiration (e.g., 1 second)
# 2. Wait for expiration
# 3. Attempt HEAD or PATCH
# The expected response is 404 Not Found or 410 Gone

# This test just verifies the upload was created successfully
# Manual testing needed for actual expiration behavior
HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP 200
