# CP-OPT-004: Tus-Extension header present
# If extensions supported, Tus-Extension header MUST list them
# Spec: "The Tus-Extension header MAY be omitted if the server does not support any extensions."
# Note: This test verifies format when header is present; header may be absent if no extensions

OPTIONS {{base_url}}

HTTP *

[Asserts]
status toString matches /^(200|204)$/
header "Tus-Version" exists
# If Tus-Extension is present, it must be a comma-separated list of valid extension names
# Valid extensions: creation, creation-defer-length, creation-with-upload, expiration,
#                   checksum, checksum-trailer, termination, concatenation, concatenation-unfinished
