# CP-HEAD-007: HEAD offset zero for new upload
# New upload MUST report Upload-Offset: 0
# Spec: Upload-Offset represents the current offset of the upload; new uploads start at 0

# Step 1: Create a new upload
POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

# Step 2: HEAD on new upload should show offset 0
HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP 200

[Asserts]
header "Upload-Offset" == "0"
