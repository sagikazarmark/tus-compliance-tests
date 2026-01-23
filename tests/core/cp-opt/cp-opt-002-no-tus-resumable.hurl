# CP-OPT-002: OPTIONS without Tus-Resumable header
# Server MUST NOT require Tus-Resumable header on OPTIONS requests
# Spec: "The Client SHOULD NOT include the Tus-Resumable header in the request"

OPTIONS {{base_url}}

HTTP 200

[Asserts]
header "Tus-Version" exists
