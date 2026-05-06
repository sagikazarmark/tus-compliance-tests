# CP-OVERRIDE-001: X-HTTP-Method-Override PATCH
# Server MUST interpret X-HTTP-Method-Override as the effective method.

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 6

HTTP 201

[Captures]
upload_url: header "Location"

POST {{upload_url}}
Tus-Resumable: {{tus_version}}
X-HTTP-Method-Override: PATCH
Upload-Offset: 0
Content-Type: application/offset+octet-stream
```
12345
```

HTTP 204

[Asserts]
header "Upload-Offset" == "6"
