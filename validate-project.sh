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
