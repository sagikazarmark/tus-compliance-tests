# EXT-CSUM-TR-002: Checksum trailer requires chunked encoding
# HTTP trailers can only be used with chunked transfer encoding
# Spec: "HTTP trailers can only be sent when using chunked transfer encoding"
# Note: Hurl may not support sending HTTP trailers - this test verifies extension is advertised

OPTIONS {{base_url}}

HTTP 200

[Asserts]
header "Tus-Extension" contains "checksum-trailer"
