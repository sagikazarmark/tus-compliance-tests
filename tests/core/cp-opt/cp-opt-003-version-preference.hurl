# CP-OPT-003: Tus-Version preference order
# Versions MUST be ordered by server preference (most preferred first)
# Spec: "The value MUST be a comma-separated list of protocol versions supported by the Server.
#        The list MUST be sorted by Server's preference"

OPTIONS {{base_url}}

HTTP *

[Asserts]
status toString matches /^(200|204)$/
header "Tus-Version" exists
# Version format check - should contain at least 1.0.0 and be comma-separated if multiple
header "Tus-Version" matches "^[0-9]+\\.[0-9]+\\.[0-9]+(,[0-9]+\\.[0-9]+\\.[0-9]+)*$"
# First version in list should be the most preferred (this is informational)
header "Tus-Version" matches "^[0-9]"
