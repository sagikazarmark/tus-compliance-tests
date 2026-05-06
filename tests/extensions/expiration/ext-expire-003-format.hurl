# EXT-EXPIRE-003: Upload-Expires format
# Header MUST use RFC 9110 datetime format
# Spec: "The value of the Upload-Expires header MUST be in RFC 9110 datetime format"
# Format example: "Sat, 18 Apr 2020 12:31:39 GMT"

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

# PATCH response for an unfinished expiring upload MUST include Upload-Expires.
PATCH {{upload_url}}
Tus-Resumable: {{tus_version}}
Upload-Offset: 0
Content-Type: application/offset+octet-stream

```
partial data
```

HTTP 204

[Asserts]
# RFC 9110 format: Day, DD Mon YYYY HH:MM:SS GMT
# Example: Sat, 18 Apr 2020 12:31:39 GMT
header "Upload-Expires" matches "^(Mon|Tue|Wed|Thu|Fri|Sat|Sun), [0-9]{2} (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) [0-9]{4} [0-9]{2}:[0-9]{2}:[0-9]{2} GMT$"
