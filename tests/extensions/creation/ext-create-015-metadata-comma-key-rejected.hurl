# EXT-CREATE-015: Upload-Metadata rejects comma in keys
# Spec: metadata keys MUST NOT contain commas, but comma is also the pair separator.
# Strict servers may reject malformed metadata with 400; lenient servers may parse or ignore it and still create the upload.
# This intentionally stays relaxed because `bad,key dGVzdA==` can be parsed as two metadata pairs over HTTP.

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100
Upload-Metadata: bad,key dGVzdA==

HTTP *

[Asserts]
status toString matches /^(201|400)$/
