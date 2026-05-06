# CP-OPT-002: OPTIONS without Tus-Resumable header
# Server MUST NOT require Tus-Resumable header on OPTIONS requests
# Spec: "The Client SHOULD NOT include the Tus-Resumable header in the request"

OPTIONS {{base_url}}

HTTP *

[Asserts]
status toString matches /^(200|204)$/
header "Tus-Version" exists
