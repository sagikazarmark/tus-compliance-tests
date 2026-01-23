# OPT-CSUM-003: Checksum on creation-with-upload
# Spec: Checksum for POST body?
# Suggested Best Practice: Support Upload-Checksum on POST with body

# POST with body and checksum (requires creation-with-upload extension)
# "Hello, tus!" SHA1: jiVMcGsdc+pakQJdI4OKm+zKT3s=
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 12
Content-Type: application/offset+octet-stream
Upload-Checksum: sha1 jiVMcGsdc+pakQJdI4OKm+zKT3s=

```
Hello, tus!
```

HTTP 201

[Asserts]
header "Location" exists
header "Upload-Offset" == "12"
