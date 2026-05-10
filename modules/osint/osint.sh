#!/bin/bash
#=============================================================
# NishantX - OSINT Module
#=============================================================

run_osint() {
    local domain="$1"
    local output_dir="$2"
    local osint_dir="${output_dir}/osint"

    log_module "OSINT COLLECTION"

    local total_tools=4
    local current=0

    # --- theHarvester ---
    show_progress $((++current)) $total_tools "OSINT"
    if require_tool theHarvester; then
        log_info "Running theHarvester..."
        theHarvester -d "$domain" -b all -l 500 2>/dev/null > "${osint_dir}/harvester.txt"
        log_success "theHarvester: completed"

        # Extract emails
        grep -oP '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' "${osint_dir}/harvester.txt" 2>/dev/null \
            | sort -u > "${osint_dir}/emails.txt"
        log_success "Emails found: $(count_lines "${osint_dir}/emails.txt")"
    fi

    # --- holehe ---
    show_progress $((++current)) $total_tools "OSINT"
    if require_tool holehe; then
        log_info "Running holehe for email account discovery..."
        # Use emails found by theHarvester
        if [[ -f "${osint_dir}/emails.txt" ]]; then
            head -5 "${osint_dir}/emails.txt" | while IFS= read -r email; do
                holehe "$email" 2>/dev/null >> "${osint_dir}/holehe.txt"
            done
            log_success "holehe: completed"
        fi
    fi

    # --- sherlock ---
    show_progress $((++current)) $total_tools "OSINT"
    if require_tool sherlock; then
        log_info "Running sherlock for social media accounts..."
        # Try with common usernames derived from domain
        local username="${domain%%.*}"
        sherlock "$username" --timeout 20 --print-found 2>/dev/null > "${osint_dir}/sherlock.txt"
        log_success "sherlock: $(count_lines "${osint_dir}/sherlock.txt") accounts found"
    fi

    # --- Built-in OSINT checks ---
    show_progress $((++current)) $total_tools "OSINT"
    log_info "Running built-in OSINT checks..."

    # Shodan (if API key available)
    if [[ -n "$SHODAN_API_KEY" ]]; then
        log_info "Querying Shodan..."
        curl -s "https://api.shodan.io/shodan/host/search?key=${SHODAN_API_KEY}&query=hostname:${domain}" 2>/dev/null \
            | jq '.' 2>/dev/null > "${osint_dir}/shodan.json"
        log_success "Shodan: completed"
    fi

    # SecurityTrails
    if [[ -n "$SECURITYTRAILS_API_KEY" ]]; then
        log_info "Querying SecurityTrails..."
        curl -s -H "APIKEY: ${SECURITYTRAILS_API_KEY}" "https://api.securitytrails.com/v1/domain/${domain}/subdomains" 2>/dev/null \
            | jq -r '.subdomains[]' 2>/dev/null | sed "s/$/.${domain}/" >> "${osint_dir}/securitytrails_subs.txt"
        log_success "SecurityTrails: $(count_lines "${osint_dir}/securitytrails_subs.txt") subdomains"
    fi

    # VirusTotal
    if [[ -n "$VIRUSTOTAL_API_KEY" ]]; then
        log_info "Querying VirusTotal..."
        curl -s "https://www.virustotal.com/vtapi/v2/domain/report?apikey=${VIRUSTOTAL_API_KEY}&domain=${domain}" 2>/dev/null \
            | jq '.' 2>/dev/null > "${osint_dir}/virustotal.json"
        log_success "VirusTotal: completed"
    fi

    # DNS Dumpster (via crt.sh already done, but add cert transparency)
    log_info "Querying certificate transparency logs..."
    curl -s "https://crt.sh/?q=${domain}&output=json" 2>/dev/null \
        | jq -r '.[].name_value' 2>/dev/null | sort -u > "${osint_dir}/ct_logs.txt"
    log_success "CT logs: $(count_lines "${osint_dir}/ct_logs.txt") entries"

    # Email harvesting from web
    log_info "Harvesting emails from web content..."
    local alive_file="${output_dir}/alive/alive.txt"
    if [[ -f "$alive_file" ]]; then
        while IFS= read -r host; do
            curl -s "$host" --max-time 10 2>/dev/null | \
                grep -oP '[a-zA-Z0-9._%+-]+@'"${domain//./\\.}" | sort -u >> "${osint_dir}/web_emails.txt"
        done < <(head -10 "$alive_file")
        dedup_file "${osint_dir}/web_emails.txt"
        log_success "Web emails: $(count_lines "${osint_dir}/web_emails.txt") found"
    fi

    # Merge all emails
    cat "${osint_dir}"/emails.txt "${osint_dir}"/web_emails.txt 2>/dev/null | sort -u > "${osint_dir}/all_emails.txt"

    # Metadata extraction
    log_info "Checking for document metadata..."
    local urls_file="${output_dir}/urls/all_urls.txt"
    if [[ -f "$urls_file" ]]; then
        grep -iE '\.(pdf|doc|docx|xls|xlsx|ppt|pptx)$' "$urls_file" 2>/dev/null | head -10 > "${osint_dir}/doc_urls.txt"
        log_success "Documents found: $(count_lines "${osint_dir}/doc_urls.txt")"
    fi

    log_success "OSINT collection complete"
}
