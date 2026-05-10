#!/bin/bash
#=============================================================
# NishantX - Core Logging System
#=============================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# Severity icons
ICON_CRITICAL="${RED}[-]${RESET}"
ICON_HIGH="${RED}[!]${RESET}"
ICON_MEDIUM="${YELLOW}[?]${RESET}"
ICON_LOW="${BLUE}[*]${RESET}"
ICON_INFO="${CYAN}[+]${RESET}"
ICON_SUCCESS="${GREEN}[$]${RESET}"

# Log levels: DEBUG=0, INFO=1, WARN=2, ERROR=3
LOG_LEVEL_DEBUG=0
LOG_LEVEL_INFO=1
LOG_LEVEL_WARN=2
LOG_LEVEL_ERROR=3

# Current log level (default INFO)
CURRENT_LOG_LEVEL=1

# Log file path (set per domain)
LOG_FILE=""

# Init logging for a domain
init_logging() {
    local domain="$1"
    local output_dir="$2"
    LOG_FILE="${output_dir}/logs/nishantx_$(date +%Y%m%d_%H%M%S).log"
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "=== NishantX Log - $(date) ===" > "$LOG_FILE"
}

# Set log level from config
set_log_level() {
    local level="$1"
    case "$level" in
        DEBUG) CURRENT_LOG_LEVEL=$LOG_LEVEL_DEBUG ;;
        INFO)  CURRENT_LOG_LEVEL=$LOG_LEVEL_INFO ;;
        WARN)  CURRENT_LOG_LEVEL=$LOG_LEVEL_WARN ;;
        ERROR) CURRENT_LOG_LEVEL=$LOG_LEVEL_ERROR ;;
        *)     CURRENT_LOG_LEVEL=$LOG_LEVEL_INFO ;;
    esac
}

# Core log function
_log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%H:%M:%S')

    local level_num
    case "$level" in
        DEBUG) level_num=$LOG_LEVEL_DEBUG ;;
        INFO)  level_num=$LOG_LEVEL_INFO ;;
        WARN)  level_num=$LOG_LEVEL_WARN ;;
        ERROR) level_num=$LOG_LEVEL_ERROR ;;
        *)     level_num=$LOG_LEVEL_INFO ;;
    esac

    # Skip if below current level
    [[ $level_num -lt $CURRENT_LOG_LEVEL ]] && return

    # Write to log file
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE" 2>/dev/null

    # Skip terminal output in silent mode
    [[ "$SILENT" == "true" ]] && return

    local prefix
    case "$level" in
        DEBUG) prefix="${GRAY}[DEBUG]${RESET}" ;;
        INFO)  prefix="${CYAN}[+]${RESET}" ;;
        WARN)  prefix="${YELLOW}[?]${RESET}" ;;
        ERROR) prefix="${RED}[!]${RESET}" ;;
        *)     prefix="${WHITE}[*]${RESET}" ;;
    esac

    echo -e "${DIM}${timestamp}${RESET} ${prefix} ${message}"
}

log_debug() { _log "DEBUG" "$@"; }
log_info()  { _log "INFO"  "$@"; }
log_warn()  { _log "WARN"  "$@"; }
log_error() { _log "ERROR" "$@"; }

# Success log (green)
log_success() {
    local message="$*"
    local timestamp
    timestamp=$(date '+%H:%M:%S')
    echo "[$timestamp] [SUCCESS] $message" >> "$LOG_FILE" 2>/dev/null
    [[ "$SILENT" == "true" ]] && return
    echo -e "${DIM}${timestamp}${RESET} ${GREEN}[\$]${RESET} ${GREEN}${message}${RESET}"
}

# Critical log (red + bold)
log_critical() {
    local message="$*"
    local timestamp
    timestamp=$(date '+%H:%M:%S')
    echo "[$timestamp] [CRITICAL] $message" >> "$LOG_FILE" 2>/dev/null
    [[ "$SILENT" == "true" ]] && return
    echo -e "${DIM}${timestamp}${RESET} ${RED}${BOLD}[-]${RESET} ${RED}${BOLD}${message}${RESET}"
}

# Module header
log_module() {
    local module_name="$1"
    local timestamp
    timestamp=$(date '+%H:%M:%S')
    echo "[$timestamp] [MODULE] $module_name" >> "$LOG_FILE" 2>/dev/null
    [[ "$SILENT" == "true" ]] && return
    echo -e ""
    echo -e "${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${MAGENTA}${BOLD}  $module_name${RESET}"
    echo -e "${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

# Progress bar
show_progress() {
    local current="$1"
    local total="$2"
    local description="$3"
    local width=40
    local percentage=$(( current * 100 / total ))
    local filled=$(( current * width / total ))
    local empty=$(( width - filled ))

    [[ "$SILENT" == "true" ]] && return

    local bar
    bar=$(printf '%*s' "$filled" '' | tr ' ' '█')
    bar+=$(printf '%*s' "$empty" '' | tr ' ' '░')

    echo -ne "\r${CYAN}${description}${RESET} [${GREEN}${bar}${RESET}] ${BOLD}${percentage}%${RESET} (${current}/${total})"
    [[ $current -eq $total ]] && echo ""
}

# Spinner
_spinner_pid=""

start_spinner() {
    local message="$1"
    [[ "$SILENT" == "true" ]] && return
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while true; do
        for i in $(seq 0 9); do
            echo -ne "\r${CYAN}${spin:$i:1}${RESET} ${message}   "
            sleep 0.1
        done
    done &
    _spinner_pid=$!
}

stop_spinner() {
    [[ -n "$_spinner_pid" ]] && kill "$_spinner_pid" 2>/dev/null
    _spinner_pid=""
    echo -ne "\r\033[K"
}

# Section divider
print_divider() {
    [[ "$SILENT" == "true" ]] && return
    echo -e "${DIM}────────────────────────────────────────────────────────${RESET}"
}

# Banner (called once at start)
print_banner() {
    echo -e "${RED}${BOLD}"
    echo -e '███╗   ██╗██╗███████╗██╗  ██╗ █████╗ ███╗   ██╗████████╗██╗  ██╗'
    echo -e '████╗  ██║██║██╔════╝██║  ██║██╔══██╗████╗  ██║╚══██╔══╝╚██╗██╔╝'
    echo -e '██╔██╗ ██║██║███████╗███████║███████║██╔██╗ ██║   ██║    ╚███╔╝ '
    echo -e '██║╚██╗██║██║╚════██║██╔══██║██╔══██║██║╚██╗██║   ██║    ██╔██╗ '
    echo -e '██║ ╚████║██║███████║██║  ██║██║  ██║██║ ╚████║   ██║   ██╔╝ ██╗'
    echo -e '╚═╝  ╚═══╝╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝'
    echo -e "${RESET}"
    echo -e "${WHITE}${BOLD}  [ Automated Recon & Vulnerability Assessment Framework ]${RESET}"
    echo -e "${GRAY}  Version 1.0.0 | Authorized Use Only${RESET}"
    echo -e ""
}

# Print scan summary
print_summary() {
    local domain="$1"
    local output_dir="$2"
    echo -e ""
    echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${GREEN}${BOLD}  SCAN COMPLETE${RESET}"
    echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${CYAN}  Target:${RESET}   $domain"
    echo -e "${CYAN}  Output:${RESET}   $output_dir"
    echo -e "${CYAN}  Log:${RESET}      $LOG_FILE"
    echo -e ""
}
