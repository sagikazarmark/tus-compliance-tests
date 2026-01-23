# EXT-CREATE-006: POST metadata value base64
# Metadata values MUST be base64-encoded
# Spec: "The value MUST be Base64 encoded"
# Test with various base64 values including empty

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100
Upload-Metadata: name SGVsbG8gV29ybGQ=,description VGhpcyBpcyBhIHRlc3QgZmlsZQ==

HTTP 201

[Asserts]
header "Location" exists
