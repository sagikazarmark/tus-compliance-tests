# CP-HEAD-003: HEAD requires Tus-Resumable
# Request without Tus-Resumable must be rejected; exact status is not specified.
# Spec: "The Tus-Resumable header MUST be included in every request and response
#        except for OPTIONS requests."

# Step 1: Create an upload first
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

# Step 2: HEAD without Tus-Resumable header must be rejected.
HEAD {{upload_url}}

HTTP *

[Asserts]
status toString matches /^(400|412)$/
