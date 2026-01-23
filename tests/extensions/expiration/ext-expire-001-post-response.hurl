# EXT-EXPIRE-001: Upload-Expires in POST response
# Creation response SHOULD include Upload-Expires header
# Spec: "The Server MAY add the Upload-Expires header to indicate when the upload expires"

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Asserts]
header "Location" exists
# Upload-Expires is optional but if present must be valid datetime format
