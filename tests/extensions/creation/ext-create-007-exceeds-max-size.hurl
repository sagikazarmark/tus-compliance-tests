# EXT-CREATE-007: POST exceeds Tus-Max-Size
# Upload-Length > Tus-Max-Size MUST return 413 Request Entity Too Large
# Spec: "If the length of the upload exceeds the maximum, the Server MUST respond
#        with the 413 Request Entity Too Large status"
# Note: This test assumes Tus-Max-Size is advertised. Skip if server has no size limit.

# First check if server has a max size limit
OPTIONS {{base_url}}

HTTP 200

# If Tus-Max-Size exists, test with a value exceeding it
# Using a very large value that should exceed most limits (1 petabyte)
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 1125899906842624

HTTP 413
