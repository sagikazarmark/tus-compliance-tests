# EXT-EXPIRE-002: Upload-Expires in PATCH response
# Servers advertising expiration and tracking unfinished upload expiry MUST return Upload-Expires on PATCH.
# Spec: "If a PATCH request is issued against an upload with a known expiration date, the Upload-Expires header MUST be included in the response."

# Create upload
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

# PATCH and check for Upload-Expires
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
test data
```

HTTP 204

[Asserts]
header "Upload-Expires" exists
header "Upload-Expires" matches "^(Mon|Tue|Wed|Thu|Fri|Sat|Sun), [0-9]{2} (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) [0-9]{4} [0-9]{2}:[0-9]{2}:[0-9]{2} GMT$"
