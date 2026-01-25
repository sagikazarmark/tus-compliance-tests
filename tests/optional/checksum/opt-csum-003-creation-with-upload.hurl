# OPT-CSUM-003: Checksum on creation-with-upload
# Spec: Checksum for POST body?
# Suggested Best Practice: Support Upload-Checksum on POST with body

# POST with body and checksum (requires creation-with-upload extension)
# "Hello, tus!\n" SHA1: E7X121m3do5RTtnrOi5XTG9Uq0A=
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 12
Content-Type: application/offset+octet-stream
Upload-Checksum: sha1 E7X121m3do5RTtnrOi5XTG9Uq0A=

```
Hello, tus!
```

HTTP 201

[Asserts]
header "Location" exists
header "Upload-Offset" == "12"
