#!/bin/bash
# DialogChain System Detection Module
# Detects operating system, architecture, and package manager

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

get_system_info() {
    echo "OS: $OS"
    echo "Architecture: $ARCH"
    echo "Package Manager: $PACKAGE_MANAGER"
}