# OPT-URL-003: Cross-origin Location
# Spec: No CORS requirements specified
# Suggested Best Practice: Support CORS headers if serving web clients

OPTIONS {{base_url}}

HTTP 200

# CORS headers are optional but recommended for web client support
# If present, should include:
# - Access-Control-Allow-Origin
# - Access-Control-Allow-Methods
# - Access-Control-Allow-Headers
# - Access-Control-Expose-Headers
