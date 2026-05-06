# CP-OPT-006: OPTIONS ignores Tus-Resumable when present
# Server MUST ignore Tus-Resumable on OPTIONS, even if the value is unsupported.

OPTIONS {{base_url}}
Tus-Resumable: 99.99.99

HTTP *
[Asserts]
status toString matches /^(200|204)$/
header "Tus-Version" exists
