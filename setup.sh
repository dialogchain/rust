#!/bin/bash

# DialogChain Universal Installer & Project Creator
# Main installation script
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

# =============================================================================
# Source additional modules
# =============================================================================

# Download and source system detection module
curl -sSL "https://raw.githubusercontent.com/dialogchain/installer/main/modules/system_detection.sh" > /tmp/system_detection.sh
source /tmp/system_detection.sh

# Download and source dependency installation module
curl -sSL "https://raw.githubusercontent.com/dialogchain/installer/main/modules/dependencies.sh" > /tmp/dependencies.sh
source /tmp/dependencies.sh

# Download and source CLI generation module
curl -sSL "https://raw.githubusercontent.com/dialogchain/installer/main/modules/cli_generator.sh" > /tmp/cli_generator.sh
source /tmp/cli_generator.sh

# =============================================================================
# Main Installation Flow
# =============================================================================

show_logo() {
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
}

create_directory_structure() {
    info "Creating DialogChain directory structure..."

    mkdir -p "$INSTALL_DIR"/{bin,config,templates,logs,projects,cache}
    mkdir -p "$TEMPLATES_DIR"/{examples,processors,triggers,outputs}

    # Create log file
    touch "$LOG_FILE"

    success "Directory structure created at $INSTALL_DIR"
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

main() {
    show_logo

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
# Entry Point
# =============================================================================

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

# Cleanup temporary files
rm -f /tmp/system_detection.sh /tmp/dependencies.sh /tmp/cli_generator.sh