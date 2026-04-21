# EXT-CONCAT-009: HEAD on partial upload returns Upload-Concat
# Spec: "Response to HEAD request against partial or final upload MUST include
#        the Upload-Concat header and its value as received in the upload
#        creation request."

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 6
Upload-Concat: partial

HTTP 201

[Captures]
partial_url: header "Location"

HEAD {{partial_url}}
Tus-Resumable: {{tus_version}}

HTTP *

[Asserts]
status toString matches /^(200|204)$/
header "Upload-Concat" == "partial"
