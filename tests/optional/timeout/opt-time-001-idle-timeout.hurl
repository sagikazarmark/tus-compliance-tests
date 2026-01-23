# OPT-TIME-001: Idle connection timeout
# Spec: No timeout requirements
# Suggested Best Practice: Document timeouts; minimum 30 seconds recommended
# Note: Timeout testing requires external tooling or server configuration

POST {{base_url}}
Tus-Resumable: {{tus_version}}
Upload-Length: 100

HTTP 201

[Captures]
upload_url: header "Location"

# Basic connectivity test - actual timeout testing requires keeping connection idle
HEAD {{upload_url}}
Tus-Resumable: {{tus_version}}

HTTP 200

# Note: To test idle timeout:
# 1. Configure server with short idle timeout
# 2. Open connection, send partial request headers
# 3. Wait beyond idle timeout
# 4. Verify server closes connection appropriately
