# OPT-URL-001: Location header form (absolute vs relative)
# Spec: does not mandate absolute URLs; both forms are valid.
# Best Practice (informational): returning absolute URLs maximises client compatibility.
# This test only verifies Location exists; servers returning relative URLs are still compliant.

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Asserts]
header "Location" exists
