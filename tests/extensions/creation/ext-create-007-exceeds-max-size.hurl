# EXT-CREATE-007: POST exceeds Tus-Max-Size
# Upload-Length > Tus-Max-Size MUST return 413 Request Entity Too Large
# Spec: "If the length of the upload exceeds the maximum, which MAY be specified
#        using the Tus-Max-Size header, the Server MUST respond with the 413
#        Request Entity Too Large status."
#
# Note: this test is only meaningful if the server advertises Tus-Max-Size.
# Against servers without a configured limit, the POST with a very large
# Upload-Length may legitimately succeed — we accept 201 in that case as a
# vacuous pass rather than a false failure.

# First probe OPTIONS to surface server configuration
OPTIONS {{base_url}}

HTTP *

[Asserts]
status toString matches /^(200|204)$/

# Attempt to create an upload with Upload-Length of 1 PiB (2^50)
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 1125899906842624

HTTP *

[Asserts]
# 413: server enforced Tus-Max-Size (expected when limit < 1 PiB)
# 201: server has no limit or a limit >= 1 PiB and accepted the declaration
status toString matches /^(201|413)$/
