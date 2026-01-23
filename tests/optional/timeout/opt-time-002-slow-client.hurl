# OPT-TIME-002: Slow client handling
# Spec: No minimum transfer rate specified
# Suggested Best Practice: Allow configurable minimum rate or timeout
# Note: Slow client simulation requires external tooling

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

# Normal speed upload (baseline)
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
test data
```

HTTP 204

# Note: To test slow client handling:
# 1. Configure server with minimum transfer rate
# 2. Send data at rate below minimum
# 3. Verify server behavior (timeout vs acceptance)
