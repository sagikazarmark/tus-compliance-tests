# EXT-TERM-007: Successful DELETE returns Tus-Resumable

# Create upload
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

# Delete the upload
DELETE {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP 204

[Asserts]
header "Tus-Resumable" == "{{tus_version}}"
