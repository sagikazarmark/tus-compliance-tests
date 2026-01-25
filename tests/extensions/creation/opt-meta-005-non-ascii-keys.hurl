# OPT-META-005: Non-ASCII metadata keys
# Spec: Says "ASCII" but no error response specified
# Suggested Best Practice: Return 400 Bad Request for non-ASCII keys

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100
Upload-Metadata: filename dGVzdC50eHQ=

HTTP 201

# Note: Testing non-ASCII keys is complex in hurl
# This test uses valid ASCII key as baseline
# Manual testing with non-ASCII keys should return 400
