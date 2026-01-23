# EXT-CWU-004: Partial body acceptance
# Server MAY accept fewer bytes than sent; offset indicates actual
# Spec: "The Server MAY only accept a portion of the uploaded data"
# Note: Server may accept all, so Upload-Offset >= 0 is valid

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100
Content-Type: application/offset+octet-stream

```
test data for partial test
```

HTTP 201

[Captures]
upload_url: header "Location"
initial_offset: header "Upload-Offset"

# Verify offset matches what server accepted
HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP 200

[Asserts]
header "Upload-Offset" == "{{initial_offset}}"
