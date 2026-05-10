#!/bin/bash
#=============================================================
# NishantX - XSS Detection Module
#=============================================================

run_xss_scan() {
    local domain="$1"
    local output_dir="$2"
    local xss_dir="${output_dir}/xss"
    local urls_file="${output_dir}/urls/all_urls.txt"

    log_module "XSS DETECTION"

    local injectable_urls="${xss_dir}/xss_targets.txt"
    if [[ -f "$urls_file" ]]; then
        grep -E '\?.*=' "$urls_file" 2>/dev/null | sort -u > "$injectable_urls"
    fi

    local url_count
    url_count=$(count_lines "$injectable_urls")
    log_info "Found $url_count URLs with parameters for XSS testing"

    local total_tools=2
    local current=0

    # --- dalfox ---
    show_progress $((++current)) $total_tools "XSS Scan"
    if require_tool dalfox; then
        log_info "Running dalfox..."
        if [[ -f "$injectable_urls" ]] && [[ $url_count -gt 0 ]]; then
            head -30 "$injectable_urls" | dalfox pipe -t "$THREADS" \
                --silence --only-poc \
                -o "${xss_dir}/dalfox_xss.txt" 2>/dev/null
            log_success "dalfox: $(count_lines "${xss_dir}/dalfox_xss.txt") XSS findings"
        fi
    fi

    # --- xsstrike ---
    show_progress $((++current)) $total_tools "XSS Scan"
    if require_tool xsstrike; then
        log_info "Running XSStrike..."
        if [[ -f "$injectable_urls" ]] && [[ $url_count -gt 0 ]]; then
            while IFS= read -r url; do
                xsstrike -u "$url" --batch --timeout 10 2>/dev/null >> "${xss_dir}/xsstrike_xss.txt"
            done < <(head -20 "$injectable_urls")
            dedup_file "${xss_dir}/xsstrike_xss.txt"
            log_success "XSStrike: $(count_lines "${xss_dir}/xsstrike_xss.txt") XSS findings"
        fi
    fi

    # Check for critical findings
    local xss_count
    xss_count=$(count_lines "${xss_dir}/dalfox_xss.txt")
    xss_count=$((xss_count + $(count_lines "${xss_dir}/xsstrike_xss.txt")))
    if [[ $xss_count -gt 0 ]]; then
        log_critical "$xss_count XSS findings detected!"
        notify_critical "$domain" "$xss_count XSS findings detected"
    fi

    log_success "XSS scanning complete"
}
