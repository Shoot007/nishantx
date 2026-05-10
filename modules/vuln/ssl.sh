#!/bin/bash
#=============================================================
# NishantX - SSL/TLS Analysis Module
#=============================================================

run_ssl_analysis() {
    local domain="$1"
    local output_dir="$2"
    local ssl_dir="${output_dir}/ssl"

    log_module "SSL/TLS ANALYSIS"

    local total_tools=3
    local current=0

    # --- sslscan ---
    show_progress $((++current)) $total_tools "SSL Analysis"
    if require_tool sslscan; then
        log_info "Running sslscan..."
        sslscan --no-colour "$domain" 2>/dev/null > "${ssl_dir}/sslscan.txt"
        log_success "sslscan: completed"

        # Check for weak ciphers
        grep -i "weak\|insecure\|SSLv3\|SSLv2\|TLS 1.0\|TLS 1.1" "${ssl_dir}/sslscan.txt" 2>/dev/null > "${ssl_dir}/weak_ssl.txt"
        if [[ -s "${ssl_dir}/weak_ssl.txt" ]]; then
            log_warn "Weak SSL/TLS configurations detected!"
        fi
    fi

    # --- testssl.sh ---
    show_progress $((++current)) $total_tools "SSL Analysis"
    if require_tool testssl; then
        log_info "Running testssl.sh..."
        testssl --quiet --severity LOW -oL "${ssl_dir}/testssl" "$domain" 2>/dev/null
        log_success "testssl.sh: completed"
    fi

    # --- SSL certificate info ---
    show_progress $((++current)) $total_tools "SSL Analysis"
    log_info "Extracting SSL certificate details..."
    echo | openssl s_client -connect "${domain}:443" -servername "$domain" 2>/dev/null | \
        openssl x509 -noout -subject -issuer -dates -ext subjectAltName 2>/dev/null > "${ssl_dir}/cert_info.txt"

    # Check for expiring certs
    if [[ -f "${ssl_dir}/cert_info.txt" ]]; then
        local not_after
        not_after=$(grep "notAfter" "${ssl_dir}/cert_info.txt" | head -1)
        log_info "Certificate expiry: $not_after"
    fi

    log_success "SSL/TLS analysis complete"
}
