# EXT-CREATE-009: Location URL is absolute
# Location header MUST be an absolute URL or resolvable
# Spec: "The value MUST be a absolute URL"

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Asserts]
header "Location" exists
# Absolute URL must start with http:// or https://
header "Location" matches "^https?://"
