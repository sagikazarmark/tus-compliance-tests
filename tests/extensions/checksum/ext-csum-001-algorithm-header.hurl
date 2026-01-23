# EXT-CSUM-001: Tus-Checksum-Algorithm header
# OPTIONS MUST include Tus-Checksum-Algorithm with supported algorithms
# Spec: "The Server MUST include the Tus-Checksum-Algorithm header in OPTIONS response"

OPTIONS {{base_url}}

HTTP 200

[Asserts]
header "Tus-Checksum-Algorithm" exists
# Should be comma-separated list of algorithm names (e.g., "sha1,md5,crc32")
header "Tus-Checksum-Algorithm" matches "^[a-z0-9-]+(,[a-z0-9-]+)*$"
