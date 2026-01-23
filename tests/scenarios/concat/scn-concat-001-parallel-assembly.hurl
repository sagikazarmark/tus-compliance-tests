# SCN-CONCAT-001: Parallel upload assembly
# Create 3 partials, upload in parallel (sequentially here), create final, verify size

# Step 1: Create 3 partial uploads (11 bytes each with trailing newline)
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 11
Upload-Concat: partial

HTTP 201

[Captures]
partial1_url: header "Location"

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 11
Upload-Concat: partial

HTTP 201

[Captures]
partial2_url: header "Location"

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 11
Upload-Concat: partial

HTTP 201

[Captures]
partial3_url: header "Location"

# Step 2: Upload to all partials (in "parallel")
PATCH {{partial1_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
AAAAAAAAAA
```

HTTP 204

PATCH {{partial2_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
BBBBBBBBBB
```

HTTP 204

PATCH {{partial3_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
CCCCCCCCCC
```

HTTP 204

# Step 3: Create final from all partials
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Concat: final;{{partial1_url}} {{partial2_url}} {{partial3_url}}

HTTP 201

[Captures]
final_url: header "Location"

# Step 4: Verify final size (11 + 11 + 11 = 33)
HEAD {{final_url}}
Tus-Resumable: {{tus_version}}

HTTP 200

[Asserts]
header "Upload-Offset" == "33"
header "Upload-Length" == "33"
header "Upload-Concat" startsWith "final"
