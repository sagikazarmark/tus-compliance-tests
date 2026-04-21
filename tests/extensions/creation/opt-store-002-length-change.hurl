# OPT-STORE-002: Unexpected Upload-Length header on PATCH
# Spec: "Once the length of an upload is known, it MUST NOT be changed."
# The core protocol PATCH request does not define Upload-Length. The spec does not
# mandate a specific error code when a client sends Upload-Length on a PATCH against
# an upload whose length is already fixed.
# Suggested Best Practice: ignore the header or reject the request; servers that
# reject SHOULD use 400 Bad Request.
# This test is lenient: it accepts either silent-ignore (204) or rejection (4xx).

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

# PATCH with Upload-Length header attempting to redeclare size
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Upload-Length: 200
Content-Type: application/offset+octet-stream

```
test
```

HTTP *

[Asserts]
# Accept either: server ignored the unexpected header (204) or rejected it (4xx).
status toString matches /^(204|4[0-9]{2})$/

# Regardless of how the server handled the PATCH, the stored Upload-Length MUST NOT change.
HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP *

[Asserts]
status toString matches /^(200|204)$/
header "Upload-Length" == "100"
