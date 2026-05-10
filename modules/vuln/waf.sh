#!/bin/bash
#=============================================================
# NishantX - WAF Detection Module
#=============================================================

run_waf_detection() {
    local domain="$1"
    local output_dir="$2"
    local waf_dir="${output_dir}/waf"

    log_module "WAF DETECTION"

    local total_tools=2
    local current=0

    # --- wafw00f ---
    show_progress $((++current)) $total_tools "WAF Detection"
    if require_tool wafw00f; then
        log_info "Running wafw00f..."
        wafw00f "https://${domain}" -a 2>/dev/null > "${waf_dir}/wafw00f.txt"
        log_success "wafw00f: completed"

        # Extract WAF name
        local waf_name
        waf_name=$(grep "is behind" "${waf_dir}/wafw00f.txt" 2>/dev/null | head -1)
        if [[ -n "$waf_name" ]]; then
            log_warn "WAF detected: $waf_name"
        else
            log_info "No WAF detected by wafw00f"
        fi
    fi

    # --- httpx WAF detection ---
    show_progress $((++current)) $total_tools "WAF Detection"
    if require_tool httpx; then
        log_info "Running httpx WAF detection..."
        local alive_file="${output_dir}/alive/alive.txt"
        if [[ -f "$alive_file" ]]; then
            httpx -l "$alive_file" -silent -waf -t "$THREADS" 2>/dev/null > "${waf_dir}/httpx_waf.txt"
            log_success "httpx WAF: $(count_lines "${waf_dir}/httpx_waf.txt") WAF detections"
        fi
    fi

    log_success "WAF detection complete"
}
