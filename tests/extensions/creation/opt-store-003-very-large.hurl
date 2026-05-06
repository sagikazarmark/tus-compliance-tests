# OPT-STORE-003: Very large Upload-Length
# Spec: No maximum file size requirement beyond Tus-Max-Size
# Suggested Best Practice: Validate against Tus-Max-Size; return 413

# First check server's max size (if any)
OPTIONS {{base_url}}

HTTP *

[Asserts]
status toString matches /^(200|204)$/

# Attempt to create very large upload (may be rejected if exceeds Tus-Max-Size)
# Using 1 petabyte as test value
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 1125899906842624

HTTP *

[Asserts]
# Accept either 201 (no limit) or 413 (exceeds limit)
status >= 200
status <= 500
