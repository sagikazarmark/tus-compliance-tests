# EXT-CREATE-003: POST requires Tus-Resumable
# POST without Tus-Resumable MUST return 412 Precondition Failed
# Spec: "If the version specified by the Client is not supported by the Server,
#        it MUST respond with the 412 Precondition Failed status"

POST {{base_url}}
Upload-Length: 100

HTTP 412

[Asserts]
header "Tus-Version" exists
