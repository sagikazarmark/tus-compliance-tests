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

2. **Run all tests**
   ```bash
   dagger call run
   ```

3. **Export HTML report**
   ```bash
   dagger call run --report html export --path results
   ```

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
