# EXT-CONCAT-010: HEAD on final upload after concatenation returns offset == length
# Spec: "After successful concatenation, the Upload-Offset and Upload-Length
#        MUST be set and their values MUST be equal."
# Spec: "The response to a HEAD request for a final upload SHOULD NOT contain
#        the Upload-Offset header unless the concatenation has been successfully
#        finished."
# Note: this test assumes synchronous concatenation (the norm for tusd, rustus,
# tus-node-server for completed partials). Servers that concatenate asynchronously
# may require a poll loop after 201, which is outside the scope of this test.

# Create and complete a partial (6 bytes: AAAAA + newline)
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 6
Upload-Concat: partial

HTTP 201

[Captures]
partial_url: header "Location"

PATCH {{partial_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
AAAAA
```

HTTP 204

# Create final from the completed partial. Concatenation completes synchronously
# for servers without the concatenation-unfinished extension.
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Concat: final;{{partial_url}}

HTTP 201

[Captures]
final_url: header "Location"

# HEAD on the final upload after concatenation MUST expose both headers, equal.
HEAD {{final_url}}
Tus-Resumable: {{tus_version}}

HTTP *

[Asserts]
status toString matches /^(200|204)$/
header "Upload-Concat" startsWith "final"
header "Upload-Offset" == "6"
header "Upload-Length" == "6"
