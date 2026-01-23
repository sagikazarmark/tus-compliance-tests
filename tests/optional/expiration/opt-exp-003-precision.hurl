# OPT-EXP-003: Expiration precision
# Spec: Minimum granularity not specified
# Suggested Best Practice: Second-level precision minimum

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP 200

# Note: If Upload-Expires header is present, it should:
# 1. Be in RFC 9110 datetime format
# 2. Have at least second-level precision
# 3. Be in the future
#
# Format: Day, DD Mon YYYY HH:MM:SS GMT
# Example: Sat, 18 Apr 2026 12:31:39 GMT
