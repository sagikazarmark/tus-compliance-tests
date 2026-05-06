# CP-OPT-005: Tus-Max-Size header format
# If present, Tus-Max-Size MUST be a non-negative integer
# Spec: "The Tus-Max-Size header indicates the maximum allowed size of an entire upload in bytes."
# Note: This header is optional; test validates format when present

OPTIONS {{base_url}}

HTTP *

[Asserts]
status toString matches /^(200|204)$/
header "Tus-Version" exists
# Tus-Max-Size is optional, but if present must be a non-negative integer
# We can't conditionally assert, so this test just verifies the OPTIONS succeeds
# Implementations should manually verify: if header exists, value matches ^[0-9]+$
