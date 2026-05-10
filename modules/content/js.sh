#!/bin/bash
#=============================================================
# NishantX - JavaScript Analysis Module
#=============================================================

run_js_analysis() {
    local domain="$1"
    local output_dir="$2"
    local js_dir="${output_dir}/js"
    local urls_file="${output_dir}/urls/all_urls.txt"

    log_module "JAVASCRIPT ANALYSIS"

    # Collect JS file URLs
    log_info "Collecting JavaScript file URLs..."
    if [[ -f "$urls_file" ]]; then
        grep -iE '\.js(\?|$| )' "$urls_file" 2>/dev/null | sort -u > "${js_dir}/js_urls.txt"
    fi

    # Also try to find JS from alive hosts
    local alive_file="${output_dir}/alive/alive.txt"
    if [[ -f "$alive_file" ]]; then
        while IFS= read -r host; do
            curl -s "$host" 2>/dev/null | grep -oP 'src="[^"]*\.js[^"]*"' | sed 's/src="//;s/"//' | sort -u >> "${js_dir}/js_urls.txt" 2>/dev/null
        done < <(head -5 "$alive_file")
    fi
    dedup_file "${js_dir}/js_urls.txt"

    local js_count
    js_count=$(count_lines "${js_dir}/js_urls.txt")
    log_info "Found $js_count JavaScript files"

    [[ "$js_count" -eq 0 ]] && return

    local total_tools=3
    local current=0

    # --- secretfinder ---
    show_progress $((++current)) $total_tools "JS Analysis"
    if require_tool SecretFinder; then
        log_info "Running SecretFinder for secrets in JS..."
        while IFS= read -r js_url; do
            SecretFinder -i "$js_url" -o "${js_dir}/secrets_${RANDOM}.txt" 2>/dev/null &
        done < "${js_dir}/js_urls.txt"
        wait
        cat "${js_dir}"/secrets_*.txt 2>/dev/null | sort -u > "${js_dir}/all_secrets.txt"
        dedup_file "${js_dir}/all_secrets.txt"
        log_success "SecretFinder: $(count_lines "${js_dir}/all_secrets.txt") secrets found"

        if [[ $(count_lines "${js_dir}/all_secrets.txt") -gt 0 ]]; then
            notify_critical "$domain" "JS secrets found - check ${js_dir}/all_secrets.txt"
        fi
    fi

    # --- linkfinder ---
    show_progress $((++current)) $total_tools "JS Analysis"
    if require_tool linkfinder; then
        log_info "Running LinkFinder for endpoints in JS..."
        while IFS= read -r js_url; do
            python3 /opt/LinkFinder/linkfinder.py -i "$js_url" -o cli 2>/dev/null >> "${js_dir}/linkfinder_endpoints.txt"
        done < <(head -50 "${js_dir}/js_urls.txt")
        dedup_file "${js_dir}/linkfinder_endpoints.txt"
        log_success "LinkFinder: $(count_lines "${js_dir}/linkfinder_endpoints.txt") endpoints found"
    fi

    # --- xnLinkFinder ---
    show_progress $((++current)) $total_tools "JS Analysis"
    if require_tool xnLinkFinder; then
        log_info "Running xnLinkFinder..."
        xnLinkFinder -i "https://${domain}" -o "${js_dir}/xnlinkfinder_endpoints.txt" 2>/dev/null
        dedup_file "${js_dir}/xnlinkfinder_endpoints.txt"
        log_success "xnLinkFinder: $(count_lines "${js_dir}/xnlinkfinder_endpoints.txt") endpoints found"
    fi

    # --- Built-in regex secret scan ---
    log_info "Running built-in regex secret scan on JS files..."
    local secret_patterns=(
        'api[_-]?key\s*[=:]\s*["\x27][a-zA-Z0-9]{16,}["\x27]'
        'secret[_-]?key\s*[=:]\s*["\x27][a-zA-Z0-9]{16,}["\x27]'
        'token\s*[=:]\s*["\x27][a-zA-Z0-9._-]{20,}["\x27]'
        'password\s*[=:]\s*["\x27][^"\x27]{4,}["\x27]'
        'AWS[_A-Z]*KEY\s*[=:]\s*["\x27][A-Z0-9]{20,}["\x27]'
        'ghp_[a-zA-Z0-9]{36}'
        'sk-[a-zA-Z0-9]{32,}'
        'AIza[a-zA-Z0-9_-]{35}'
        'eyJ[a-zA-Z0-9_-]*\.eyJ[a-zA-Z0-9_-]*\.[a-zA-Z0-9_-]*'
    )

    local tmp_js_dir="${js_dir}/downloaded"
    mkdir -p "$tmp_js_dir"

    # Download top 50 JS files
    head -50 "${js_dir}/js_urls.txt" | while IFS= read -r js_url; do
        local fname
        fname=$(echo "$js_url" | md5sum | cut -d' ' -f1)
        curl -s "$js_url" --max-time 10 -o "${tmp_js_dir}/${fname}.js" 2>/dev/null
    done

    # Scan for secrets
    for pattern in "${secret_patterns[@]}"; do
        grep -rP "$pattern" "${tmp_js_dir}/" 2>/dev/null >> "${js_dir}/regex_secrets.txt"
    done
    dedup_file "${js_dir}/regex_secrets.txt"

    if [[ -s "${js_dir}/regex_secrets.txt" ]]; then
        log_critical "Potential secrets found in JS files!"
        notify_critical "$domain" "Potential secrets found in JS files - check ${js_dir}/regex_secrets.txt"
    fi

    # Clean up downloaded files
    rm -rf "$tmp_js_dir"

    log_success "JavaScript analysis complete"
}
