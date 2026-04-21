# EXT-CONCAT-003: Final without Upload-Length; final with Upload-Length is rejected
# Final upload creation MUST NOT include Upload-Length
# Spec: "The Client MUST NOT include the Upload-Length header in the final upload creation"

# Create and complete partial upload (6 bytes: AAAAA + newline)
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

# Positive case: create final WITHOUT Upload-Length - MUST succeed.
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Concat: final;{{partial_url}}

HTTP 201

[Asserts]
header "Location" exists

# Set up a fresh partial for the negative case — some servers delete partials
# after a successful concatenation, so the earlier partial may no longer be valid.
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 6
Upload-Concat: partial

HTTP 201

[Captures]
partial2_url: header "Location"

PATCH {{partial2_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
BBBBB
```

HTTP 204

# Negative case: create final WITH Upload-Length - MUST be rejected.
# The spec does not mandate a specific status; 400 Bad Request is the common choice.
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Concat: final;{{partial2_url}}
Upload-Length: 6

HTTP *

[Asserts]
status toString matches /^4[0-9]{2}$/
