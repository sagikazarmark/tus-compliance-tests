# EXT-CONCAT-004: Final offset is sum of partials
# Final upload Upload-Offset MUST equal sum of partial sizes
# Spec: "The Upload-Offset header of a final upload MUST be set to the sum of
#        the Upload-Length headers of all partial uploads"

# Create first partial (6 bytes: AAAAA + newline)
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 6
Upload-Concat: partial

HTTP 201

[Captures]
partial1_url: header "Location"

PATCH {{partial1_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
AAAAA
```

HTTP 204

# Create second partial (7 bytes: BBBBBB + newline)
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 7
Upload-Concat: partial

HTTP 201

[Captures]
partial2_url: header "Location"

PATCH {{partial2_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
BBBBBB
```

HTTP 204

# Create final
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Concat: final;{{partial1_url}} {{partial2_url}}

HTTP 201

[Captures]
final_url: header "Location"

# Verify final offset is 6 + 7 = 13
HEAD {{final_url}}
Tus-Resumable: {{tus_version}}

HTTP 200

[Asserts]
header "Upload-Offset" == "13"
header "Upload-Length" == "13"
