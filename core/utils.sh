#!/bin/bash
#=============================================================
# NishantX - Core Utility Functions
#=============================================================

# Check if a command/tool exists
check_tool() {
    command -v "$1" >/dev/null 2>&1
}

# Require a tool or exit with warning
require_tool() {
    local tool="$1"
    if ! check_tool "$tool"; then
        log_warn "Tool not found: $tool - skipping related scans"
        return 1
    fi
    return 0
}

# Create output directory structure for a domain
create_output_dirs() {
    local base="$1"
    local dirs=(
        "subdomains" "alive" "dns" "ports" "urls" "params"
        "dirs" "js" "nuclei" "sqlmap" "xss" "ssl" "waf"
        "cloud" "screenshots" "takeover" "osint" "reports"
        "logs" "temp"
    )
    for dir in "${dirs[@]}"; do
        mkdir -p "${base}/${dir}"
    done
}

# Deduplicate a file (sort + uniq)
dedup_file() {
    local filepath="$1"
    if [[ -f "$filepath" ]]; then
        sort -u "$filepath" -o "$filepath" 2>/dev/null
    fi
}

# Count lines in a file
count_lines() {
    local filepath="$1"
    if [[ -f "$filepath" ]]; then
        wc -l < "$filepath" | tr -d ' '
    else
        echo "0"
    fi
}

# Merge multiple files into one, deduplicated
merge_files() {
    local output="$1"
    shift
    cat "$@" 2>/dev/null | sort -u > "$output"
}

# Append to file if not already present
append_unique() {
    local filepath="$1"
    local line="$2"
    grep -qxF "$line" "$filepath" 2>/dev/null || echo "$line" >> "$filepath"
}

# Run a command with retry logic
run_with_retry() {
    local retries="${RETRY_COUNT:-2}"
    local attempt=1
    local cmd="$*"

    while [[ $attempt -le $retries ]]; do
        if eval "$cmd"; then
            return 0
        fi
        log_warn "Attempt $attempt/$retries failed for: $cmd"
        ((attempt++))
        sleep 2
    done
    log_error "All $retries attempts failed for: $cmd"
    return 1
}

# Run a command with timeout
run_with_timeout() {
    local timeout_val="${TIMEOUT:-300}"
    local cmd="$*"
    timeout "$timeout_val" eval "$cmd" 2>/dev/null
}

# Get random user agent
random_ua() {
    local uas=(
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36"
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_1) AppleWebKit/605.1.15 Safari/605.1.15"
        "Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/121.0"
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/119.0.0.0 Safari/537.36"
        "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:120.0) Gecko/20100101 Firefox/120.0"
    )
    echo "${uas[$RANDOM % ${#uas[@]}]}"
}

# Check internet connectivity
check_connectivity() {
    if ! curl -s -o /dev/null -w "%{http_code}" https://1.1.1.1 --max-time 5 2>/dev/null | grep -qE "^[0-9]"; then
        if ! ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1; then
            log_error "No internet connectivity detected"
            return 1
        fi
    fi
    log_debug "Internet connectivity OK"
    return 0
}

# Validate domain format
validate_domain() {
    local domain="$1"
    if [[ "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}$ ]]; then
        return 0
    fi
    return 1
}

# Read config file
load_config() {
    local config_file="$1"
    if [[ -f "$config_file" ]]; then
        # Source only variable assignments (skip comments and empty lines)
        while IFS= read -r line; do
            # Skip comments and empty lines
            [[ "$line" =~ ^[[:space:]]*# ]] && continue
            [[ -z "${line// }" ]] && continue
            # Only source KEY=VALUE lines
            if [[ "$line" =~ ^[A-Z_]+= ]]; then
                eval "$line" 2>/dev/null
            fi
        done < "$config_file"
        log_debug "Config loaded from $config_file"
    else
        log_warn "Config file not found: $config_file - using defaults"
    fi
}

# Save resume state
save_resume_state() {
    local domain="$1"
    local module="$2"
    local resume_file="$3"
    echo "${domain}:${module}:$(date +%s)" >> "$resume_file"
}

# Check if module was already completed (resume mode)
is_module_done() {
    local domain="$1"
    local module="$2"
    local resume_file="$3"
    if [[ -f "$resume_file" ]]; then
        grep -q "${domain}:${module}:" "$resume_file" 2>/dev/null
        return $?
    fi
    return 1
}

# Get file path for a module output
get_output_file() {
    local output_dir="$1"
    local module="$2"
    local ext="${3:-txt}"
    echo "${output_dir}/${module}/${module}.${ext}"
}

# Clean up temp files
cleanup_temp() {
    local output_dir="$1"
    rm -rf "${output_dir}/temp/"* 2>/dev/null
    log_debug "Temp files cleaned"
}

# Calculate scan duration
calc_duration() {
    local start="$1"
    local end="$2"
    local duration=$(( end - start ))
    local hours=$(( duration / 3600 ))
    local minutes=$(( (duration % 3600) / 60 ))
    local seconds=$(( duration % 60 ))
    printf "%02dh %02dm %02ds" "$hours" "$minutes" "$seconds"
}
