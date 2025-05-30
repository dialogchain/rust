#!/bin/bash
# DialogChain CLI Generator Module
# Creates the main CLI tool and project templates

install_dialogchain_cli() {
    info "Installing DialogChain CLI..."

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
    local template_name="${2:-basic}"
    local project_dir="$PROJECTS_DIR/$project_name"

    if [[ -d "$project_dir" ]]; then
        error "Project '$project_name' already exists"
        exit 1
    fi

    info "Creating new DialogChain project: $project_name"
    info "Using template: $template_name"

    # Call Python project generator
    python3 -c "
import sys
sys.path.append('$DIALOGCHAIN_HOME/bin')
from project_generator import DialogChainProjectGenerator

generator = DialogChainProjectGenerator('$project_name', '$template_name')
generator.project_path = '$project_dir'
generator.generate_project()
"

    success "Project '$project_name' created successfully!"
    info "Next steps:"
    echo "  cd $project_dir"
    echo "  ./scripts/dev.sh setup"
    echo "  ./scripts/dev.sh start"
}

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
node_modules/
target/
*.exe
*.dll
*.so
*.dylib
.DS_Store
Thumbs.db
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
    if command -v python3 >/dev/null; then
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

    cat << 'TEMPLATES'
Available Templates:

1. basic
   Description: Simple HTTP to file pipeline
   Use case: Basic data processing and logging

2. security
   Description: AI-powered security monitoring system
   Use case: Real-time threat detection with ML models

3. iot
   Description: High-throughput IoT data processing
   Use case: Sensor data aggregation and anomaly detection

4. microservices
   Description: Multi-language microservices integration hub
   Use case: Service-to-service communication and orchestration

Usage: dialogchain create <project-name> --template <template-name>
Example: dialogchain create my-project --template security
TEMPLATES
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
    # Source system detection module and run doctor check
    if [[ -f "$DIALOGCHAIN_HOME/bin/system_detection.sh" ]]; then
        source "$DIALOGCHAIN_HOME/bin/system_detection.sh"
        run_doctor_check
    else
        error "System detection module not found"
        exit 1
    fi
}

# Parse command line arguments
TEMPLATE_NAME="basic"
while [[ $# -gt 0 ]]; do
    case $1 in
        --template)
            TEMPLATE_NAME="$2"
            shift 2
            ;;
        *)
            break
            ;;
    esac
done

# Main command handling
case "${1:-help}" in
    "create")
        if [[ $# -lt 2 ]]; then
            error "Project name required"
            echo "Usage: dialogchain create <project_name> [--template <template_name>]"
            exit 1
        fi
        create_project "$2" "$TEMPLATE_NAME"
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