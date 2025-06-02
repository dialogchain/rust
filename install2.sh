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
