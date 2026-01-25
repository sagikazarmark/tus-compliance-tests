# OPT-URL-001: Relative Location header
# Spec: Doesn't mandate absolute URLs
# Suggested Best Practice: Always return absolute URLs for client compatibility

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Asserts]
header "Location" exists
# Best practice: Location should be absolute URL starting with http/https
header "Location" matches "^https?://"
