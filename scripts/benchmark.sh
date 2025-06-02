#!/bin/bash
# DialogChain Performance Benchmark
set -e

# Configuration
ENDPOINT="${ENDPOINT:-http://localhost:8080/webhook}"
CONCURRENT_REQUESTS="${CONCURRENT_REQUESTS:-10}"
TOTAL_REQUESTS="${TOTAL_REQUESTS:-100}"
PAYLOAD_SIZE="${PAYLOAD_SIZE:-small}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }

generate_payload() {
    local size="$1"

    case $size in
        "small")
            echo '{"message": "test", "timestamp": "'$(date -Iseconds)'", "size": "small"}'
            ;;
        "medium")
            echo '{"message": "test", "timestamp": "'$(date -Iseconds)'", "size": "medium", "data": "'$(head -c 1000 /dev/urandom | base64 | tr -d '\n')''"}'
            ;;
        "large")
            echo '{"message": "test", "timestamp": "'$(date -Iseconds)'", "size": "large", "data": "'$(head -c 10000 /dev/urandom | base64 | tr -d '\n')''"}'
            ;;
    esac
}

run_benchmark() {
    local payload=$(generate_payload "$PAYLOAD_SIZE")

    info "Starting benchmark..."
    info "Endpoint: $ENDPOINT"
    info "Concurrent requests: $CONCURRENT_REQUESTS"
    info "Total requests: $TOTAL_REQUESTS"
    info "Payload size: $PAYLOAD_SIZE"
    echo ""

    # Check if endpoint is available
    if ! curl -s -f "$ENDPOINT" -X POST -H "Content-Type: application/json" -d '{"test": true}' >/dev/null; then
        echo "❌ Error: Endpoint $ENDPOINT is not available"
        exit 1
    fi

    # Run benchmark with Apache Bench if available
    if command -v ab >/dev/null 2>&1; then
        info "Running Apache Bench..."
        echo "$payload" > /tmp/payload.json
        ab -n "$TOTAL_REQUESTS" -c "$CONCURRENT_REQUESTS" -T "application/json" -p /tmp/payload.json "$ENDPOINT"
        rm /tmp/payload.json

    # Fallback to curl-based benchmark
    else
        info "Running curl-based benchmark..."

        start_time=$(date +%s.%N)

        for i in $(seq 1 "$TOTAL_REQUESTS"); do
            curl -s -X POST -H "Content-Type: application/json" -d "$payload" "$ENDPOINT" >/dev/null &

            # Limit concurrent requests
            if (( i % CONCURRENT_REQUESTS == 0 )); then
                wait
            fi
        done
        wait

        end_time=$(date +%s.%N)
        duration=$(echo "$end_time - $start_time" | bc)
        rps=$(echo "scale=2; $TOTAL_REQUESTS / $duration" | bc)

        echo ""
        success "Benchmark completed!"
        echo "  Total requests: $TOTAL_REQUESTS"
        echo "  Duration: ${duration}s"
        echo "  Requests per second: $rps"
    fi
}

case "${1:-run}" in
    "run")
        run_benchmark
        ;;
    "help")
        echo "DialogChain Performance Benchmark"
        echo ""
        echo "Usage: $0 [run|help]"
        echo ""
        echo "Environment variables:"
        echo "  ENDPOINT              Target endpoint (default: http://localhost:8080/webhook)"
        echo "  CONCURRENT_REQUESTS   Concurrent requests (default: 10)"
        echo "  TOTAL_REQUESTS        Total requests (default: 100)"
        echo "  PAYLOAD_SIZE          Payload size: small|medium|large (default: small)"
        echo ""
        echo "Examples:"
        echo "  $0"
        echo "  TOTAL_REQUESTS=1000 CONCURRENT_REQUESTS=50 $0"
        echo "  PAYLOAD_SIZE=large $0"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Run '$0 help' for usage information"
        exit 1
        ;;
esac
