# SCN-CONCAT-002: Sequential partial upload
# Create and complete partials sequentially, then concatenate

# Step 1: Create and complete first partial (6 bytes: AAAAA + newline)
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

# Verify first partial is complete
HEAD {{partial1_url}}
Tus-Resumable: {{tus_version}}

HTTP 200

[Asserts]
header "Upload-Offset" == "6"

# Step 2: Create and complete second partial (7 bytes: BBBBBB + newline)
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

# Verify second partial is complete
HEAD {{partial2_url}}
Tus-Resumable: {{tus_version}}

HTTP 200

[Asserts]
header "Upload-Offset" == "7"

# Step 3: Create final concatenation
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Concat: final;{{partial1_url}} {{partial2_url}}

HTTP 201

[Captures]
final_url: header "Location"

# Step 4: Verify final is complete with correct size (6 + 7 = 13)
HEAD {{final_url}}
Tus-Resumable: {{tus_version}}

HTTP 200

[Asserts]
header "Upload-Offset" == "13"
header "Upload-Length" == "13"
