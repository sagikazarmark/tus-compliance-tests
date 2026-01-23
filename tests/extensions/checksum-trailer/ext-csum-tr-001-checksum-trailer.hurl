# EXT-CSUM-TR-001: Checksum-trailer extension advertised
# Server MUST advertise checksum-trailer in Tus-Extension if supported
# Spec: "The Client MAY include the checksum as a trailer"

OPTIONS {{base_url}}

HTTP 200

[Asserts]
header "Tus-Extension" contains "checksum-trailer"
