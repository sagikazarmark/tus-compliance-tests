# OPT-CSUM-001: Checksum on empty chunk
# Spec: Doesn't address empty body with checksum
# Suggested Best Practice: Accept; validate checksum of empty data
# SHA1 of empty string: 2jmj7l5rSw0yVb/vlWAYkK/YBwk=

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 0

HTTP 201

[Captures]
upload_url: header "Location"

# Note: Zero-length uploads don't need PATCH
# For servers supporting creation-with-upload, empty body with checksum could be:
# POST with Content-Length: 0 and Upload-Checksum for empty content

HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP 200

[Asserts]
header "Upload-Offset" == "0"
