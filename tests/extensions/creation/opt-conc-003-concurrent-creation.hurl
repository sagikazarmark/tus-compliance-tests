# OPT-CONC-003: Concurrent upload creation
# Spec: Same file uploaded twice simultaneously
# Suggested Best Practice: Each gets unique upload URL

# Create first upload
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100
Upload-Metadata: filename dGVzdC50eHQ=

HTTP 201

[Captures]
upload_url1: header "Location"

# Create second upload (same metadata)
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100
Upload-Metadata: filename dGVzdC50eHQ=

HTTP 201

[Captures]
upload_url2: header "Location"

# Both uploads should exist independently
HEAD {{upload_url1}}
Tus-Resumable: {{tus_version}}

HTTP 200

HEAD {{upload_url2}}
Tus-Resumable: {{tus_version}}

HTTP 200
