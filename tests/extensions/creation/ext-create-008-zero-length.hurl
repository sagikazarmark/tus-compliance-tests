# EXT-CREATE-008: POST zero-length upload
# Upload-Length: 0 MUST be accepted (empty file)
# Spec: Server must accept creation of zero-length uploads

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 0

HTTP 201

[Captures]
upload_url: header "Location"

# Verify the upload is immediately complete
HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP 200

[Asserts]
header "Upload-Offset" == "0"
header "Upload-Length" == "0"
