# OPT-CONC-001: Concurrent PATCH requests
# Spec: No concurrency requirements specified
# Suggested Best Practice: Serialize writes; second request gets 409 or waits
# Note: True concurrency testing requires external tooling; this documents expected behavior

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

# First PATCH
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
first chunk
```

HTTP 204

# Sequential PATCH (not truly concurrent, but validates offset handling)
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 12
Content-Type: application/offset+octet-stream

```
second chunk
```

HTTP 204
