# OPT-META-003: Empty metadata value
# Spec: "The value MAY be empty." HTTP header transport strips trailing whitespace,
# so a bare key (no space, no value) is the practical form for expressing an
# empty-value entry. Strict parsers may still reject without the separator.

# Bare key, no value.
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100
Upload-Metadata: emptykey

HTTP *

[Asserts]
# Accept lenient (201) or strict rejection (400). Other codes indicate a bug.
status toString matches /^(201|400)$/

# Mixed form: one populated key and one empty-value key in the same header.
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100
Upload-Metadata: filename dGVzdA==,emptykey

HTTP *

[Asserts]
status toString matches /^(201|400)$/
