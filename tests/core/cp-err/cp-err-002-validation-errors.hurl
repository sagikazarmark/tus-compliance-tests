# OPT-ERR-003: Detailed validation errors
# Spec: No structure for validation messages
# Suggested Best Practice: Include specific field/header that failed validation

# Create request with multiple issues
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: -1

HTTP 400

# Note: Best practice is to include which header/field failed validation
# Example response body: {"error": "Invalid Upload-Length", "field": "Upload-Length"}
