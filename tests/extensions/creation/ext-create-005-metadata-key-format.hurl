# EXT-CREATE-005: POST metadata key format
# Metadata keys MUST be ASCII, non-empty, unique
# Spec: "The key SHOULD be ASCII encoded and MUST NOT contain spaces or commas"

# Valid ASCII keys without spaces or commas
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100
Upload-Metadata: filename dGVzdC50eHQ=,content-type dGV4dC9wbGFpbg==,size MTAw

HTTP 201

[Asserts]
header "Location" exists
