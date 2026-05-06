# [tus](https://tus.io) Protocol Compliance Test Suite

A comprehensive test suite for validating tus resumable upload protocol v1.0.0 server implementations.

- **[Specification](https://github.com/tus/tus-resumable-upload-protocol/blob/83541f361872002bb26a3571bff71b10408ef91f/protocol.md)** (as of 2016-03-25) (also available on the [website](https://tus.io/protocols/resumable-upload.html))
- [OpenAPI](https://github.com/tus/tus-resumable-upload-protocol/blob/83541f361872002bb26a3571bff71b10408ef91f/OpenAPI/openapi3.yaml)

## Overview

The [test suite](tests/) includes:

- **Core Protocol Tests** - Required for all implementations (27 tests)
- **Extension Tests** - Modular tests for each tus extension (52 tests)
- **Scenario Tests** - End-to-end workflow validation (13 tests)
- **Optional Tests** - Behavioral tests for undefined spec areas (31 tests)

**Total: 123 tests**

## Requirements

### The easy way

- [Dagger](https://dagger.io)

### The hard way

- [hurl](https://hurl.dev/) v7.1.0 or later
- A running tus server implementation to test against
- Docker and Docker Compose (optional, for running test servers)

> [!TIP]
> If you use [devenv](https://devenv.sh) or [mise](https://mise.jdx.dev), you can easily set up the required tools.

## Quick Start

### Prerequisites

- Dagger for the recommended containerized runner.
- Docker available to Dagger for server and runner containers.
- For direct script usage: Python 3, Hurl v7.1.0, and a running tus server.

### Hello World Runner

```bash
dagger call run --server=TUSD --report=JUNIT export --path results/tusd-hello
```

Expected duration: about 1 to 3 minutes for a local server image after Docker layers are cached. First runs may take longer while Dagger pulls or builds images.

The exported result directory contains one subdirectory per server. For the hello-world command above, inspect `results/tusd-hello/tusd/` for selection reports named by server:

- `all-<server>.txt`: every discovered `.hurl` and selected probe path before filtering.
- `unsupported-<server>.txt`: extension paths removed because `Tus-Extension` did not advertise that extension.
- `raw-active-<server>.txt`: tests remaining after unsupported filtering and before source-verified skips.
- `skipped-<server>.txt`: exact paths skipped by `tests/skips/<server>.txt`.
- `active-<server>.txt`: selected paths actually executed, unless `LIST_ONLY=true` is used.
- `status-<server>.txt`: numeric runner exit status; `0` means all active Hurl files and probes passed or `LIST_ONLY=true` skipped execution.

Raw means selected by path arguments. Unsupported means excluded because the server did not advertise the required tus extension. Skipped means source-verified server noncompliance documented in `docs/server-noncompliance.md`. Active means the runner executes the path.

### Troubleshooting

#### Capability Discovery Failure

If OPTIONS fails or no `Tus-Extension` header is present, the runner treats the server as advertising no extensions. Extension tests are reported in `unsupported-*` instead of being run.

#### Server Startup Failure

If Dagger fails before reports are written, inspect the server image logs and confirm Docker can pull or build the selected server. The runner expects the tus service at `http://tus:8080/files` inside Dagger.

#### Probe Failure

Python probes run only when selected and active. Probe errors use the `Problem` / `Likely cause` / `Fix` / `Docs` shape and should be checked alongside `active-*` and `status-*`.

#### Source-Verified Skip Policy

Do not add a skip for a failing server until the implementation source or upstream issue proves server noncompliance. Every non-comment line in `tests/skips/<server>.txt` must have a matching entry in `docs/server-noncompliance.md`.

## References

### Protocol & Tools
- [tus Protocol v1.0.0](https://tus.io/protocols/resumable-upload)
- [hurl Documentation](https://hurl.dev/docs)

### tus Server Implementations
- [tusd](https://github.com/tus/tusd) - Official reference implementation (Go)
- [rustus](https://github.com/s3rius/rustus) - High-performance Rust implementation
- [tus-node-server](https://github.com/tus/tus-node-server) - Official Node.js implementation
- [tus Implementations List](https://tus.io/implementations) - Complete list of tus implementations

## License

The project is licensed under the [MIT License](LICENSE).
