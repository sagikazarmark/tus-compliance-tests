# EXT-TERM-004: DELETE non-existent resource
# DELETE on missing resource MUST return 404
# Spec: "If the resource is not found, the Server SHOULD return 404 Not Found"

DELETE {{base_url}}/non-existent-upload-id-99999
Tus-Resumable: {{tus_version}}

HTTP 404
