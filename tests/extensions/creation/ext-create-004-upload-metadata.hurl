# EXT-CREATE-004: POST with Upload-Metadata
# Server MUST accept valid Upload-Metadata header
# Spec: "The Client MAY supply the Upload-Metadata header to add additional metadata"
# Format: key base64value,key2 base64value2

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100
Upload-Metadata: filename dGVzdC50eHQ=,filetype dGV4dC9wbGFpbg==

HTTP 201

[Asserts]
header "Location" exists
