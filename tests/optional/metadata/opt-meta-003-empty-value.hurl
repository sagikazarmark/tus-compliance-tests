# OPT-META-003: Empty metadata value
# Spec: Allows empty values but behavior unclear
# Suggested Best Practice: Accept empty base64-encoded values (key without value)

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100
Upload-Metadata: emptykey

HTTP 201

[Asserts]
header "Location" exists
