# EXT-CSUM-002: SHA1 algorithm support
# Server MUST support SHA1 checksum algorithm
# Spec: "The Server MUST support at least the SHA1 checksum algorithm
#        identified by sha1 to allow for a minimum of compatibility."

OPTIONS {{base_url}}

HTTP 200

[Asserts]
header "Tus-Checksum-Algorithm" exists
header "Tus-Checksum-Algorithm" contains "sha1"
