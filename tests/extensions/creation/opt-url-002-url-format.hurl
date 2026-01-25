# OPT-URL-002: URL format and structure
# Spec: "Left for implementation to decide"
# Suggested Best Practice: Use opaque, non-guessable identifiers

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url1: header "Location"

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url2: header "Location"

# Best practice: URLs should be unique and non-guessable
# The two upload URLs should be different
