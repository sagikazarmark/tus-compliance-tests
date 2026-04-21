# EXT-CONCAT-008: Invalid partial URL rejected
# Non-existent partial URL in final MUST be rejected
# Spec: server MUST reject creation of a final upload referencing a missing partial.
# The specific status is not mandated; 400 Bad Request and 404 Not Found are both
# commonly observed and spec-compatible.

# Attempt to create final with non-existent partial URL
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Concat: final;{{base_url}}/non-existent-partial-12345

HTTP *

[Asserts]
status toString matches /^(400|404)$/
