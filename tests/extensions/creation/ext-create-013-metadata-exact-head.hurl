# EXT-CREATE-013: HEAD echoes Upload-Metadata exactly
# Spec: HEAD responses for uploads with metadata MUST include Upload-Metadata with the value specified during creation.

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100
Upload-Metadata: filename dGVzdC50eHQ=,filetype dGV4dC9wbGFpbg==

HTTP 201

[Captures]
upload_url: header "Location"

HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP *

[Asserts]
status toString matches /^(200|204)$/
header "Upload-Metadata" == "filename dGVzdC50eHQ=,filetype dGV4dC9wbGFpbg=="
