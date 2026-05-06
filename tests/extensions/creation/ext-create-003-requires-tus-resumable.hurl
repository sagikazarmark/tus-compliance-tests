# EXT-CREATE-003: POST requires Tus-Resumable
# POST without Tus-Resumable must be rejected.
# Spec: "The Tus-Resumable header MUST be included in every request and response
#        except for OPTIONS requests."

POST {{base_url}}
Upload-Length: 100

HTTP 412
