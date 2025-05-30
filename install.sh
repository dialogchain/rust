#!/bin/bash

# DialogChain Universal Installer & Project Creator
# Supports Linux, macOS, and Windows (WSL/Git Bash)
# Usage: curl -sSL https://install.dialogchain.io | bash

set -euo pipefail

# =============================================================================
# Configuration and Constants
# =============================================================================

readonly DIALOGCHAIN_VERSION="0.1.0"
readonly INSTALL_DIR="${DIALOGCHAIN_HOME:-$HOME/.dialogchain}"
readonly BIN_DIR="$INSTALL_DIR/bin"
readonly CONFIG_DIR="$INSTALL_DIR/config"
readonly TEMPLATES_DIR="$INSTALL_DIR/templates"
readonly LOG_FILE="$INSTALL_DIR/install.log"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# System detection
OS=""
ARCH=""
PACKAGE_MANAGER=""

# =============================================================================
# Utility Functions
# =============================================================================

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" | tee -a "$LOG_FILE" >/dev/null
}

info() {
    echo -e "${BLUE}[INFO]${NC} $*"
    log "INFO: $*"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
    log "SUCCESS: $*"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
    log "WARNING: $*"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
    log "ERROR: $*"
}

fatal() {
    error "$*"
    exit 1
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# =============================================================================
# System Detection
# =============================================================================

detect_system() {
    info "Detecting system information..."

    # Detect OS
    case "$(uname -s)" in
        Linux*)     OS="linux";;
        Darwin*)    OS="macos";;
        CYGWIN*|MINGW*|MSYS*) OS="windows";;
        *)          fatal "Unsupported operating system: $(uname -s)";;
    esac

    # Detect Architecture
    case "$(uname -m)" in
        x86_64|amd64)   ARCH="x86_64";;
        arm64|aarch64)  ARCH="arm64";;
        armv7l)         ARCH="armv7";;
        *)              fatal "Unsupported architecture: $(uname -m)";;
    esac

    # Detect Package Manager
    if command_exists apt-get; then
        PACKAGE_MANAGER="apt"
    elif command_exists yum; then
        PACKAGE_MANAGER="yum"
    elif command_exists dnf; then
        PACKAGE_MANAGER="dnf"
    elif command_exists pacman; then
        PACKAGE_MANAGER="pacman"
    elif command_exists brew; then
        PACKAGE_MANAGER="brew"
    elif command_exists zypper; then
        PACKAGE_MANAGER="zypper"
    else
        warning "No supported package manager found. Manual installation required."
        PACKAGE_MANAGER="manual"
    fi

    success "System detected: $OS ($ARCH) with $PACKAGE_MANAGER"
}

# =============================================================================
# Dependency Installation
# =============================================================================

install_system_dependencies() {
    info "Installing system dependencies..."

    local deps=""
    case $OS in
        "linux")
            case $PACKAGE_MANAGER in
                "apt")
                    deps="curl wget git build-essential pkg-config libssl-dev python3 python3-pip nodejs npm docker.io"
                    sudo apt-get update
                    sudo apt-get install -y $deps
                    ;;
                "yum"|"dnf")
                    deps="curl wget git gcc gcc-c++ make pkgconfig openssl-devel python3 python3-pip nodejs npm docker"
                    sudo $PACKAGE_MANAGER install -y $deps
                    ;;
                "pacman")
                    deps="curl wget git base-devel openssl python python-pip nodejs npm docker"
                    sudo pacman -S --noconfirm $deps
                    ;;
                "zypper")
                    deps="curl wget git gcc gcc-c++ make pkg-config libopenssl-devel python3 python3-pip nodejs npm docker"
                    sudo zypper install -y $deps
                    ;;
                *)
                    warning "Please install manually: curl, wget, git, build tools, OpenSSL, Python3, Node.js, Docker"
                    ;;
            esac
            ;;
        "macos")
            if [[ $PACKAGE_MANAGER == "brew" ]]; then
                deps="curl wget git openssl python3 node docker"
                brew install $deps
            else
                warning "Please install Homebrew or manually install: curl, wget, git, OpenSSL, Python3, Node.js, Docker"
            fi
            ;;
        "windows")
            warning "On Windows, please ensure you have: Git, Python3, Node.js, Docker Desktop installed"
            ;;
    esac
}

install_rust() {
    if command_exists rustc; then
        info "Rust is already installed: $(rustc --version)"
        return
    fi

    info "Installing Rust toolchain..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable

    # Source cargo env
    source "$HOME/.cargo/env" 2>/dev/null || true

    if command_exists rustc; then
        success "Rust installed successfully: $(rustc --version)"
    else
        fatal "Failed to install Rust. Please install manually from https://rustup.rs/"
    fi
}

install_go() {
    if command_exists go; then
        info "Go is already installed: $(go version)"
        return
    fi

    info "Installing Go..."
    local go_version="1.21.5"
    local go_archive="go${go_version}.${OS}-${ARCH}.tar.gz"
    local go_url="https://golang.org/dl/${go_archive}"

    case $OS in
        "linux"|"macos")
            curl -L "$go_url" -o "/tmp/$go_archive"
            sudo tar -C /usr/local -xzf "/tmp/$go_archive"
            rm "/tmp/$go_archive"

            # Add to PATH if not already there
            if ! echo "$PATH" | grep -q "/usr/local/go/bin"; then
                echo 'export PATH=$PATH:/usr/local/go/bin' >> "$HOME/.bashrc"
                echo 'export PATH=$PATH:/usr/local/go/bin' >> "$HOME/.zshrc" 2>/dev/null || true
                export PATH=$PATH:/usr/local/go/bin
            fi
            ;;
        "windows")
            warning "Please install Go manually from https://golang.org/dl/"
            ;;
    esac

    if command_exists go; then
        success "Go installed successfully: $(go version)"
    else
        warning "Go installation may require manual PATH configuration"
    fi
}

install_python_deps() {
    info "Installing Python dependencies..."

    # Create virtual environment for DialogChain
    python3 -m venv "$INSTALL_DIR/python-env"
    source "$INSTALL_DIR/python-env/bin/activate"

    # Upgrade pip
    pip install --upgrade pip

    # Install common ML/AI packages
    pip install \
        torch torchvision torchaudio \
        ultralytics \
        opencv-python \
        numpy pandas scikit-learn \
        fastapi uvicorn \
        pika paho-mqtt \
        psycopg2-binary pymongo redis \
        prometheus-client \
        pyyaml toml

    deactivate
    success "Python environment created at $INSTALL_DIR/python-env"
}

install_node_deps() {
    info "Setting up Node.js environment..."

    # Create package.json for global DialogChain deps
    mkdir -p "$INSTALL_DIR/node-env"
    cd "$INSTALL_DIR/node-env"

    cat > package.json << 'EOF'
{
  "name": "dialogchain-node-env",
  "version": "1.0.0",
  "description": "Node.js environment for DialogChain processors",
  "dependencies": {
    "express": "^4.18.2",
    "ws": "^8.14.2",
    "mqtt": "^5.3.0",
    "axios": "^1.6.2",
    "pg": "^8.11.3",
    "mongodb": "^6.3.0",
    "redis": "^4.6.11",
    "prom-client": "^15.1.0",
    "yaml": "^2.3.4",
    "sharp": "^0.33.1"
  }
}
EOF

    npm install
    cd - >/dev/null
    success "Node.js environment created at $INSTALL_DIR/node-env"
}

setup_docker() {
    if ! command_exists docker; then
        warning "Docker not found. Some features will be unavailable."
        return
    fi

    info "Setting up Docker environment..."

    # Start Docker service if not running (Linux only)
    if [[ $OS == "linux" ]]; then
        if ! systemctl is-active --quiet docker; then
            sudo systemctl start docker
            sudo systemctl enable docker
        fi

        # Add current user to docker group
        if ! groups | grep -q docker; then
            sudo usermod -aG docker "$USER"
            warning "Added user to docker group. Please log out and log back in for changes to take effect."
        fi
    fi

    # Pull useful base images
    docker pull python:3.11-slim &
    docker pull node:18-alpine &
    docker pull golang:1.21-alpine &
    docker pull rust:1.75-slim &
    wait

    success "Docker environment configured"
}

# =============================================================================
# DialogChain Installation
# =============================================================================

create_directory_structure() {
    info "Creating DialogChain directory structure..."

    mkdir -p "$INSTALL_DIR"/{bin,config,templates,logs,projects,cache}
    mkdir -p "$TEMPLATES_DIR"/{examples,processors,triggers,outputs}

    # Create log file
    touch "$LOG_FILE"

    success "Directory structure created at $INSTALL_DIR"
}

install_dialogchain_cli() {
    info "Installing DialogChain CLI..."

    # For now, we'll create a comprehensive CLI script
    # In production, this would download pre-compiled binaries

    cat > "$BIN_DIR/dialogchain" << 'EOF'
#!/bin/bash

# DialogChain CLI Tool
set -euo pipefail

readonly DIALOGCHAIN_HOME="${DIALOGCHAIN_HOME:-$HOME/.dialogchain}"
readonly TEMPLATES_DIR="$DIALOGCHAIN_HOME/templates"
readonly PROJECTS_DIR="$DIALOGCHAIN_HOME/projects"

# Colors
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

show_help() {
    cat << 'HELP'
DialogChain CLI - Multi-language Pipeline Engine

USAGE:
    dialogchain <COMMAND> [OPTIONS]

COMMANDS:
    create <name>           Create new pipeline project
    init                    Initialize current directory as DialogChain project
    validate <config>       Validate pipeline configuration
    run <config>            Run pipeline from configuration
    dev <config>            Run pipeline in development mode with hot reload
    build <config>          Build pipeline for production deployment
    deploy <config>         Deploy pipeline to production
    logs [pipeline]         Show pipeline execution logs
    status                  Show status of running pipelines
    stop <pipeline>         Stop running pipeline
    templates               List available templates
    examples                Show example configurations
    doctor                  Check system dependencies
    version                 Show version information

OPTIONS:
    -h, --help              Show this help message
    -v, --verbose           Enable verbose output
    --env <environment>     Specify environment (dev, staging, prod)
    --config <file>         Override default config file

EXAMPLES:
    dialogchain create my-security-system
    dialogchain run pipeline.yaml
    dialogchain dev --env development pipeline.yaml
    dialogchain deploy --env production pipeline.yaml

For more information, visit: https://dialogchain.io/docs
HELP
}

create_project() {
    local project_name="$1"
    local project_dir="$PROJECTS_DIR/$project_name"

    if [[ -d "$project_dir" ]]; then
        error "Project '$project_name' already exists"
        exit 1
    fi

    info "Creating new DialogChain project: $project_name"

    mkdir -p "$project_dir"/{configs,processors,scripts,docker,docs}

    # Create main pipeline configuration
    cat > "$project_dir/pipeline.yaml" << 'YAML'
name: "PROJECT_NAME"
version: "1.0.0"
description: "Generated DialogChain pipeline"

triggers:
  - id: http_input
    type: http
    port: 8080
    path: /webhook
    enabled: true

processors:
  - id: main_processor
    type: python
    script: "processors/main.py"
    parallel: true
    timeout: 5000
    retry: 2
    dependencies: []

outputs:
  - id: console_output
    type: file
    path: "logs/output.log"
    format: "json"

settings:
  performance:
    max_concurrent: 10
    buffer_size: 1000
  monitoring:
    enabled: true
  security:
    require_auth: false
YAML

    # Replace PROJECT_NAME with actual name
    sed -i "s/PROJECT_NAME/$project_name/g" "$project_dir/pipeline.yaml"

    # Create example Python processor
    cat > "$project_dir/processors/main.py" << 'PYTHON'
#!/usr/bin/env python3
"""
Example DialogChain processor
Reads JSON data from stdin, processes it, and outputs to stdout
"""

import json
import sys
from datetime import datetime

def process_data(data):
    """Main processing function"""
    try:
        # Add timestamp
        data['processed_at'] = datetime.utcnow().isoformat()
        data['processor'] = 'main_processor'

        # Your processing logic here
        if 'message' in data:
            data['message'] = data['message'].upper()

        return data
    except Exception as e:
        return {'error': str(e), 'original_data': data}

def main():
    try:
        # Read input from stdin
        input_data = json.load(sys.stdin)

        # Process the data
        result = process_data(input_data)

        # Output result to stdout
        json.dump(result, sys.stdout, indent=2)

    except Exception as e:
        error_output = {'error': f'Processor failed: {str(e)}'}
        json.dump(error_output, sys.stdout, indent=2)
        sys.exit(1)

if __name__ == '__main__':
    main()
PYTHON

    chmod +x "$project_dir/processors/main.py"

    # Create Go processor example
    cat > "$project_dir/processors/main.go" << 'GO'
package main

import (
    "encoding/json"
    "fmt"
    "os"
    "time"
)

type ProcessorData struct {
    Message     string                 `json:"message,omitempty"`
    ProcessedAt string                 `json:"processed_at"`
    Processor   string                 `json:"processor"`
    Data        map[string]interface{} `json:"data,omitempty"`
}

func main() {
    var input map[string]interface{}

    // Read from stdin
    decoder := json.NewDecoder(os.Stdin)
    if err := decoder.Decode(&input); err != nil {
        fmt.Fprintf(os.Stderr, "Error reading input: %v\n", err)
        os.Exit(1)
    }

    // Process the data
    result := ProcessorData{
        ProcessedAt: time.Now().UTC().Format(time.RFC3339),
        Processor:   "go_processor",
        Data:        input,
    }

    if msg, ok := input["message"].(string); ok {
        result.Message = fmt.Sprintf("Processed: %s", msg)
    }

    // Output to stdout
    encoder := json.NewEncoder(os.Stdout)
    encoder.SetIndent("", "  ")
    if err := encoder.Encode(result); err != nil {
        fmt.Fprintf(os.Stderr, "Error encoding output: %v\n", err)
        os.Exit(1)
    }
}
GO

    # Create Docker configuration
    cat > "$project_dir/docker/Dockerfile" << 'DOCKERFILE'
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Make scripts executable
RUN chmod +x processors/*.py

EXPOSE 8080

CMD ["python", "-m", "dialogchain.runner", "pipeline.yaml"]
DOCKERFILE

    # Create requirements.txt
    cat > "$project_dir/requirements.txt" << 'REQUIREMENTS'
pyyaml>=6.0
requests>=2.31.0
paho-mqtt>=1.6.1
fastapi>=0.104.0
uvicorn>=0.24.0
websockets>=11.0
aiofiles>=23.0
prometheus-client>=0.19.0
psycopg2-binary>=2.9.7
redis>=5.0.0
REQUIREMENTS

    # Create docker-compose.yml
    cat > "$project_dir/docker-compose.yml" << 'COMPOSE'
version: '3.8'

services:
  dialogchain:
    build:
      context: .
      dockerfile: docker/Dockerfile
    ports:
      - "8080:8080"
    environment:
      - ENVIRONMENT=development
      - LOG_LEVEL=INFO
    volumes:
      - ./logs:/app/logs
      - ./configs:/app/configs
    depends_on:
      - redis
      - postgres

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: dialogchain
      POSTGRES_USER: dialogchain
      POSTGRES_PASSWORD: password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  mqtt:
    image: eclipse-mosquitto:2
    ports:
      - "1883:1883"
      - "9001:9001"
    volumes:
      - ./configs/mosquitto.conf:/mosquitto/config/mosquitto.conf

volumes:
  redis_data:
  postgres_data:
COMPOSE

    # Create README.md
    cat > "$project_dir/README.md" << 'README'
# PROJECT_NAME

DialogChain pipeline for automated data processing.

## Quick Start

1. **Development Mode:**
   ```bash
   dialogchain dev pipeline.yaml
   ```

2. **Production Build:**
   ```bash
   dialogchain build pipeline.yaml
   dialogchain deploy --env production pipeline.yaml
   ```

3. **Docker Deployment:**
   ```bash
   docker-compose up -d
   ```

## Project Structure

```
├── pipeline.yaml          # Main pipeline configuration
├── processors/            # Custom processors
│   ├── main.py            # Python processor example
│   └── main.go            # Go processor example
├── configs/               # Environment-specific configs
├── scripts/               # Utility scripts
├── docker/                # Docker configuration
├── docs/                  # Documentation
└── logs/                  # Log files
```

## Configuration

Edit `pipeline.yaml` to customize your pipeline:

- **Triggers**: Define input sources (HTTP, MQTT, timers, etc.)
- **Processors**: Add data processing steps
- **Outputs**: Configure destinations for processed data

## Processors

### Python Processors
- Located in `processors/` directory
- Must read from stdin and write to stdout
- JSON format for data exchange

### Go Processors
- Compile with: `go build -o processors/processor processors/main.go`
- Same stdin/stdout interface

## Monitoring

- Logs: `dialogchain logs`
- Status: `dialogchain status`
- Metrics: Available at http://localhost:9090/metrics

## Deployment

### Local Development
```bash
dialogchain dev pipeline.yaml
```

### Production
```bash
dialogchain deploy --env production pipeline.yaml
```

### Docker
```bash
docker-compose up -d
```

For more information, visit: https://dialogchain.io/docs
README

    sed -i "s/PROJECT_NAME/$project_name/g" "$project_dir/README.md"

    # Create .gitignore
    cat > "$project_dir/.gitignore" << 'GITIGNORE'
# DialogChain
logs/
cache/
*.log

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/
ENV/

# Go
*.exe
*.exe~
*.dll
*.so
*.dylib
*.test
*.out

# Node.js
node_modules/
npm-debug.log*
yarn-debug.log*

# Docker
.docker/

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db
GITIGNORE

    # Create environment configurations
    mkdir -p "$project_dir/configs"

    cat > "$project_dir/configs/development.yaml" << 'DEV_CONFIG'
environment: development
debug: true
log_level: DEBUG

settings:
  performance:
    max_concurrent: 5
    buffer_size: 100
  monitoring:
    enabled: true
    metrics_port: 9090
  security:
    require_auth: false
    rate_limit: 100
DEV_CONFIG

    cat > "$project_dir/configs/production.yaml" << 'PROD_CONFIG'
environment: production
debug: false
log_level: INFO

settings:
  performance:
    max_concurrent: 50
    buffer_size: 10000
  monitoring:
    enabled: true
    metrics_port: 9090
  security:
    require_auth: true
    rate_limit: 10000
    tls:
      cert_file: "/certs/server.crt"
      key_file: "/certs/server.key"
PROD_CONFIG

    success "Project '$project_name' created successfully at $project_dir"
    info "Next steps:"
    echo "  cd $project_dir"
    echo "  dialogchain dev pipeline.yaml"
}

case "${1:-help}" in
    "create")
        if [[ $# -lt 2 ]]; then
            error "Project name required"
            echo "Usage: dialogchain create <project_name>"
            exit 1
        fi
        create_project "$2"
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    "version"|"-v"|"--version")
        echo "DialogChain CLI v0.1.0"
        ;;
    *)
        error "Unknown command: $1"
        echo "Run 'dialogchain help' for usage information"
        exit 1
        ;;
esac
EOF

    chmod +x "$BIN_DIR/dialogchain"
    success "DialogChain CLI installed"
}

create_templates() {
    info "Creating project templates..."

    # Security System Template
    cat > "$TEMPLATES_DIR/examples/security_system.yaml" << 'EOF'
name: "smart_security_system"
version: "1.0.0"
description: "AI-powered security monitoring with real-time alerts"

triggers:
  - id: camera_feed
    type: http
    port: 8080
    path: /camera/frame
    enabled: true

  - id: motion_sensor
    type: mqtt
    broker: "mqtt://localhost:1883"
    topic: "sensors/motion"
    enabled: true

processors:
  - id: object_detection
    type: python
    script: "processors/yolo_detect.py"
    venv: "/opt/dialogchain/python-env"
    parallel: true
    timeout: 5000
    retry: 2
    dependencies: []
    environment:
      MODEL_PATH: "/models/yolov8n.pt"
      CONFIDENCE_THRESHOLD: "0.6"

  - id: threat_analysis
    type: go
    binary: "./processors/threat-analyzer"
    args: ["--confidence=0.7"]
    parallel: false
    timeout: 2000
    retry: 1
    dependencies: ["object_detection"]

outputs:
  - id: security_alert
    type: email
    smtp: "smtp://localhost:587"
    to: ["security@company.com"]
    condition: "threat_level > 0.8"

  - id: dashboard_update
    type: websocket
    url: "ws://dashboard:3000/alerts"
    batch_size: 10

settings:
  performance:
    max_concurrent: 10
    buffer_size: 1000
  monitoring:
    enabled: true
  security:
    require_auth: true
    rate_limit: 1000
EOF

    # IoT Data Processing Template
    cat > "$TEMPLATES_DIR/examples/iot_processing.yaml" << 'EOF'
name: "iot_data_processor"
version: "1.0.0"
description: "High-throughput IoT data processing and analytics"

triggers:
  - id: sensor_data
    type: mqtt
    broker: "mqtt://iot-broker:1883"
    topic: "sensors/+/data"
    enabled: true

  - id: api_endpoint
    type: http
    port: 8080
    path: /api/sensors
    enabled: true

processors:
  - id: data_validation
    type: rust_wasm
    wasm: "processors/validator.wasm"
    parallel: true
    timeout: 1000
    retry: 0
    dependencies: []

  - id: anomaly_detection
    type: python
    script: "processors/anomaly_detector.py"
    parallel: true
    timeout: 3000
    retry: 1
    dependencies: ["data_validation"]

  - id: aggregation
    type: go
    binary: "./processors/aggregator"
    parallel: false
    timeout: 2000
    retry: 1
    dependencies: ["anomaly_detection"]

outputs:
  - id: database_storage
    type: database
    connection: "postgresql://user:pass@localhost/iot"
    table: "sensor_readings"
    batch_size: 1000

  - id: real_time_dashboard
    type: websocket
    url: "ws://dashboard:3000/data"
    condition: "anomaly_score > 0.5"

settings:
  performance:
    max_concurrent: 100
    buffer_size: 10000
  monitoring:
    enabled: true
EOF

    success "Templates created"
}

update_shell_profile() {
    info "Updating shell profile..."

    local shell_profile=""
    if [[ -n "${BASH_VERSION:-}" ]]; then
        shell_profile="$HOME/.bashrc"
    elif [[ -n "${ZSH_VERSION:-}" ]]; then
        shell_profile="$HOME/.zshrc"
    else
        shell_profile="$HOME/.profile"
    fi

    # Add DialogChain to PATH
    if ! grep -q "DIALOGCHAIN_HOME" "$shell_profile" 2>/dev/null; then
        cat >> "$shell_profile" << EOF

# DialogChain Configuration
export DIALOGCHAIN_HOME="$INSTALL_DIR"
export PATH="\$DIALOGCHAIN_HOME/bin:\$PATH"
EOF
        success "Added DialogChain to PATH in $shell_profile"
    fi

    # Source the profile for current session
    export DIALOGCHAIN_HOME="$INSTALL_DIR"
    export PATH="$INSTALL_DIR/bin:$PATH"
}

# =============================================================================
# Health Check and Verification
# =============================================================================

verify_installation() {
    info "Verifying installation..."

    local errors=0

    # Check directories
    for dir in "$INSTALL_DIR" "$BIN_DIR" "$CONFIG_DIR" "$TEMPLATES_DIR"; do
        if [[ ! -d "$dir" ]]; then
            error "Directory missing: $dir"
            ((errors++))
        fi
    done

    # Check CLI
    if [[ ! -x "$BIN_DIR/dialogchain" ]]; then
        error "DialogChain CLI not executable"
        ((errors++))
    fi

    # Check dependencies
    local required_commands=("curl" "git" "python3" "pip")
    for cmd in "${required_commands[@]}"; do
        if ! command_exists "$cmd"; then
            error "Missing required command: $cmd"
            ((errors++))
        fi
    done

    if [[ $errors -eq 0 ]]; then
        success "Installation verification passed"
        return 0
    else
        error "Installation verification failed with $errors errors"
        return 1
    fi
}

show_completion_message() {
    cat << EOF

${GREEN}╔════════════════════════════════════════════════════════════════╗
║                    DialogChain Installation Complete!          ║
╚════════════════════════════════════════════════════════════════╝${NC}

${BLUE}Installation Summary:${NC}
  📁 Installation Directory: $INSTALL_DIR
  🔧 CLI Tool: $BIN_DIR/dialogchain
  📚 Templates: $TEMPLATES_DIR/examples/
  📖 Logs: $LOG_FILE

${BLUE}Quick Start:${NC}
  1. Create a new project:
     ${CYAN}dialogchain create my-first-pipeline${NC}

  2. Navigate to the project:
     ${CYAN}cd ~/.dialogchain/projects/my-first-pipeline${NC}

  3. Start development mode:
     ${CYAN}dialogchain dev pipeline.yaml${NC}

${BLUE}Available Commands:${NC}
  • ${CYAN}dialogchain create <name>${NC}     - Create new pipeline project
  • ${CYAN}dialogchain templates${NC}         - List available templates
  • ${CYAN}dialogchain examples${NC}          - Show example configurations
  • ${CYAN}dialogchain doctor${NC}            - Check system health
  • ${CYAN}dialogchain help${NC}              - Show detailed help

${BLUE}System Information:${NC}
  • Operating System: $OS ($ARCH)
  • Package Manager: $PACKAGE_MANAGER
  • Rust: $(command_exists rustc && rustc --version | cut -d' ' -f2 || echo "Not installed")
  • Python: $(python3 --version 2>/dev/null || echo "Not installed")
  • Node.js: $(node --version 2>/dev/null || echo "Not installed")
  • Go: $(go version 2>/dev/null | cut -d' ' -f3 || echo "Not installed")
  • Docker: $(docker --version 2>/dev/null | cut -d' ' -f3 | tr -d ',' || echo "Not installed")

${YELLOW}Next Steps:${NC}
  1. Restart your terminal or run: ${CYAN}source ~/.bashrc${NC}
  2. Verify installation: ${CYAN}dialogchain doctor${NC}
  3. Check out examples: ${CYAN}dialogchain examples${NC}
  4. Read documentation: ${CYAN}https://dialogchain.io/docs${NC}

${GREEN}Happy pipeline building! 🚀${NC}

EOF
}

run_doctor_check() {
    info "Running system health check..."

    echo ""
    echo "=== DialogChain System Health Check ==="
    echo ""

    # Check core dependencies
    local status_ok="${GREEN}✓${NC}"
    local status_warn="${YELLOW}⚠${NC}"
    local status_error="${RED}✗${NC}"

    echo "Core Dependencies:"
    command_exists curl && echo -e "  $status_ok curl" || echo -e "  $status_error curl (required)"
    command_exists git && echo -e "  $status_ok git" || echo -e "  $status_error git (required)"
    command_exists python3 && echo -e "  $status_ok python3 ($(python3 --version))" || echo -e "  $status_error python3 (required)"
    command_exists pip && echo -e "  $status_ok pip" || echo -e "  $status_warn pip (recommended)"

    echo ""
    echo "Language Runtimes:"
    command_exists rustc && echo -e "  $status_ok Rust ($(rustc --version | cut -d' ' -f2))" || echo -e "  $status_warn Rust (recommended)"
    command_exists go && echo -e "  $status_ok Go ($(go version | cut -d' ' -f3))" || echo -e "  $status_warn Go (recommended)"
    command_exists node && echo -e "  $status_ok Node.js ($(node --version))" || echo -e "  $status_warn Node.js (recommended)"

    echo ""
    echo "Container Runtime:"
    if command_exists docker; then
        if docker info >/dev/null 2>&1; then
            echo -e "  $status_ok Docker ($(docker --version | cut -d' ' -f3 | tr -d ',')) - Running"
        else
            echo -e "  $status_warn Docker ($(docker --version | cut -d' ' -f3 | tr -d ',')) - Not running"
        fi
    else
        echo -e "  $status_warn Docker (not installed)"
    fi

    echo ""
    echo "DialogChain Installation:"
    [[ -d "$INSTALL_DIR" ]] && echo -e "  $status_ok Installation directory" || echo -e "  $status_error Installation directory"
    [[ -x "$BIN_DIR/dialogchain" ]] && echo -e "  $status_ok CLI executable" || echo -e "  $status_error CLI executable"
    [[ -d "$TEMPLATES_DIR" ]] && echo -e "  $status_ok Templates" || echo -e "  $status_error Templates"

    if [[ -d "$INSTALL_DIR/python-env" ]]; then
        echo -e "  $status_ok Python environment"
    else
        echo -e "  $status_warn Python environment (not created)"
    fi

    if [[ -d "$INSTALL_DIR/node-env" ]]; then
        echo -e "  $status_ok Node.js environment"
    else
        echo -e "  $status_warn Node.js environment (not created)"
    fi

    echo ""
    echo "Network Connectivity:"
    if curl -s --max-time 5 https://api.github.com >/dev/null; then
        echo -e "  $status_ok Internet connectivity"
    else
        echo -e "  $status_warn Internet connectivity (limited)"
    fi

    echo ""
    echo "System Resources:"
    echo "  Memory: $(free -h 2>/dev/null | awk '/^Mem:/ {print $2}' || echo "Unknown")"
    echo "  Disk Space: $(df -h "$INSTALL_DIR" 2>/dev/null | awk 'NR==2 {print $4}' || echo "Unknown") available"
    echo "  CPU Cores: $(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo "Unknown")"

    echo ""
}

# =============================================================================
# Main Installation Flow
# =============================================================================

main() {
    echo -e "${PURPLE}"
    cat << 'LOGO'
    ____  _       _             _____ _           _
   |  _ \(_)     | |           / ____| |         (_)
   | |_) |_  __ _| | ___   ___| |    | |__   __ _ _ _ __
   |  _ <| |/ _` | |/ _ \ / __| |    | '_ \ / _` | | '_ \
   | |_) | | (_| | | (_) | (__| |____| | | | (_| | | | | |
   |____/|_|\__,_|_|\___/ \___|\_____|_| |_|\__,_|_|_| |_|

   Multi-Language Pipeline Engine for Modern Integration
LOGO
    echo -e "${NC}"

    info "Starting DialogChain installation..."
    info "This installer will set up DialogChain and all required dependencies"

    # Check if running as root (not recommended)
    if [[ $EUID -eq 0 ]]; then
        warning "Running as root is not recommended. Consider running as a regular user."
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    # Create log directory early
    mkdir -p "$(dirname "$LOG_FILE")"

    # System detection
    detect_system

    # Create directory structure
    create_directory_structure

    # Install dependencies
    info "Installing system dependencies (this may take a few minutes)..."
    install_system_dependencies

    # Install language runtimes
    install_rust
    install_go

    # Setup language environments
    install_python_deps &
    PYTHON_PID=$!

    install_node_deps &
    NODE_PID=$!

    # Setup container runtime
    setup_docker &
    DOCKER_PID=$!

    # Install DialogChain CLI
    install_dialogchain_cli

    # Create templates
    create_templates

    # Wait for background processes
    info "Waiting for language environments to complete..."
    wait $PYTHON_PID
    wait $NODE_PID
    wait $DOCKER_PID

    # Update shell profile
    update_shell_profile

    # Verify installation
    if verify_installation; then
        success "DialogChain installed successfully!"

        # Run doctor check
        run_doctor_check

        # Show completion message
        show_completion_message
    else
        fatal "Installation failed. Check $LOG_FILE for details."
    fi
}

# =============================================================================
# CLI Extensions for Post-Installation
# =============================================================================

# Add these functions to the CLI tool
add_cli_extensions() {
    cat >> "$BIN_DIR/dialogchain" << 'EOF'

init_project() {
    local current_dir=$(pwd)
    local project_name=$(basename "$current_dir")

    if [[ -f "pipeline.yaml" ]]; then
        error "DialogChain project already exists in current directory"
        exit 1
    fi

    info "Initializing DialogChain project in current directory: $project_name"

    # Create basic structure
    mkdir -p processors scripts configs logs

    # Create basic pipeline.yaml
    cat > pipeline.yaml << 'YAML'
name: "PROJECT_NAME"
version: "1.0.0"
description: "DialogChain pipeline"

triggers:
  - id: main_trigger
    type: http
    port: 8080
    path: /webhook
    enabled: true

processors:
  - id: main_processor
    type: python
    script: "processors/main.py"
    parallel: true
    timeout: 5000
    retry: 2

outputs:
  - id: main_output
    type: file
    path: "logs/output.log"
    format: "json"

settings:
  performance:
    max_concurrent: 10
    buffer_size: 1000
  monitoring:
    enabled: true
YAML

    sed -i "s/PROJECT_NAME/$project_name/g" pipeline.yaml

    # Create basic processor
    cat > processors/main.py << 'PYTHON'
#!/usr/bin/env python3
import json
import sys
from datetime import datetime

def main():
    try:
        data = json.load(sys.stdin)
        data['processed_at'] = datetime.utcnow().isoformat()
        data['processor'] = 'main_processor'
        json.dump(data, sys.stdout, indent=2)
    except Exception as e:
        json.dump({'error': str(e)}, sys.stdout)
        sys.exit(1)

if __name__ == '__main__':
    main()
PYTHON

    chmod +x processors/main.py

    # Create .gitignore
    cat > .gitignore << 'GITIGNORE'
logs/
cache/
*.log
__pycache__/
.env
GITIGNORE

    success "DialogChain project initialized in $current_dir"
    info "Next steps:"
    echo "  dialogchain dev pipeline.yaml"
}

validate_config() {
    local config_file="$1"

    if [[ ! -f "$config_file" ]]; then
        error "Configuration file not found: $config_file"
        exit 1
    fi

    info "Validating configuration: $config_file"

    # Basic YAML syntax check
    if command_exists python3; then
        python3 -c "
import yaml
import sys

try:
    with open('$config_file', 'r') as f:
        config = yaml.safe_load(f)

    # Basic structure validation
    required_fields = ['name', 'triggers', 'processors', 'outputs']
    for field in required_fields:
        if field not in config:
            print(f'ERROR: Missing required field: {field}')
            sys.exit(1)

    print('✓ YAML syntax is valid')
    print('✓ Required fields present')
    print('✓ Configuration appears valid')

except yaml.YAMLError as e:
    print(f'ERROR: Invalid YAML syntax: {e}')
    sys.exit(1)
except Exception as e:
    print(f'ERROR: {e}')
    sys.exit(1)
"
    else
        warning "Python3 not available for YAML validation"
    fi

    success "Configuration validation completed"
}

show_templates() {
    info "Available DialogChain templates:"
    echo ""

    if [[ -d "$TEMPLATES_DIR/examples" ]]; then
        for template in "$TEMPLATES_DIR/examples"/*.yaml; do
            if [[ -f "$template" ]]; then
                local name=$(basename "$template" .yaml)
                local description=$(grep "description:" "$template" | cut -d'"' -f2)
                echo -e "  ${GREEN}$name${NC}"
                echo -e "    $description"
                echo ""
            fi
        done
    else
        warning "No templates found. Run the installer to create templates."
    fi

    info "To use a template:"
    echo "  dialogchain create my-project --template security_system"
}

show_examples() {
    cat << 'EXAMPLES'
DialogChain Configuration Examples

1. Simple HTTP to File Pipeline:
---
name: "http_logger"
triggers:
  - id: webhook
    type: http
    port: 8080
    path: /log
processors:
  - id: timestamp_processor
    type: python
    script: "add_timestamp.py"
outputs:
  - id: file_logger
    type: file
    path: "logs/requests.log"

2. IoT MQTT Processing:
---
name: "iot_processor"
triggers:
  - id: sensors
    type: mqtt
    broker: "mqtt://localhost:1883"
    topic: "sensors/+/data"
processors:
  - id: data_validator
    type: go
    binary: "./validator"
  - id: anomaly_detector
    type: python
    script: "detect_anomalies.py"
    dependencies: ["data_validator"]
outputs:
  - id: database
    type: database
    connection: "postgresql://localhost/iot"
    table: "sensor_data"

3. Multi-language Processing Chain:
---
name: "multi_lang_pipeline"
triggers:
  - id: api_input
    type: http
    port: 8080
processors:
  - id: rust_preprocessor
    type: rust_wasm
    wasm: "preprocessor.wasm"
  - id: python_ml
    type: python
    script: "ml_inference.py"
    dependencies: ["rust_preprocessor"]
  - id: go_postprocessor
    type: go
    binary: "./postprocessor"
    dependencies: ["python_ml"]
outputs:
  - id: websocket_stream
    type: websocket
    url: "ws://dashboard:3000/results"

For more examples, visit: https://dialogchain.io/examples
EXAMPLES
}

run_development_mode() {
    local config_file="$1"
    local env="${2:-development}"

    info "Starting DialogChain in development mode..."
    info "Configuration: $config_file"
    info "Environment: $env"

    # Validate configuration first
    validate_config "$config_file"

    info "Development server starting..."
    echo "  • Hot reload enabled"
    echo "  • Debug mode active"
    echo "  • Logs: tail -f logs/development.log"
    echo "  • Press Ctrl+C to stop"
    echo ""

    # This would integrate with the actual Rust engine
    # For now, simulate development mode
    while true; do
        echo "$(date '+%H:%M:%S') - Pipeline running... (simulated)"
        sleep 5
    done
}

doctor_check() {
    run_doctor_check
}

# Update the main case statement
case "${1:-help}" in
    "create")
        if [[ $# -lt 2 ]]; then
            error "Project name required"
            echo "Usage: dialogchain create <project_name>"
            exit 1
        fi
        create_project "$2"
        ;;
    "init")
        init_project
        ;;
    "validate")
        if [[ $# -lt 2 ]]; then
            error "Configuration file required"
            echo "Usage: dialogchain validate <config_file>"
            exit 1
        fi
        validate_config "$2"
        ;;
    "dev")
        if [[ $# -lt 2 ]]; then
            error "Configuration file required"
            echo "Usage: dialogchain dev <config_file> [environment]"
            exit 1
        fi
        run_development_mode "$2" "${3:-development}"
        ;;
    "templates")
        show_templates
        ;;
    "examples")
        show_examples
        ;;
    "doctor")
        doctor_check
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    "version"|"-v"|"--version")
        echo "DialogChain CLI v0.1.0"
        ;;
    *)
        error "Unknown command: $1"
        echo "Run 'dialogchain help' for usage information"
        exit 1
        ;;
esac
EOF

    success "CLI extensions added"
}

# =============================================================================
# Entry Point
# =============================================================================

# Handle script arguments
case "${1:-install}" in
    "install"|"")
        main "$@"
        ;;
    "doctor")
        detect_system
        run_doctor_check
        ;;
    "uninstall")
        if [[ -d "$INSTALL_DIR" ]]; then
            read -p "Remove DialogChain installation at $INSTALL_DIR? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rm -rf "$INSTALL_DIR"
                success "DialogChain uninstalled"
            fi
        else
            info "DialogChain not found at $INSTALL_DIR"
        fi
        ;;
    "help"|"-h"|"--help")
        cat << 'HELP'
DialogChain Installer

USAGE:
    curl -sSL https://install.dialogchain.io | bash [COMMAND]

COMMANDS:
    install      Install DialogChain (default)
    doctor       Run system health check
    uninstall    Remove DialogChain installation
    help         Show this help

ENVIRONMENT VARIABLES:
    DIALOGCHAIN_HOME    Installation directory (default: ~/.dialogchain)

EXAMPLES:
    # Standard installation
    curl -sSL https://install.dialogchain.io | bash

    # Custom installation directory
    DIALOGCHAIN_HOME=/opt/dialogchain curl -sSL https://install.dialogchain.io | bash

    # Check system compatibility
    curl -sSL https://install.dialogchain.io | bash -s doctor

For more information, visit: https://dialogchain.io/docs/installation
HELP
        ;;
    *)
        error "Unknown command: $1"
        echo "Run with 'help' for usage information"
        exit 1
        ;;
esac