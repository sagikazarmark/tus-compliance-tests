# EXT-CREATE-011: Successful POST returns Tus-Resumable

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Asserts]
header "Tus-Resumable" == "{{tus_version}}"
