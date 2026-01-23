# EXT-CONCAT-008: Invalid partial URL rejected
# Non-existent partial URL in final MUST be rejected
# Spec: "The Server MUST respond with 400 Bad Request if one or more of the partial
#        uploads can not be found"

# Attempt to create final with non-existent partial URL
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Concat: final;{{base_url}}/non-existent-partial-12345

HTTP 400
