# EXT-DEFER-002: HEAD before length known
# HEAD on deferred upload MUST NOT include Upload-Length
# Spec: "As long as the length of the upload is not known, the Server MUST set
#        Upload-Defer-Length: 1 in all responses to HEAD requests"

# Create upload with deferred length
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Defer-Length: 1

HTTP 201

[Captures]
upload_url: header "Location"

# HEAD should show Upload-Defer-Length: 1 and no Upload-Length
HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP *

[Asserts]
status toString matches /^(200|204)$/
header "Upload-Defer-Length" == "1"
header "Upload-Offset" exists
# Upload-Length MUST NOT be sent while the length is still unknown
header "Upload-Length" not exists
