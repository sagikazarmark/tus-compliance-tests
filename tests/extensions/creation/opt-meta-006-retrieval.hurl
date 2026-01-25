# OPT-META-006: Metadata retrieval
# Spec: Doesn't require returning metadata on HEAD
# Suggested Best Practice: Return Upload-Metadata on HEAD for debugging

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100
Upload-Metadata: filename dGVzdC50eHQ=,contenttype dGV4dC9wbGFpbg==

HTTP 201

[Captures]
upload_url: header "Location"

# Check if server returns metadata on HEAD (optional but useful)
HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP 200

# Upload-Metadata on HEAD is optional but helpful for debugging
# Best practice is to include it in the response
