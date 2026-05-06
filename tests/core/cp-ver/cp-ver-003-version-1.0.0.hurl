# CP-VER-003: Version 1.0.0 supported
# Server MUST support version 1.0.0
# Spec: This test validates that the server correctly handles Tus-Resumable: 1.0.0

# Verify OPTIONS responds with version 1.0.0 in supported versions
OPTIONS {{base_url}}

HTTP *

[Asserts]
status toString matches /^(200|204)$/
header "Tus-Version" exists
header "Tus-Version" contains "1.0.0"
