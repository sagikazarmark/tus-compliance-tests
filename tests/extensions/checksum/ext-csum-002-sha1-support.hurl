# EXT-CSUM-002: SHA1 algorithm support
# Server SHOULD support SHA1 checksum algorithm
# Spec: Recommended algorithms include sha1

OPTIONS {{base_url}}

HTTP 200

[Asserts]
header "Tus-Checksum-Algorithm" exists
header "Tus-Checksum-Algorithm" contains "sha1"
