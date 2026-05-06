import http.client
import os
import re
import time
from urllib.parse import urljoin, urlparse


BASE_URL = os.environ.get("TUS_BASE_URL", "http://tus:8080/files")
TUS_VERSION = "1.0.0"
PARTIAL_BODY = b"partial data\n"
DOCS = "tests/README.md#runner-configuration"
HTTP_DATE = re.compile(
    r"^(Mon|Tue|Wed|Thu|Fri|Sat|Sun), "
    r"[0-9]{2} "
    r"(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) "
    r"[0-9]{4} [0-9]{2}:[0-9]{2}:[0-9]{2} GMT$"
)


def fail(problem, likely_cause, fix, docs=DOCS):
    raise SystemExit(
        f"Problem: {problem}\n"
        f"Likely cause: {likely_cause}\n"
        f"Fix: {fix}\n"
        f"Docs: {docs}"
    )


def parse_http_url(url, default_path="/"):
    parsed = urlparse(url)
    if parsed.scheme not in ("http", "https"):
        fail(
            f"Unsupported TUS_BASE_URL scheme: {parsed.scheme!r}.",
            "The expiration probe uses Python's standard HTTP client.",
            "Use an http:// or https:// tus base URL.",
        )

    host = parsed.hostname or "tus"
    port = parsed.port or (443 if parsed.scheme == "https" else 80)
    path = parsed.path or default_path
    if parsed.query:
        path = f"{path}?{parsed.query}"
    return parsed.scheme, host, port, path


def parsed_target():
    return parse_http_url(BASE_URL, "/files")


def http_connection_for(scheme, host, port):
    conn_cls = http.client.HTTPSConnection if scheme == "https" else http.client.HTTPConnection
    return conn_cls(host, port, timeout=10)


def http_connection():
    scheme, host, port, _ = parsed_target()
    return http_connection_for(scheme, host, port)


def request(method, path, headers=None, body=None):
    conn = http_connection()
    try:
        conn.request(method, path, body=body, headers=headers or {})
        res = conn.getresponse()
        response_headers = {k.lower(): v.strip() for k, v in res.getheaders()}
        response_body = res.read()
        return res.status, response_headers, response_body
    finally:
        conn.close()


def request_url(method, url, headers=None, body=None):
    scheme, host, port, path = parse_http_url(url)
    conn = http_connection_for(scheme, host, port)
    try:
        conn.request(method, path, body=body, headers=headers or {})
        res = conn.getresponse()
        response_headers = {k.lower(): v.strip() for k, v in res.getheaders()}
        response_body = res.read()
        return res.status, response_headers, response_body
    finally:
        conn.close()


def options_extensions():
    _, _, _, base_path = parsed_target()
    status, headers, body = request("OPTIONS", base_path)
    if status not in (200, 204):
        fail(
            f"OPTIONS returned {status}: {body!r}.",
            "The server did not accept OPTIONS on the configured tus base URL.",
            "Verify TUS_BASE_URL points at the tus collection endpoint.",
        )

    extensions = headers.get("tus-extension", "")
    return {part.strip().lower() for part in extensions.split(",") if part.strip()}


def resolve_location(location):
    resolved = urlparse(urljoin(BASE_URL.rstrip("/") + "/", location))
    return resolved.geturl()


def create_upload():
    _, _, _, base_path = parsed_target()
    status, headers, body = request(
        "POST",
        base_path,
        headers={
            "Tus-Resumable": TUS_VERSION,
            "Upload-Length": "100",
        },
    )
    location = headers.get("location")
    if status != 201 or not location:
        fail(
            f"Upload creation returned {status} with Location {location!r}: {body!r}.",
            "The server advertised expiration but could not create a fixed-length upload.",
            "Ensure creation requests with Upload-Length are supported at TUS_BASE_URL.",
            "docs/protocol-coverage-audit.md",
        )
    return resolve_location(location)


def patch_upload(upload_url, require_expires):
    status, headers, body = request_url(
        "PATCH",
        upload_url,
        headers={
            "Tus-Resumable": TUS_VERSION,
            "Upload-Offset": "0",
            "Content-Type": "application/offset+octet-stream",
        },
        body=PARTIAL_BODY,
    )
    if status != 204:
        fail(
            f"PATCH returned {status}: {body!r}.",
            "The server advertised expiration but rejected a valid partial upload PATCH.",
            "Accept PATCH with application/offset+octet-stream and Upload-Offset 0 for the created upload.",
            "docs/protocol-coverage-audit.md",
        )

    expires = headers.get("upload-expires")
    if require_expires and not expires:
        fail(
            f"PATCH missing Upload-Expires: {headers}.",
            "The expiration probe was configured with a wait window, so this upload is expected to expire.",
            "Return Upload-Expires for expiring unfinished uploads or set TUS_EXPIRATION_WAIT_SECONDS=0 for smoke coverage.",
            "docs/protocol-coverage-audit.md",
        )
    if expires and not HTTP_DATE.fullmatch(expires):
        fail(
            f"PATCH returned invalid Upload-Expires: {headers}.",
            "The server returned Upload-Expires but not as an RFC 9110 HTTP-date.",
            "Return Upload-Expires in IMF-fixdate form, for example Tue, 15 Nov 1994 08:12:31 GMT.",
            "docs/protocol-coverage-audit.md",
        )


def env_seconds(name, default):
    raw = os.environ.get(name, default)
    try:
        return float(raw)
    except ValueError:
        fail(
            f"{name} must be a number of seconds, got {raw!r}.",
            "The expiration probe uses numeric wait and grace periods for polling.",
            f"Set {name} to a non-negative number.",
        )


def wait_for_expiration(upload_url, wait_seconds):
    if wait_seconds <= 0:
        return

    grace_seconds = env_seconds("TUS_EXPIRATION_GRACE_SECONDS", "5")
    deadline = time.monotonic() + wait_seconds + grace_seconds
    time.sleep(wait_seconds)

    last_status = None
    while time.monotonic() <= deadline:
        status, _, _ = request_url(
            "HEAD",
            upload_url,
            headers={"Tus-Resumable": TUS_VERSION},
        )
        last_status = status
        if status in (404, 410):
            return
        time.sleep(1)

    fail(
        f"Expired upload returned {last_status}; expected 404 or 410 before deadline.",
        "The server advertised expiration but did not make the unfinished upload unavailable after its expiry window.",
        "Configure a short unfinished-upload expiration and ensure HEAD rejects expired uploads with 404 or 410.",
        "docs/protocol-coverage-audit.md",
    )


if "expiration" not in options_extensions():
    raise SystemExit(0)

upload_path = create_upload()
wait_seconds = env_seconds("TUS_EXPIRATION_WAIT_SECONDS", "0")
patch_upload(upload_path, require_expires=wait_seconds > 0)
wait_for_expiration(upload_path, wait_seconds)
