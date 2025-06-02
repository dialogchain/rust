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
