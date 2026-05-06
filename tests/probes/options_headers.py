import http.client
import os
import re
from urllib.parse import urlparse


BASE_URL = os.environ.get("TUS_BASE_URL", "http://tus:8080/files")
TUS_VERSION = "1.0.0"
DOCS = "tests/README.md#runner-configuration"


def fail(problem, likely_cause, fix, docs=DOCS):
    raise SystemExit(
        f"Problem: {problem}\n"
        f"Likely cause: {likely_cause}\n"
        f"Fix: {fix}\n"
        f"Docs: {docs}"
    )


def parsed_target():
    parsed = urlparse(BASE_URL)
    if parsed.scheme not in ("http", "https"):
        fail(
            f"Unsupported TUS_BASE_URL scheme: {parsed.scheme!r}.",
            "The OPTIONS probe uses Python's standard HTTP client.",
            "Use an http:// or https:// tus base URL.",
        )
    host = parsed.hostname or "tus"
    port = parsed.port or (443 if parsed.scheme == "https" else 80)
    path = parsed.path or "/files"
    if parsed.query:
        path = f"{path}?{parsed.query}"
    return parsed.scheme, host, port, path


def request(method, headers=None):
    scheme, host, port, path = parsed_target()
    conn_cls = http.client.HTTPSConnection if scheme == "https" else http.client.HTTPConnection
    conn = conn_cls(host, port, timeout=10)
    try:
        conn.request(method, path, headers=headers or {})
        res = conn.getresponse()
        response_headers = {k.lower(): v.strip() for k, v in res.getheaders()}
        body = res.read()
        return res.status, response_headers, body
    finally:
        conn.close()


def parse_extensions(value):
    token = r"[A-Za-z0-9-]+"
    extensions = {part.strip() for part in value.split(",")}
    if "" in extensions or any(not re.fullmatch(token, ext) for ext in extensions):
        fail(
            f"Invalid Tus-Extension format: {value!r}.",
            "The server returned an empty or malformed extension token.",
            "Return a comma-separated list of tus extension tokens without empty entries.",
        )
    return extensions


status, headers, body = request("OPTIONS")

if status not in (200, 204):
    fail(
        f"OPTIONS returned {status}: {body!r}.",
        "The server did not accept OPTIONS on the configured tus base URL.",
        "Verify TUS_BASE_URL points at the tus collection endpoint.",
    )

if "tus-version" not in headers:
    fail(
        "OPTIONS response is missing Tus-Version.",
        "The server did not advertise supported tus protocol versions.",
        "Include Tus-Version on OPTIONS responses, for example Tus-Version: 1.0.0.",
    )

if not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+(,[0-9]+\.[0-9]+\.[0-9]+)*", headers["tus-version"]):
    fail(
        f"Invalid Tus-Version format: {headers['tus-version']!r}.",
        "The server returned a malformed tus version list.",
        "Return comma-separated semantic version tokens such as 1.0.0.",
    )

extensions = set()
if "tus-extension" in headers:
    extensions = parse_extensions(headers["tus-extension"])
    if "creation-with-upload" in extensions and "creation" not in extensions:
        fail(
            "creation-with-upload advertised without creation.",
            "Creation-with-upload depends on the creation extension semantics.",
            "Advertise creation whenever creation-with-upload is advertised.",
        )

if "tus-max-size" in headers:
    max_size = headers["tus-max-size"]
    if not re.fullmatch(r"[0-9]+", max_size):
        fail(
            f"Invalid Tus-Max-Size: {max_size!r}.",
            "Tus-Max-Size must be a non-negative integer when present.",
            "Return only decimal digits in Tus-Max-Size or omit the header.",
        )
    if "creation" in extensions:
        oversized = int(max_size) + 1
        create_status, _, create_body = request(
            "POST",
            headers={
                "Tus-Resumable": TUS_VERSION,
                "Upload-Length": str(oversized),
            },
        )
        if create_status != 413:
            fail(
                f"Upload-Length greater than Tus-Max-Size returned {create_status}: {create_body!r}.",
                "The server advertised Tus-Max-Size but did not enforce it on creation.",
                "Reject creation requests exceeding Tus-Max-Size with 413 Request Entity Too Large.",
                "docs/protocol-coverage-audit.md",
            )
