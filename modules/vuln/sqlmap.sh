#!/bin/bash
#=============================================================
# NishantX - SQL Injection Detection Module
#=============================================================

run_sqlmap_scan() {
    local domain="$1"
    local output_dir="$2"
    local sqlmap_dir="${output_dir}/sqlmap"
    local urls_file="${output_dir}/urls/all_urls.txt"
    local params_dir="${output_dir}/params"

    log_module "SQL INJECTION DETECTION"

    if ! require_tool sqlmap; then
        log_warn "sqlmap not found - skipping SQLi scan"
        return
    fi

    # Find URLs with parameters (potential injection points)
    local injectable_urls="${sqlmap_dir}/injectable_urls.txt"
    if [[ -f "$urls_file" ]]; then
        grep -E '\?.*=' "$urls_file" 2>/dev/null | sort -u > "$injectable_urls"
    fi

    local url_count
    url_count=$(count_lines "$injectable_urls")
    log_info "Found $url_count URLs with parameters to test"

    [[ "$url_count" -eq 0 ]] && return

    # Limit to top 50 URLs to avoid excessive scanning
    head -50 "$injectable_urls" > "${sqlmap_dir}/targets.txt"

    log_info "Running sqlmap batch scan..."
    sqlmap -m "${sqlmap_dir}/targets.txt" \
        --batch --level "$SQLMAP_LEVEL" --risk "$SQLMAP_RISK" \
        --threads "$THREADS" \
        --random-agent \
        --output-dir="${sqlmap_dir}/output" \
        --reports-dir="${sqlmap_dir}/reports" \
        --timeout=30 --retries="$RETRY_COUNT" \
        -o 2>/dev/null

    # Extract injection findings
    find "${sqlmap_dir}/output" -name "log" -exec grep -l "is injectable" {} \; 2>/dev/null > "${sqlmap_dir}/injectable.txt"
    find "${sqlmap_dir}/output" -name "log" -exec grep "is injectable" {} \; 2>/dev/null >> "${sqlmap_dir}/sqli_findings.txt"

    local sqli_count
    sqli_count=$(count_lines "${sqlmap_dir}/sqli_findings.txt")
    if [[ $sqli_count -gt 0 ]]; then
        log_critical "$sqli_count SQL injection points found!"
        notify_critical "$domain" "$sqli_count SQL injection points found by sqlmap"
    else
        log_success "sqlmap: No SQL injection found"
    fi
}
