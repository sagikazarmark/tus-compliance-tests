### Testing Each Server

#### Testing tusd (Go Reference Implementation)

tusd is the official reference implementation with full protocol support.

```bash
# Start tusd
docker compose up -d tusd

# Configure test suite for tusd
cat > variables.env << 'EOF'
base_url=http://localhost:1080/files
tus_version=1.0.0
EOF

# Run all tests
./run-tests.sh all

# Or run specific categories
./run-tests.sh core
./run-tests.sh ext-creation
./run-tests.sh ext-checksum
./run-tests.sh scenario
```

**tusd Extensions:** creation, creation-with-upload, creation-defer-length, termination, concatenation, checksum, expiration

#### Testing rustus (Rust Implementation)

rustus is a high-performance Rust-based tus server.

```bash
# Start rustus
docker compose up -d rustus

# Configure test suite for rustus
cat > variables.env << 'EOF'
base_url=http://localhost:1081/files
tus_version=1.0.0
EOF

# Run all tests
./run-tests.sh all

# Run specific tests
./run-tests.sh core
./run-tests.sh ext-creation
./run-tests.sh ext-termination
```

**rustus Extensions:** creation, creation-with-upload, creation-defer-length, termination, concatenation, checksum

#### Testing tus-node-server (Node.js Implementation)

tus-node-server is the official Node.js tus implementation.

```bash
# Start tus-node-server (builds from Dockerfile on first run)
docker compose up -d tus-node-server

# Configure test suite for tus-node-server
cat > variables.env << 'EOF'
base_url=http://localhost:1082/files
tus_version=1.0.0
EOF

# Run all tests
./run-tests.sh all

# Run specific tests
./run-tests.sh core
./run-tests.sh ext-creation
./run-tests.sh ext-termination
```

**tus-node-server Extensions:** creation, creation-with-upload, creation-defer-length, termination, expiration

### Comparing Server Compliance

Run the test suite against each server and compare results:

```bash
# Use the included comparison script
./compare-servers.sh --start --all

# Or manually test each server
SERVERS=("tusd:1080" "rustus:1081" "tus-node-server:1082")

for server in "${SERVERS[@]}"; do
    name="${server%%:*}"
    port="${server##*:}"

    echo "=========================================="
    echo "Testing: $name (port $port)"
    echo "=========================================="

    # Update variables
    cat > variables.env << EOF
base_url=http://localhost:${port}/files
tus_version=1.0.0
EOF

    # Run tests and save results
    ./run-tests.sh -r junit all 2>&1 | tee "results/${name}-output.txt"
    mv results/report_*.xml "results/${name}-junit.xml" 2>/dev/null || true

    echo ""
done

echo "Results saved to ./results/"
```

### Server Health Checks

Verify servers are running and responsive:

```bash
# Check tusd
curl -I http://localhost:1080/files/

# Check rustus
curl -I http://localhost:1081/files/

# Check tus-node-server
curl -I http://localhost:1082/files/

# Check all with OPTIONS (shows supported extensions)
curl -X OPTIONS http://localhost:1080/files/ -H "Tus-Resumable: 1.0.0" -I
curl -X OPTIONS http://localhost:1081/files/ -H "Tus-Resumable: 1.0.0" -I
curl -X OPTIONS http://localhost:1082/files/ -H "Tus-Resumable: 1.0.0" -I
```

### Troubleshooting Docker Setup

**Container won't start:**
```bash
# Check container status
docker compose ps

# View container logs
docker compose logs tusd
docker compose logs rustus
docker compose logs tus-node-server

# Restart containers
docker compose restart
```

**Permission issues with volumes:**
```bash
# Remove and recreate volumes
docker compose down -v
docker compose up -d
```

**Port conflicts:**
```bash
# Check what's using the ports
lsof -i :1080
lsof -i :1081

# Or modify compose.yaml to use different ports
```

## Configuration

### Environment Variables

Create a `variables.env` file (copy from `variables.env.template`):

```bash
# Base URL for the tus upload endpoint
base_url=http://localhost:1080/files

# tus protocol version to test
tus_version=1.0.0

# Optional: Authentication header (if required)
# auth_header=Authorization
# auth_value=Bearer your-token-here
```

### Test Runner Options

```bash
# Run with verbose output
./run-tests.sh -v all

# Generate JUnit XML report
./run-tests.sh -r junit all

# Run specific extension tests
./run-tests.sh ext-creation
./run-tests.sh ext-checksum
./run-tests.sh ext-termination

# Run a single test file
hurl --variables-file variables.env core/cp-opt/cp-opt-001-tus-version.hurl

# Dry run (check syntax only)
hurl --check core/**/*.hurl
```

## Testing with Docker

The test suite includes a `compose.yaml` file to run multiple tus server implementations for testing.

### Available Servers

| Server | Language | Port | Description |
|--------|----------|------|-------------|
| **tusd** | Go | 1080 | Official tus reference implementation |
| **rustus** | Rust | 1081 | High-performance Rust implementation |
| **tus-node-server** | Node.js | 1082 | Official Node.js implementation |

## Test Categories

### Core Protocol (`core/`)

Required tests for basic tus compliance:

| Category | Tests | Description |
|----------|-------|-------------|
| `cp-opt/` | 5 | OPTIONS request handling |
| `cp-head/` | 7 | HEAD request handling |
| `cp-patch/` | 10 | PATCH request handling |
| `cp-ver/` | 3 | Version negotiation |

### Extensions (`extensions/`)

Tests for tus protocol extensions. Run only if your server advertises the extension:

| Extension | Tests | Description |
|-----------|-------|-------------|
| `creation/` | 9 | Upload creation via POST |
| `creation-defer-length/` | 5 | Deferred upload length |
| `creation-with-upload/` | 5 | POST with initial data |
| `expiration/` | 5 | Upload expiration |
| `checksum/` | 8 | Data integrity verification |
| `checksum-trailer/` | 2 | HTTP trailer checksum |
| `termination/` | 5 | Upload deletion |
| `concatenation/` | 8 | Parallel upload assembly |
| `concatenation-unfinished/` | 2 | Incomplete partial concatenation |

### Scenarios (`scenarios/`)

End-to-end workflow tests:

| Category | Tests | Description |
|----------|-------|-------------|
| `basic/` | 4 | Basic upload workflows |
| `resume/` | 4 | Resumption scenarios |
| `error/` | 3 | Error recovery |
| `concat/` | 2 | Concatenation workflows |

### Optional (`optional/`)

Tests for undefined specification behavior. Failures here indicate deviation from suggested best practices but don't affect protocol compliance:

| Category | Tests | Description |
|----------|-------|-------------|
| `metadata/` | 6 | Metadata edge cases |
| `url/` | 3 | URL handling |
| `partial/` | 3 | Partial write handling |
| `concurrent/` | 3 | Concurrency handling |
| `complete/` | 3 | Completion behavior |
| `error/` | 3 | Error response format |
| `timeout/` | 3 | Timeout behavior |
| `storage/` | 3 | Storage edge cases |
| `checksum/` | 3 | Checksum edge cases |
| `expiration/` | 3 | Expiration edge cases |

## Test Data

Tests use deterministic test data for reproducibility:

### ASCII Content

**Note:** Hurl's multiline body syntax adds a trailing newline, so actual byte counts are +1.

- `Hello, tus!\n` (12 bytes) - SHA1: `E7X121m3do5RTtnrOi5XTG9Uq0A=`
- `AAAAAAAAAA\n` (11 bytes of 'A' + newline) - for chunk testing

### Binary Content
Checksum tests use precomputed hashes for verification.

## Compliance Levels

| Level | Requirements |
|-------|--------------|
| **Core** | All `CP-*` tests pass |
| **Core + Creation** | Core + all `EXT-CREATE-*` tests pass |
| **Full** | All required tests for all advertised extensions pass |

## Reports

Test results can be output in multiple formats:

```bash
# JUnit XML (for CI systems)
./run-tests.sh -r junit all

# JSON report
./run-tests.sh -r json all

# TAP format
./run-tests.sh -r tap all
```

Reports are saved to `./results/` directory.

## Notes

### Extension Dependencies

Some tests require specific extensions to be available:
- Most tests in `core/cp-head/` and `core/cp-patch/` require the `creation` extension to create uploads first
- Concatenation scenario tests require the `concatenation` extension
- Checksum tests require the `checksum` extension

### HTTP Trailer Limitations

Tests in `checksum-trailer/` use HTTP trailers which may have limited support depending on your HTTP client/server configuration.

### Timeout Tests

Tests in `optional/timeout/` may require adjusting Hurl timeout settings:
```bash
hurl --connect-timeout 60 --max-time 120 ...
```
