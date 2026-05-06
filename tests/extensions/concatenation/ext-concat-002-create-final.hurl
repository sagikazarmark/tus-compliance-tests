# EXT-CONCAT-002: Create final upload
# POST with Upload-Concat: final;url1 url2 MUST succeed
# Spec: "A final upload is created by sending a POST request with the Upload-Concat header
#        set to final followed by a semicolon and the partial upload URLs"

# Create first partial upload (6 bytes: AAAAA + newline)
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 6
Upload-Concat: partial

HTTP 201

[Captures]
partial1_url: header "Location"

# Upload data to first partial
PATCH {{partial1_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
AAAAA
```

HTTP 204

# Create second partial upload (6 bytes: BBBBB + newline)
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 6
Upload-Concat: partial

HTTP 201

[Captures]
partial2_url: header "Location"

# Upload data to second partial
PATCH {{partial2_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
BBBBB
```

HTTP 204

# Create final upload from partials
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Concat: final;{{partial1_url}} {{partial2_url}}

HTTP 201

[Captures]
final_url: header "Location"

[Asserts]
header "Location" exists
header "Upload-Concat" == "final;{{partial1_url}} {{partial2_url}}"
