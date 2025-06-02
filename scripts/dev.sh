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
