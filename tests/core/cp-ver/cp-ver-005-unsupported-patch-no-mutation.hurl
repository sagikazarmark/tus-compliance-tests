# CP-VER-005: Unsupported Tus-Resumable on PATCH does not mutate upload

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 12

HTTP 201
[Captures]
upload_url: header "Location"

PATCH {{upload_url}}
Tus-Resumable: 99.99.99
Upload-Offset: 0
Content-Type: application/offset+octet-stream
```
Hello, tus!
```

HTTP 412
[Asserts]
header "Tus-Version" exists

HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP *
[Asserts]
status toString matches /^(200|204)$/
header "Upload-Offset" == "0"
