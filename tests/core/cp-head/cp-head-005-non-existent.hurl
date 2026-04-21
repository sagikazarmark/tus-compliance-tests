# CP-HEAD-005: HEAD on non-existent resource
# SHOULD return 404 Not Found, 410 Gone, or 403 Forbidden
# Spec: "If the resource is not found, the Server SHOULD return either the
#        404 Not Found, 410 Gone or 403 Forbidden status without the Upload-Offset header."

HEAD {{base_url}}/non-existent-upload-id-12345
Tus-Resumable: {{tus_version}}

HTTP *

[Asserts]
status toString matches /^(403|404|410)$/
header "Upload-Offset" not exists
