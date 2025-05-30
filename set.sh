#!/bin/bash
# DialogChain Setup and Utility Scripts Collection
# This file contains multiple utility scripts for project management

# =============================================================================
# 1. Quick Installation Script (install.sh)
# =============================================================================

create_quick_installer() {
    cat > install.sh << 'EOF'
#!/bin/bash
# DialogChain Quick Installer
set -e

echo "🚀 Installing DialogChain..."

# Check for required commands
for cmd in curl git python3; do
    if ! command -v $cmd >/dev/null 2>&1; then
        echo "❌ Error: $cmd is required but not installed"
        exit 1
    fi
done

# Download and run main installer
curl -sSL https://raw.githubusercontent.com/dialogchain/installer/main/install.sh | bash

echo "✅ DialogChain installation complete!"
echo "Run 'dialogchain create my-project' to get started"
EOF

    chmod +x install.sh
    echo "✅ Quick installer created: install.sh"
}

# =============================================================================
# 2. Development Environment Setup (dev-setup.sh)
# =============================================================================

create_dev_setup() {
    cat > dev-setup.sh << 'EOF'
#!/bin/bash
# DialogChain Development Environment Setup
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

PROJECT_DIR="$(pwd)"
PROJECT_NAME="$(basename "$PROJECT_DIR")"

setup_python_env() {
    info "Setting up Python environment..."

    if [[ ! -d "venv" ]]; then
        python3 -m venv venv
        success "Virtual environment created"
    fi

    source venv/bin/activate
    pip install --upgrade pip

    if [[ -f "requirements.txt" ]]; then
        pip install -r requirements.txt
        success "Python dependencies installed"
    fi
}

setup_node_env() {
    if [[ -f "package.json" ]] || [[ -f "processors/package.json" ]]; then
        info "Setting up Node.js environment..."

        if [[ -f "package.json" ]]; then
            npm install
        fi

        if [[ -f "processors/package.json" ]]; then
            cd processors && npm install && cd ..
        fi

        success "Node.js dependencies installed"
    fi
}

build_go_processors() {
    if find processors -name "*.go" -type f | head -1 | grep -q .; then
        info "Building Go processors..."

        find processors -name "main.go" -type f | while read -r go_file; do
            dir=$(dirname "$go_file")
            processor_name=$(basename "$dir")

            cd "$dir"
            if [[ -f "go.mod" ]]; then
                go build -o "../${processor_name}" .
                success "Built Go processor: ${processor_name}"
            fi
            cd - >/dev/null
        done
    fi
}

setup_docker() {
    if command -v docker >/dev/null 2>&1; then
        info "Setting up Docker environment..."

        if [[ -f "docker-compose.yml" ]]; then
            docker-compose pull
            success "Docker images pulled"
        fi
    else
        warning "Docker not found. Some features may be unavailable."
    fi
}

create_env_file() {
    if [[ ! -f ".env" ]]; then
        info "Creating environment file..."

        cat > .env << 'ENV'
# DialogChain Environment Configuration
ENVIRONMENT=development
LOG_LEVEL=DEBUG
PORT=8080

# Database
DATABASE_URL=postgresql://dialogchain:password@localhost:5432/dialogchain

# Redis
REDIS_URL=redis://localhost:6379

# MQTT
MQTT_BROKER=mqtt://localhost:1883

# Security (for production)
JWT_SECRET=your-secret-key-here
API_KEY=your-api-key-here
ENV

        success ".env file created"
    fi
}

run_tests() {
    info "Running tests..."

    # Python tests
    if [[ -d "tests" ]] && command -v pytest >/dev/null 2>&1; then
        source venv/bin/activate 2>/dev/null || true
        pytest tests/ -v
    fi

    # Go tests
    find processors -name "*.go" -type f | head -1 | grep -q . && {
        find processors -name "main.go" -type f | while read -r go_file; do
            dir=$(dirname "$go_file")
            cd "$dir" && go test . && cd - >/dev/null
        done
    }

    success "Tests completed"
}

case "${1:-setup}" in
    "setup")
        info "Setting up development environment for $PROJECT_NAME..."
        setup_python_env
        setup_node_env
        build_go_processors
        setup_docker
        create_env_file
        success "Development environment ready!"
        ;;
    "test")
        run_tests
        ;;
    "clean")
        info "Cleaning build artifacts..."
        rm -rf venv/ node_modules/ processors/node_modules/
        find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
        find . -name "*.pyc" -delete 2>/dev/null || true
        find processors -name "go.sum" -delete 2>/dev/null || true
        success "Clean completed"
        ;;
    *)
        echo "Usage: $0 {setup|test|clean}"
        exit 1
        ;;
esac
EOF

    chmod +x dev-setup.sh
    echo "✅ Development setup script created: dev-setup.sh"
}

# =============================================================================
# 3. Project Validator (validate-project.sh)
# =============================================================================

create_project_validator() {
    cat > validate-project.sh << 'EOF'
#!/bin/bash
# DialogChain Project Validator
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[✓]${NC} $*"; }
warning() { echo -e "${YELLOW}[⚠]${NC} $*"; }
error() { echo -e "${RED}[✗]${NC} $*"; }

ERRORS=0
WARNINGS=0

check_file() {
    local file="$1"
    local required="${2:-false}"

    if [[ -f "$file" ]]; then
        info "Found: $file"
    elif [[ "$required" == "true" ]]; then
        error "Missing required file: $file"
        ((ERRORS++))
    else
        warning "Missing optional file: $file"
        ((WARNINGS++))
    fi
}

check_directory() {
    local dir="$1"
    local required="${2:-false}"

    if [[ -d "$dir" ]]; then
        info "Found directory: $dir"
    elif [[ "$required" == "true" ]]; then
        error "Missing required directory: $dir"
        ((ERRORS++))
    else
        warning "Missing optional directory: $dir"
        ((WARNINGS++))
    fi
}

validate_yaml() {
    local file="$1"

    if [[ -f "$file" ]]; then
        if python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
            info "Valid YAML: $file"
        else
            error "Invalid YAML syntax: $file"
            ((ERRORS++))
        fi
    fi
}

echo "🔍 Validating DialogChain project structure..."
echo ""

# Check required files
check_file "pipeline.yaml" true
check_file "requirements.txt" false
check_file "Dockerfile" false
check_file "docker-compose.yml" false
check_file ".gitignore" false
check_file "README.md" false

# Check directories
check_directory "processors" true
check_directory "configs" false
check_directory "scripts" false
check_directory "tests" false
check_directory "logs" false

# Validate YAML files
echo ""
echo "📝 Validating configuration files..."
validate_yaml "pipeline.yaml"
for config in configs/*.yaml configs/*.yml; do
    [[ -f "$config" ]] && validate_yaml "$config"
done

# Check processors
echo ""
echo "🔧 Checking processors..."
if [[ -d "processors" ]]; then
    processor_count=$(find processors -name "*.py" -o -name "*.go" -o -name "*.js" | wc -l)
    if [[ $processor_count -gt 0 ]]; then
        info "Found $processor_count processor files"

        # Check Python processors
        find processors -name "*.py" | while read -r py_file; do
            if head -1 "$py_file" | grep -q "#!/usr/bin/env python3"; then
                info "Python processor: $(basename "$py_file")"
            else
                warning "Python processor missing shebang: $(basename "$py_file")"
                ((WARNINGS++))
            fi
        done

        # Check Go processors
        find processors -name "main.go" | while read -r go_file; do
            dir=$(dirname "$go_file")
            if [[ -f "$dir/go.mod" ]]; then
                info "Go processor: $(basename "$dir")"
            else
                warning "Go processor missing go.mod: $(basename "$dir")"
                ((WARNINGS++))
            fi
        done

    else
        error "No processor files found"
        ((ERRORS++))
    fi
fi

# Check scripts
echo ""
echo "📜 Checking scripts..."
if [[ -d "scripts" ]]; then
    find scripts -name "*.sh" | while read -r script; do
        if [[ -x "$script" ]]; then
            info "Executable script: $(basename "$script")"
        else
            warning "Non-executable script: $(basename "$script")"
            ((WARNINGS++))
        fi
    done
fi

# Summary
echo ""
echo "📊 Validation Summary:"
echo "  Errors: $ERRORS"
echo "  Warnings: $WARNINGS"

if [[ $ERRORS -eq 0 ]]; then
    echo ""
    info "✅ Project validation passed!"
    exit 0
else
    echo ""
    error "❌ Project validation failed with $ERRORS errors"
    exit 1
fi
EOF

    chmod +x validate-project.sh
    echo "✅ Project validator created: validate-project.sh"
}

# =============================================================================
# 4. Performance Benchmarking Script (benchmark.sh)
# =============================================================================

create_benchmark_script() {
    cat > benchmark.sh << 'EOF'
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
EOF

    chmod +x benchmark.sh
    echo "✅ Benchmark script created: benchmark.sh"
}

# =============================================================================
# 5. Log Analyzer Script (analyze-logs.sh)
# =============================================================================

create_log_analyzer() {
    cat > analyze-logs.sh << 'EOF'
#!/bin/bash
# DialogChain Log Analyzer
set -e

LOG_DIR="${LOG_DIR:-logs}"
TIME_RANGE="${TIME_RANGE:-1h}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

analyze_logs() {
    if [[ ! -d "$LOG_DIR" ]]; then
        error "Log directory not found: $LOG_DIR"
        exit 1
    fi

    info "Analyzing logs in $LOG_DIR (last $TIME_RANGE)..."
    echo ""

    # Find log files
    log_files=$(find "$LOG_DIR" -name "*.log" -type f)

    if [[ -z "$log_files" ]]; then
        warning "No log files found in $LOG_DIR"
        exit 0
    fi

    # Analyze each log file
    while read -r log_file; do
        if [[ -f "$log_file" ]]; then
            echo "📄 Analyzing: $(basename "$log_file")"

            # Count log levels
            if grep -q "ERROR\|WARN\|INFO\|DEBUG" "$log_file"; then
                echo "  Log levels:"
                grep -o "ERROR\|WARN\|INFO\|DEBUG" "$log_file" | sort | uniq -c | while read -r count level; do
                    case $level in
                        "ERROR") echo -e "    ${RED}ERROR${NC}: $count" ;;
                        "WARN")  echo -e "    ${YELLOW}WARN${NC}: $count" ;;
                        "INFO")  echo -e "    ${GREEN}INFO${NC}: $count" ;;
                        "DEBUG") echo -e "    ${BLUE}DEBUG${NC}: $count" ;;
                    esac
                done
            fi

            # Find errors
            error_count=$(grep -c "ERROR" "$log_file" 2>/dev/null || echo "0")
            if [[ $error_count -gt 0 ]]; then
                echo "  ❌ Recent errors:"
                grep "ERROR" "$log_file" | tail -3 | while read -r line; do
                    echo "    $line"
                done
            fi

            # Processing times (if available)
            if grep -q "duration\|took\|ms\|seconds" "$log_file"; then
                echo "  ⏱️  Performance indicators found"
            fi

            echo ""
        fi
    done <<< "$log_files"

    # Overall statistics
    echo "📊 Overall Statistics:"
    total_lines=$(wc -l $LOG_DIR/*.log 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
    echo "  Total log lines: $total_lines"

    total_errors=$(grep -c "ERROR" $LOG_DIR/*.log 2>/dev/null || echo "0")
    echo "  Total errors: $total_errors"

    if [[ $total_errors -gt 0 ]]; then
        error_rate=$(echo "scale=2; $total_errors * 100 / $total_lines" | bc 2>/dev/null || echo "N/A")
        echo "  Error rate: ${error_rate}%"
    fi
}

tail_logs() {
    info "Tailing logs in $LOG_DIR..."
    if command -v multitail >/dev/null 2>&1; then
        multitail $LOG_DIR/*.log
    else
        tail -f $LOG_DIR/*.log 2>/dev/null || {
            warning "No log files to tail"
            exit 1
        }
    fi
}

case "${1:-analyze}" in
    "analyze")
        analyze_logs
        ;;
    "tail")
        tail_logs
        ;;
    "clean")
        info "Cleaning old logs..."
        find "$LOG_DIR" -name "*.log" -mtime +7 -delete
        success "Old logs cleaned"
        ;;
    "help")
        echo "DialogChain Log Analyzer"
        echo ""
        echo "Usage: $0 [analyze|tail|clean|help]"
        echo ""
        echo "Environment variables:"
        echo "  LOG_DIR      Log directory (default: logs)"
        echo "  TIME_RANGE   Time range for analysis (default: 1h)"
        ;;
    *)
        echo "Unknown command: $1"
        exit 1
        ;;
esac
EOF

    chmod +x analyze-logs.sh
    echo "✅ Log analyzer created: analyze-logs.sh"
}

# =============================================================================
# Main Script Execution
# =============================================================================

main() {
    echo "🛠️  Creating DialogChain utility scripts..."
    echo ""

    create_quick_installer
    create_dev_setup
    create_project_validator
    create_benchmark_script
    create_log_analyzer

    echo ""
    echo "✅ All utility scripts created successfully!"
    echo ""
    echo "Available scripts:"
    echo "  📦 install.sh           - Quick DialogChain installation"
    echo "  🔧 dev-setup.sh         - Development environment setup"
    echo "  ✅ validate-project.sh   - Project structure validation"
    echo "  🚀 benchmark.sh         - Performance benchmarking"
    echo "  📊 analyze-logs.sh      - Log analysis and monitoring"
    echo ""
    echo "Usage examples:"
    echo "  ./install.sh"
    echo "  ./dev-setup.sh setup"
    echo "  ./validate-project.sh"
    echo "  ./benchmark.sh"
    echo "  ./analyze-logs.sh analyze"
}

# Run main function
main "$@"