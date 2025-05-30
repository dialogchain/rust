#!/bin/bash
# DialogChain Dependencies Installation Module
# Handles installation of system dependencies and language runtimes

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