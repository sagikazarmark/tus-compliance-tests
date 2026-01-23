#!/bin/bash
# tus Protocol Compliance Test Runner
# Usage: ./run-tests.sh [options] <category>

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="${SCRIPT_DIR}/results"
TESTS_DIR="${SCRIPT_DIR}/tests"
VARS_FILE="${SCRIPT_DIR}/variables.env"

# Default options
VERBOSE=""
REPORT_FORMAT=""
HURL_OPTS="--test"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_usage() {
    cat << EOF
tus Protocol Compliance Test Runner

USAGE:
    ./run-tests.sh [OPTIONS] <CATEGORY>

CATEGORIES:
    all             Run all tests
    core            Core protocol tests (CP-*)
    ext             All extension tests
    ext-creation    Creation extension tests
    ext-defer       Creation-defer-length tests
    ext-cwu         Creation-with-upload tests
    ext-expiration  Expiration extension tests
    ext-checksum    Checksum extension tests (including trailer)
    ext-termination Termination extension tests
    ext-concat      Concatenation extension tests (including unfinished)
    scenario        Scenario tests (SCN-*)
    optional        Optional behavior tests (OPT-*)
    discover        Run OPTIONS to discover server capabilities

OPTIONS:
    -v, --verbose       Enable verbose output
    -r, --report FMT    Generate report (junit, json, tap)
    -h, --help          Show this help message

EXAMPLES:
    ./run-tests.sh all                 Run all tests
    ./run-tests.sh -v core             Run core tests with verbose output
    ./run-tests.sh -r junit all        Run all tests with JUnit report
    ./run-tests.sh ext-creation        Run only creation extension tests

ENVIRONMENT:
    TUS_BASE_URL    Override base_url from variables.env
    TUS_VERSION     Override tus_version from variables.env
EOF
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

# Check for hurl installation
check_hurl() {
    if ! command -v hurl &> /dev/null; then
        log_error "hurl is not installed. Please install it from https://hurl.dev/"
        exit 1
    fi
}

# Create results directory
setup_results_dir() {
    mkdir -p "$RESULTS_DIR"
}

# Build hurl options
build_hurl_opts() {
    local opts="--test"

    if [[ -n "$VERBOSE" ]]; then
        opts="$opts --verbose"
    fi

    if [[ -n "$REPORT_FORMAT" ]]; then
        local timestamp=$(date +%Y%m%d_%H%M%S)
        case "$REPORT_FORMAT" in
            junit)
                opts="$opts --report-junit ${RESULTS_DIR}/report_${timestamp}.xml"
                ;;
            json)
                opts="$opts --report-json ${RESULTS_DIR}/report_${timestamp}.json"
                ;;
            tap)
                opts="$opts --report-tap ${RESULTS_DIR}/report_${timestamp}.tap"
                ;;
        esac
    fi

    # Add variables file
    if [[ -f "$VARS_FILE" ]]; then
        opts="$opts --variables-file $VARS_FILE"
    fi

    # Environment variable overrides
    if [[ -n "$TUS_BASE_URL" ]]; then
        opts="$opts --variable base_url=$TUS_BASE_URL"
    fi
    if [[ -n "$TUS_VERSION" ]]; then
        opts="$opts --variable tus_version=$TUS_VERSION"
    fi

    echo "$opts"
}

# Run tests for a specific path
run_tests() {
    local test_path="$1"
    local test_name="$2"
    local opts=$(build_hurl_opts)

    log_info "Running $test_name tests..."

    # Find all .hurl files
    local files=$(find "$test_path" -name "*.hurl" -type f 2>/dev/null | sort)

    if [[ -z "$files" ]]; then
        log_warn "No test files found in $test_path"
        return 0
    fi

    local count=$(echo "$files" | wc -l | tr -d ' ')
    log_info "Found $count test file(s)"

    # Run hurl with all files
    if hurl $opts $files; then
        log_success "$test_name tests passed"
        return 0
    else
        log_error "Some $test_name tests failed"
        return 1
    fi
}

# Run core protocol tests
run_core() {
    log_info "=== Core Protocol Tests ==="
    run_tests "${TESTS_DIR}/core" "Core Protocol"
}

# Run all extension tests
run_extensions() {
    log_info "=== Extension Tests ==="
    run_tests "${TESTS_DIR}/extensions" "Extensions"
}

# Run specific extension tests
run_extension() {
    local ext_name="$1"
    local ext_path="${TESTS_DIR}/extensions/${ext_name}"

    if [[ ! -d "$ext_path" ]]; then
        log_error "Extension directory not found: $ext_path"
        return 1
    fi

    run_tests "$ext_path" "$ext_name extension"
}

# Run scenario tests
run_scenarios() {
    log_info "=== Scenario Tests ==="
    run_tests "${TESTS_DIR}/scenarios" "Scenario"
}

# Run optional tests
run_optional() {
    log_info "=== Optional Behavior Tests ==="
    run_tests "${TESTS_DIR}/optional" "Optional"
}

# Run discovery (OPTIONS request)
run_discover() {
    local opts=$(build_hurl_opts)
    opts="${opts/--test/}"

    log_info "=== Server Discovery ==="
    log_info "Sending OPTIONS request to discover server capabilities..."

    # Get base_url from variables.env or environment
    local base_url="${TUS_BASE_URL:-$(grep '^base_url=' "$VARS_FILE" 2>/dev/null | cut -d'=' -f2)}"

    if [[ -z "$base_url" ]]; then
        log_error "base_url not configured"
        return 1
    fi

    echo ""
    curl -s -X OPTIONS "$base_url" \
        -H "Tus-Resumable: 1.0.0" \
        -D - \
        -o /dev/null | grep -i "^tus-"
    echo ""
}

# Run all tests
run_all() {
    local failed=0

    run_core || failed=1
    run_extensions || failed=1
    run_scenarios || failed=1
    run_optional || failed=1

    echo ""
    if [[ $failed -eq 0 ]]; then
        log_success "=== All tests passed ==="
    else
        log_error "=== Some tests failed ==="
    fi

    return $failed
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -v|--verbose)
                VERBOSE="true"
                shift
                ;;
            -r|--report)
                REPORT_FORMAT="$2"
                shift 2
                ;;
            -h|--help)
                print_usage
                exit 0
                ;;
            *)
                CATEGORY="$1"
                shift
                ;;
        esac
    done
}

# Main entry point
main() {
    parse_args "$@"

    check_hurl
    setup_results_dir

    cd "$SCRIPT_DIR"

    case "${CATEGORY:-all}" in
        all)
            run_all
            ;;
        core)
            run_core
            ;;
        ext|extensions)
            run_extensions
            ;;
        ext-creation)
            run_extension "creation"
            ;;
        ext-defer)
            run_extension "creation-defer-length"
            ;;
        ext-cwu)
            run_extension "creation-with-upload"
            ;;
        ext-expiration)
            run_extension "expiration"
            ;;
        ext-checksum)
            run_extension "checksum"
            run_extension "checksum-trailer"
            ;;
        ext-termination)
            run_extension "termination"
            ;;
        ext-concat)
            run_extension "concatenation"
            run_extension "concatenation-unfinished"
            ;;
        scenario|scenarios)
            run_scenarios
            ;;
        optional)
            run_optional
            ;;
        discover)
            run_discover
            ;;
        *)
            log_error "Unknown category: $CATEGORY"
            print_usage
            exit 1
            ;;
    esac
}

main "$@"
