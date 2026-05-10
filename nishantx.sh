#!/bin/bash
#=============================================================
#  ███╗   ██╗██╗███████╗██╗  ██╗ █████╗ ███╗   ██╗████████╗██╗  ██╗
#  ████╗  ██║██║██╔════╝██║  ██║██╔══██╗████╗  ██║╚══██╔══╝╚██╗██╔╝
#  ██╔██╗ ██║██║███████╗███████║███████║██╔██╗ ██║   ██║    ╚███╔╝
#  ██║╚██╗██║██║╚════██║██╔══██║██╔══██║██║╚██╗██║   ██║    ██╔██╗
#  ██║ ╚████║██║███████║██║  ██║██║  ██║██║ ╚████║   ██║   ██╔╝ ██╗
#  ╚═╝  ╚═══╝╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝
#
#  NishantX - Automated Recon & Vulnerability Assessment Framework
#  Version: 1.0.0
#  Purpose: Authorized penetration testing & security assessments only
#=============================================================

# set -e removed: individual modules handle errors gracefully

# --- Script directory ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Source core modules ---
source "${SCRIPT_DIR}/core/logging.sh"
source "${SCRIPT_DIR}/core/utils.sh"
source "${SCRIPT_DIR}/core/notifications.sh"

# --- Source recon modules ---
source "${SCRIPT_DIR}/modules/recon/subdomains.sh"
source "${SCRIPT_DIR}/modules/recon/alive.sh"
source "${SCRIPT_DIR}/modules/recon/dns.sh"
source "${SCRIPT_DIR}/modules/recon/ports.sh"
source "${SCRIPT_DIR}/modules/recon/techdetect.sh"

# --- Source content modules ---
source "${SCRIPT_DIR}/modules/content/urls.sh"
source "${SCRIPT_DIR}/modules/content/params.sh"
source "${SCRIPT_DIR}/modules/content/dirs.sh"
source "${SCRIPT_DIR}/modules/content/js.sh"

# --- Source vuln modules ---
source "${SCRIPT_DIR}/modules/vuln/nuclei.sh"
source "${SCRIPT_DIR}/modules/vuln/sqlmap.sh"
source "${SCRIPT_DIR}/modules/vuln/xss.sh"
source "${SCRIPT_DIR}/modules/vuln/ssl.sh"
source "${SCRIPT_DIR}/modules/vuln/waf.sh"
source "${SCRIPT_DIR}/modules/vuln/takeover.sh"
source "${SCRIPT_DIR}/modules/vuln/cloud.sh"
source "${SCRIPT_DIR}/modules/vuln/git.sh"

# --- Source OSINT module ---
source "${SCRIPT_DIR}/modules/osint/osint.sh"

# --- Source screenshot module ---
source "${SCRIPT_DIR}/modules/screenshot/screenshots.sh"

# --- Source report module ---
source "${SCRIPT_DIR}/modules/report/report.sh"

# --- Defaults ---
DOMAIN=""
DOMAIN_LIST=""
OUTPUT_DIR=""
THREADS=10
TIMEOUT=300
RATE_LIMIT=100
RETRY_COUNT=2
SILENT=false
VERBOSE=false
DEEP_SCAN=false
STEALTH_MODE=false
AGGRESSIVE_MODE=false
NOTIFY=false
RESUME=false
RESUME_FILE=""
CONFIG_FILE="${SCRIPT_DIR}/config/config.conf"
OUTPUT_BASE="results"
LOG_LEVEL="INFO"
SCAN_START_TIME=0

# --- Help ---
show_help() {
    print_banner
    cat << HELP
${BOLD}USAGE${RESET}
    ./nishantx.sh -d example.com [OPTIONS]

${BOLD}OPTIONS${RESET}
    ${CYAN}-h${RESET}              Show this help message
    ${CYAN}-d${RESET} <domain>     Target domain
    ${CYAN}-l${RESET} <file>       List of domains (one per line)
    ${CYAN}-o${RESET} <dir>        Output directory (default: results/<domain>)
    ${CYAN}-t${RESET} <threads>    Thread count (default: 10)
    ${CYAN}-s${RESET}              Silent mode (no terminal output)
    ${CYAN}-v${RESET}              Verbose mode
    ${CYAN}-r${RESET}              Resume previous scan
    ${CYAN}--deep${RESET}          Deep scan mode (more thorough, slower)
    ${CYAN}--stealth${RESET}       Stealth mode (rate limited, slower)
    ${CYAN}--aggressive${RESET}    Aggressive mode (faster, noisier)
    ${CYAN}--notify${RESET}        Enable notifications
    ${CYAN}--config${RESET} <file> Custom config file
    ${CYAN}--update${RESET}        Update NishantX and tools
    ${CYAN}--api-config${RESET}    Configure API keys interactively

${BOLD}EXAMPLES${RESET}
    ./nishantx.sh -d example.com
    ./nishantx.sh -d example.com --deep --notify
    ./nishantx.sh -d example.com -t 20 --stealth
    ./nishantx.sh -l domains.txt -o ./output

${BOLD}SCAN PHASES${RESET}
    1. Subdomain Enumeration
    2. Alive Host Discovery
    3. DNS Enumeration
    4. Port Scanning
    5. Technology Detection
    6. URL & Endpoint Collection
    7. Parameter Discovery
    8. Directory Fuzzing
    9. JavaScript Analysis
    10. Vulnerability Scanning (nuclei, sqlmap, xss)
    11. SSL/TLS Analysis
    12. WAF Detection
    13. Subdomain Takeover Check
    14. Cloud Enumeration
    15. Git & Secret Discovery
    16. Screenshot Collection
    17. OSINT Collection
    18. Report Generation

HELP
}

# --- Parse arguments ---
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -d)
                DOMAIN="$2"
                shift 2
                ;;
            -l)
                DOMAIN_LIST="$2"
                shift 2
                ;;
            -o)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            -t)
                THREADS="$2"
                shift 2
                ;;
            -s)
                SILENT=true
                shift
                ;;
            -v)
                VERBOSE=true
                shift
                ;;
            -r)
                RESUME=true
                shift
                ;;
            --deep)
                DEEP_SCAN=true
                shift
                ;;
            --stealth)
                STEALTH_MODE=true
                shift
                ;;
            --aggressive)
                AGGRESSIVE_MODE=true
                shift
                ;;
            --notify)
                NOTIFY=true
                shift
                ;;
            --config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            --update)
                run_update
                exit 0
                ;;
            --api-config)
                configure_apis
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# --- Configure API keys interactively ---
configure_apis() {
    print_banner
    echo -e "${CYAN}${BOLD}API Key Configuration${RESET}"
    echo -e ""

    read -rp "Shodan API Key: " SHODAN_API_KEY
    read -rp "Censys API ID: " CENSYS_API_ID
    read -rp "Censys API Secret: " CENSYS_API_SECRET
    read -rp "VirusTotal API Key: " VIRUSTOTAL_API_KEY
    read -rp "SecurityTrails API Key: " SECURITYTRAILS_API_KEY
    read -rp "GitHub Token: " GITHUB_TOKEN
    read -rp "Chaos API Key: " CHAOS_API_KEY
    read -rp "Telegram Bot Token: " TELEGRAM_BOT_TOKEN
    read -rp "Telegram Chat ID: " TELEGRAM_CHAT_ID
    read -rp "Discord Webhook URL: " DISCORD_WEBHOOK_URL
    read -rp "Slack Webhook URL: " SLACK_WEBHOOK_URL

    # Write to config
    cat > "$CONFIG_FILE" << CONFEOF
# NishantX Configuration - Auto-generated
THREADS=$THREADS
TIMEOUT=$TIMEOUT
RATE_LIMIT=$RATE_LIMIT
RETRY_COUNT=$RETRY_COUNT
SHODAN_API_KEY="$SHODAN_API_KEY"
CENSYS_API_ID="$CENSYS_API_ID"
CENSYS_API_SECRET="$CENSYS_API_SECRET"
VIRUSTOTAL_API_KEY="$VIRUSTOTAL_API_KEY"
SECURITYTRAILS_API_KEY="$SECURITYTRAILS_API_KEY"
GITHUB_TOKEN="$GITHUB_TOKEN"
CHAOS_API_KEY="$CHAOS_API_KEY"
TELEGRAM_BOT_TOKEN="$TELEGRAM_BOT_TOKEN"
TELEGRAM_CHAT_ID="$TELEGRAM_CHAT_ID"
DISCORD_WEBHOOK_URL="$DISCORD_WEBHOOK_URL"
SLACK_WEBHOOK_URL="$SLACK_WEBHOOK_URL"
NOTIFY=true
NUCLEI_TEMPLATES_DIR="\$HOME/nuclei-templates"
NUCLEI_SEVERITY="critical,high,medium"
PORT_TOP_PORTS=1000
PORT_SCAN_RATE=1000
DIRS_WORDLIST="/usr/share/wordlists/dirb/common.txt"
DNS_WORDLIST="/usr/share/wordlists/dnsrecon/namelist.txt"
SQLMAP_LEVEL=3
SQLMAP_RISK=2
SCREENSHOT_TIMEOUT=10
CONFEOF

    log_success "API keys saved to $CONFIG_FILE"
}

# --- Update function ---
run_update() {
    log_info "Updating NishantX tools..."
    if require_tool nuclei; then
        nuclei -ut 2>/dev/null
        log_success "nuclei templates updated"
    fi
    if require_tool subfinder; then
        subfinder -up 2>/dev/null || true
    fi
    log_success "Update complete"
}

# --- Pre-flight checks ---
preflight_checks() {
    # Check root (optional, some tools need it)
    if [[ $EUID -eq 0 ]]; then
        log_warn "Running as root - some tools may behave differently"
    fi

    # Check connectivity
    if ! check_connectivity; then
        log_error "No internet connectivity - aborting"
        exit 1
    fi

    # Validate domain
    if [[ -n "$DOMAIN" ]]; then
        if ! validate_domain "$DOMAIN"; then
            log_error "Invalid domain format: $DOMAIN"
            exit 1
        fi
    fi

    # Check essential tools
    local essential_tools=("jq" "curl" "nmap" "nuclei" "subfinder" "httpx")
    local missing=()
    for tool in "${essential_tools[@]}"; do
        if ! check_tool "$tool"; then
            missing+=("$tool")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_warn "Missing essential tools: ${missing[*]}"
        log_info "Run installer.sh to install dependencies"
    fi
}

# --- Run scan for a single domain ---
run_scan() {
    local domain="$1"
    local output_dir="${OUTPUT_DIR:-${SCRIPT_DIR}/${OUTPUT_BASE}/${domain}}"

    # Set resume file
    RESUME_FILE="${output_dir}/resume.state"

    # Create output directories
    create_output_dirs "$output_dir"

    # Init logging
    init_logging "$domain" "$output_dir"
    set_log_level "$LOG_LEVEL"

    # Record start time
    SCAN_START_TIME=$(date +%s)

    # Print banner
    print_banner
    echo -e "${WHITE}${BOLD}  Target: ${CYAN}${domain}${RESET}"
    echo -e "${WHITE}${BOLD}  Output: ${CYAN}${output_dir}${RESET}"
    echo -e "${WHITE}${BOLD}  Threads: ${CYAN}${THREADS}${RESET}"
    echo -e "${WHITE}${BOLD}  Mode: ${CYAN}$([ "$DEEP_SCAN" == "true" ] && echo "DEEP" || ([ "$STEALTH_MODE" == "true" ] && echo "STEALTH" || echo "NORMAL"))${RESET}"
    echo -e ""

    # Notify scan start
    notify_scan_start "$domain"

    # ===================== PHASE 1: SUBDOMAIN ENUMERATION =====================
    if [[ "$RESUME" == "true" ]] && is_module_done "$domain" "subdomains" "$RESUME_FILE"; then
        log_info "Skipping subdomain enum (resume mode)"
    else
        run_subdomain_enum "$domain" "$output_dir"
        save_resume_state "$domain" "subdomains" "$RESUME_FILE"
    fi

    # ===================== PHASE 2: ALIVE HOST DISCOVERY =====================
    if [[ "$RESUME" == "true" ]] && is_module_done "$domain" "alive" "$RESUME_FILE"; then
        log_info "Skipping alive check (resume mode)"
    else
        run_alive_check "$domain" "$output_dir"
        save_resume_state "$domain" "alive" "$RESUME_FILE"
    fi

    # ===================== PHASE 3: DNS ENUMERATION =====================
    if [[ "$RESUME" == "true" ]] && is_module_done "$domain" "dns" "$RESUME_FILE"; then
        log_info "Skipping DNS enum (resume mode)"
    else
        run_dns_enum "$domain" "$output_dir"
        save_resume_state "$domain" "dns" "$RESUME_FILE"
    fi

    # ===================== PHASE 4: PORT SCANNING =====================
    if [[ "$RESUME" == "true" ]] && is_module_done "$domain" "ports" "$RESUME_FILE"; then
        log_info "Skipping port scan (resume mode)"
    else
        run_port_scan "$domain" "$output_dir"
        save_resume_state "$domain" "ports" "$RESUME_FILE"
    fi

    # ===================== PHASE 5: TECHNOLOGY DETECTION =====================
    if [[ "$RESUME" == "true" ]] && is_module_done "$domain" "techdetect" "$RESUME_FILE"; then
        log_info "Skipping tech detection (resume mode)"
    else
        run_tech_detection "$domain" "$output_dir"
        save_resume_state "$domain" "techdetect" "$RESUME_FILE"
    fi

    # ===================== PHASE 6: URL COLLECTION =====================
    if [[ "$RESUME" == "true" ]] && is_module_done "$domain" "urls" "$RESUME_FILE"; then
        log_info "Skipping URL collection (resume mode)"
    else
        run_url_collection "$domain" "$output_dir"
        save_resume_state "$domain" "urls" "$RESUME_FILE"
    fi

    # ===================== PHASE 7: PARAMETER DISCOVERY =====================
    if [[ "$RESUME" == "true" ]] && is_module_done "$domain" "params" "$RESUME_FILE"; then
        log_info "Skipping param discovery (resume mode)"
    else
        run_param_discovery "$domain" "$output_dir"
        save_resume_state "$domain" "params" "$RESUME_FILE"
    fi

    # ===================== PHASE 8: DIRECTORY FUZZING =====================
    if [[ "$RESUME" == "true" ]] && is_module_done "$domain" "dirs" "$RESUME_FILE"; then
        log_info "Skipping directory fuzzing (resume mode)"
    else
        run_dir_fuzzing "$domain" "$output_dir"
        save_resume_state "$domain" "dirs" "$RESUME_FILE"
    fi

    # ===================== PHASE 9: JAVASCRIPT ANALYSIS =====================
    if [[ "$RESUME" == "true" ]] && is_module_done "$domain" "js" "$RESUME_FILE"; then
        log_info "Skipping JS analysis (resume mode)"
    else
        run_js_analysis "$domain" "$output_dir"
        save_resume_state "$domain" "js" "$RESUME_FILE"
    fi

    # ===================== PHASE 10: VULNERABILITY SCANNING =====================
    if [[ "$RESUME" == "true" ]] && is_module_done "$domain" "nuclei" "$RESUME_FILE"; then
        log_info "Skipping nuclei scan (resume mode)"
    else
        run_nuclei_scan "$domain" "$output_dir"
        save_resume_state "$domain" "nuclei" "$RESUME_FILE"
    fi

    # ===================== PHASE 11: SQL INJECTION =====================
    if [[ "$RESUME" == "true" ]] && is_module_done "$domain" "sqlmap" "$RESUME_FILE"; then
        log_info "Skipping SQLi scan (resume mode)"
    else
        run_sqlmap_scan "$domain" "$output_dir"
        save_resume_state "$domain" "sqlmap" "$RESUME_FILE"
    fi

    # ===================== PHASE 12: XSS DETECTION =====================
    if [[ "$RESUME" == "true" ]] && is_module_done "$domain" "xss" "$RESUME_FILE"; then
        log_info "Skipping XSS scan (resume mode)"
    else
        run_xss_scan "$domain" "$output_dir"
        save_resume_state "$domain" "xss" "$RESUME_FILE"
    fi

    # ===================== PHASE 13: SSL/TLS ANALYSIS =====================
    if [[ "$RESUME" == "true" ]] && is_module_done "$domain" "ssl" "$RESUME_FILE"; then
        log_info "Skipping SSL analysis (resume mode)"
    else
        run_ssl_analysis "$domain" "$output_dir"
        save_resume_state "$domain" "ssl" "$RESUME_FILE"
    fi

    # ===================== PHASE 14: WAF DETECTION =====================
    if [[ "$RESUME" == "true" ]] && is_module_done "$domain" "waf" "$RESUME_FILE"; then
        log_info "Skipping WAF detection (resume mode)"
    else
        run_waf_detection "$domain" "$output_dir"
        save_resume_state "$domain" "waf" "$RESUME_FILE"
    fi

    # ===================== PHASE 15: SUBDOMAIN TAKEOVER =====================
    if [[ "$RESUME" == "true" ]] && is_module_done "$domain" "takeover" "$RESUME_FILE"; then
        log_info "Skipping takeover check (resume mode)"
    else
        run_takeover_check "$domain" "$output_dir"
        save_resume_state "$domain" "takeover" "$RESUME_FILE"
    fi

    # ===================== PHASE 16: CLOUD ENUMERATION =====================
    if [[ "$RESUME" == "true" ]] && is_module_done "$domain" "cloud" "$RESUME_FILE"; then
        log_info "Skipping cloud enum (resume mode)"
    else
        run_cloud_enum "$domain" "$output_dir"
        save_resume_state "$domain" "cloud" "$RESUME_FILE"
    fi

    # ===================== PHASE 17: GIT & SECRET DISCOVERY =====================
    if [[ "$RESUME" == "true" ]] && is_module_done "$domain" "git" "$RESUME_FILE"; then
        log_info "Skipping git/secret scan (resume mode)"
    else
        run_git_secret_scan "$domain" "$output_dir"
        save_resume_state "$domain" "git" "$RESUME_FILE"
    fi

    # ===================== PHASE 18: SCREENSHOTS =====================
    if [[ "$RESUME" == "true" ]] && is_module_done "$domain" "screenshots" "$RESUME_FILE"; then
        log_info "Skipping screenshots (resume mode)"
    else
        run_screenshots "$domain" "$output_dir"
        save_resume_state "$domain" "screenshots" "$RESUME_FILE"
    fi

    # ===================== PHASE 19: OSINT =====================
    if [[ "$RESUME" == "true" ]] && is_module_done "$domain" "osint" "$RESUME_FILE"; then
        log_info "Skipping OSINT (resume mode)"
    else
        run_osint "$domain" "$output_dir"
        save_resume_state "$domain" "osint" "$RESUME_FILE"
    fi

    # ===================== PHASE 20: REPORT GENERATION =====================
    generate_report "$domain" "$output_dir"

    # Cleanup
    cleanup_temp "$output_dir"

    # Notify scan complete
    notify_scan_complete "$domain" "$output_dir"

    # Print summary
    print_summary "$domain" "$output_dir"
}

# --- Main ---
main() {
    parse_args "$@"

    # Load config
    load_config "$CONFIG_FILE"

    # If no domain or list provided, show help
    if [[ -z "$DOMAIN" ]] && [[ -z "$DOMAIN_LIST" ]]; then
        show_help
        exit 1
    fi

    # Pre-flight checks
    preflight_checks

    # Single domain scan
    if [[ -n "$DOMAIN" ]]; then
        run_scan "$DOMAIN"
    fi

    # Multi-domain scan from list
    if [[ -n "$DOMAIN_LIST" ]] && [[ -f "$DOMAIN_LIST" ]]; then
        while IFS= read -r domain; do
            [[ -z "$domain" ]] && continue
            [[ "$domain" =~ ^# ]] && continue
            log_info "Starting scan for: $domain"
            run_scan "$domain"
        done < "$DOMAIN_LIST"
    fi
}

main "$@"
