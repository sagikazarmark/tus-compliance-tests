# EXT-CREATE-014: Upload-Metadata rejects empty keys
# Spec: metadata keys MUST NOT be empty, but servers MAY ignore supplied metadata.
# Strict servers may reject with 400; lenient servers may ignore or normalize it and still create the upload.
# HTTP parsers may strip leading whitespace after the colon, so this is a relaxed parse-ambiguity sentinel.

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100
Upload-Metadata:  dGVzdA==

HTTP *

[Asserts]
status toString matches /^(201|400)$/
