# CP-HEAD-005: HEAD on non-existent resource
# MUST return 404 Not Found
# Spec: "If the resource is not found, the Server SHOULD return 404 Not Found"

HEAD {{base_url}}/non-existent-upload-id-12345
Tus-Resumable: {{tus_version}}

HTTP 404
