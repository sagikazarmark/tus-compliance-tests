# EXT-CREATE-010: HEAD echoes stored Upload-Metadata
# Response to HEAD MUST include the Upload-Metadata as provided at creation
# Spec: "If an upload contains additional metadata, responses to HEAD requests
#        MUST include the Upload-Metadata header and its value as specified by
#        the Client during the creation."
# Note: precondition is that the server stored the metadata. Servers that
# explicitly discard metadata would legitimately omit the header on HEAD,
# though a compliance target should store and echo it.

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100
Upload-Metadata: filename dGVzdC50eHQ=,filetype dGV4dC9wbGFpbg==

HTTP 201

[Captures]
upload_url: header "Location"

HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP *

[Asserts]
status toString matches /^(200|204)$/
header "Upload-Metadata" exists
# Both keys must be present; value ordering is not specified by the spec.
header "Upload-Metadata" contains "filename dGVzdC50eHQ="
header "Upload-Metadata" contains "filetype dGV4dC9wbGFpbg=="
