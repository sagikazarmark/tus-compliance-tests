# EXT-CONCAT-007: Partial uploads must be complete
# Final creation with incomplete partials MUST fail (unless concatenation-unfinished)
# Spec: "The Server MUST respond with 400 Bad Request if one or more of the partial
#        uploads are not finished"

# Create a partial but don't complete it
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100
Upload-Concat: partial

HTTP 201

[Captures]
incomplete_partial_url: header "Location"

# Only upload partial data (10 of 100 bytes)
PATCH {{incomplete_partial_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
some data!
```

HTTP 204

# Attempt to create final with incomplete partial - should fail
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Concat: final;{{incomplete_partial_url}}

HTTP 400
