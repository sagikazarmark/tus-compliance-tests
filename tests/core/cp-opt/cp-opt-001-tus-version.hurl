# CP-OPT-001: OPTIONS returns Tus-Version
# Server MUST return Tus-Version header with comma-separated versions
# Spec: "The Server MUST always include the Tus-Version header."

OPTIONS {{base_url}}

HTTP 200

[Asserts]
header "Tus-Version" exists
header "Tus-Version" matches "^[0-9]+\\.[0-9]+\\.[0-9]+(,[0-9]+\\.[0-9]+\\.[0-9]+)*$"
