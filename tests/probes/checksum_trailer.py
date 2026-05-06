import base64
import hashlib
import http.client
import os
import socket
import ssl
from urllib.parse import urlparse


TUS_VERSION = "1.0.0"
BODY = b"Hello, tus!\n"
DOCS = "tests/README.md#runner-configuration"


def fail(problem, likely_cause, fix, docs=DOCS):
    raise SystemExit(
        f"Problem: {problem}\n"
        f"Likely cause: {likely_cause}\n"
        f"Fix: {fix}\n"
        f"Docs: {docs}"
    )


def parsed_target():
    base_url = os.environ.get("TUS_BASE_URL", "http://tus:8080/files")
    parsed = urlparse(base_url)
    if parsed.scheme not in ("http", "https"):
        fail(
            f"Unsupported TUS_BASE_URL scheme: {parsed.scheme!r}.",
            "The checksum trailer probe uses HTTP/1.1 over raw sockets.",
            "Use an http:// or https:// tus base URL.",
        )

    host = parsed.hostname or "tus"
    port = parsed.port or (443 if parsed.scheme == "https" else 80)
    path = parsed.path or "/files"
    if parsed.query:
        path = f"{path}?{parsed.query}"
    return parsed.scheme, host, port, path


def http_connection():
    scheme, host, port, _ = parsed_target()
    conn_cls = http.client.HTTPSConnection if scheme == "https" else http.client.HTTPConnection
    return conn_cls(host, port, timeout=10)


def options_extensions():
    _, _, _, path = parsed_target()
    conn = http_connection()
    try:
        conn.request("OPTIONS", path)
        res = conn.getresponse()
        headers = {k.lower(): v for k, v in res.getheaders()}
        body = res.read()
    finally:
        conn.close()

    if res.status not in (200, 204):
        fail(
            f"OPTIONS returned {res.status}: {body!r}.",
            "The server did not accept OPTIONS on the configured tus base URL.",
            "Verify TUS_BASE_URL points at the tus collection endpoint.",
        )

    extensions = headers.get("tus-extension", "")
    return {part.strip() for part in extensions.split(",") if part.strip()}


def create_upload():
    _, _, _, path = parsed_target()
    conn = http_connection()
    try:
        conn.request(
            "POST",
            path,
            headers={
                "Tus-Resumable": TUS_VERSION,
                "Upload-Length": str(len(BODY)),
            },
        )
        res = conn.getresponse()
        location = res.getheader("Location")
        body = res.read()
    finally:
        conn.close()

    if res.status != 201 or not location:
        fail(
            f"Upload creation returned {res.status} with Location {location!r}: {body!r}.",
            "The server advertised checksum-trailer but could not create a fixed-length upload.",
            "Ensure creation requests with Upload-Length are supported at TUS_BASE_URL.",
            "docs/protocol-coverage-audit.md",
        )

    if location.startswith("/"):
        return location

    parsed_location = urlparse(location)
    path = parsed_location.path or "/"
    if not path.startswith("/"):
        path = f"/{path}"
    if parsed_location.query:
        path = f"{path}?{parsed_location.query}"
    return path


def parse_header_block(header_block):
    lines = header_block.decode("iso-8859-1", errors="replace").split("\r\n")
    headers = {}
    for line in lines[1:]:
        if not line or ":" not in line:
            continue
        name, value = line.split(":", 1)
        headers[name.lower()] = value.strip()
    return lines[0], headers


def raw_patch_with_trailer(path, checksum):
    scheme, host, port, _ = parsed_target()
    host_header = host if port in (80, 443) else f"{host}:{port}"
    request = (
        f"PATCH {path} HTTP/1.1\r\n"
        f"Host: {host_header}\r\n"
        f"Tus-Resumable: {TUS_VERSION}\r\n"
        "Upload-Offset: 0\r\n"
        "Content-Type: application/offset+octet-stream\r\n"
        "Transfer-Encoding: chunked\r\n"
        "Trailer: Upload-Checksum\r\n"
        "Connection: close\r\n"
        "\r\n"
    ).encode("ascii")
    request += f"{len(BODY):X}\r\n".encode("ascii") + BODY + b"\r\n"
    request += b"0\r\n"
    request += f"Upload-Checksum: sha1 {checksum}\r\n\r\n".encode("ascii")

    with socket.create_connection((host, port), timeout=10) as sock:
        if scheme == "https":
            with ssl.create_default_context().wrap_socket(sock, server_hostname=host) as wrapped:
                wrapped.sendall(request)
                header_block = read_response_headers(wrapped)
        else:
            sock.sendall(request)
            header_block = read_response_headers(sock)

    return parse_header_block(header_block)


def read_response_headers(sock):
    chunks = []
    while True:
        chunk = sock.recv(4096)
        if not chunk:
            break
        chunks.append(chunk)
        response = b"".join(chunks)
        header_end = response.find(b"\r\n\r\n")
        if header_end != -1:
            return response[:header_end]

    response = b"".join(chunks)
    fail(
        f"Checksum trailer PATCH response ended before complete headers: {response!r}.",
        "The server closed the connection before sending an HTTP response header block.",
        "Verify the server supports HTTP/1.1 chunked requests with trailers when checksum-trailer is advertised.",
        "docs/protocol-coverage-audit.md",
    )


if "checksum-trailer" not in options_extensions():
    raise SystemExit(0)

upload_path = create_upload()
valid = base64.b64encode(hashlib.sha1(BODY).digest()).decode("ascii")
status_line, headers = raw_patch_with_trailer(upload_path, valid)
if " 204 " not in status_line:
    fail(
        f"Checksum trailer PATCH returned unexpected status: {status_line}.",
        "The server advertised checksum-trailer but rejected a valid chunked PATCH trailer checksum.",
        "Accept Upload-Checksum in the HTTP trailer and return 204 for the valid upload chunk.",
        "docs/protocol-coverage-audit.md",
    )
if headers.get("upload-offset") != str(len(BODY)):
    fail(
        f"Checksum trailer PATCH returned Upload-Offset {headers.get('upload-offset')!r}; expected {len(BODY)}.",
        "The server did not report the updated offset after accepting the trailer checksum.",
        "Return Upload-Offset with the new offset after a successful PATCH.",
        "docs/protocol-coverage-audit.md",
    )
