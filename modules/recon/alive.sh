#!/bin/bash
#=============================================================
# NishantX - Alive Host Discovery Module
#=============================================================

run_alive_check() {
    local domain="$1"
    local output_dir="$2"
    local subs_file="${output_dir}/subdomains/subdomains.txt"
    local alive_dir="${output_dir}/alive"
    local alive_file="${alive_dir}/alive.txt"
    local alive_full="${alive_dir}/alive_full.txt"

    log_module "ALIVE HOST DISCOVERY"

    if [[ ! -f "$subs_file" ]] || [[ $(count_lines "$subs_file") -eq 0 ]]; then
        log_warn "No subdomains found - skipping alive check"
        echo "0"
        return
    fi

    local total_tools=2
    local current=0

    # --- httpx ---
    show_progress $((++current)) $total_tools "Alive Check"
    if require_tool httpx; then
        log_info "Running httpx for alive detection..."
        httpx -l "$subs_file" -silent -t "$THREADS" -rate-limit "$RATE_LIMIT" \
            -status-code -content-length -title -tech-detect -follow-redirects \
            -o "${alive_dir}/httpx_full.txt" 2>/dev/null

        # Extract just the URLs for alive list
        if [[ -f "${alive_dir}/httpx_full.txt" ]]; then
            cut -d' ' -f1 "${alive_dir}/httpx_full.txt" | sort -u > "$alive_file"
        fi
        log_success "httpx: $(count_lines "$alive_file") alive hosts"
    else
        # Fallback: simple curl probe
        log_warn "httpx not found - using curl fallback"
        while IFS= read -r sub; do
            if curl -s -o /dev/null -w "%{http_code}" "https://${sub}" --max-time 5 2>/dev/null | grep -qE "^[2-3]"; then
                echo "https://${sub}" >> "$alive_file"
            elif curl -s -o /dev/null -w "%{http_code}" "http://${sub}" --max-time 5 2>/dev/null | grep -qE "^[2-3]"; then
                echo "http://${sub}" >> "$alive_file"
            fi
        done < "$subs_file"
        dedup_file "$alive_file"
        log_success "curl probe: $(count_lines "$alive_file") alive hosts"
    fi

    # --- httprobe ---
    show_progress $((++current)) $total_tools "Alive Check"
    if require_tool httprobe; then
        log_info "Running httprobe for additional alive hosts..."
        cat "$subs_file" | httprobe -c "$THREADS" 2>/dev/null >> "${alive_dir}/httprobe.txt"
        cat "${alive_dir}/httprobe.txt" >> "$alive_file" 2>/dev/null
        dedup_file "$alive_file"
        log_success "httprobe: $(count_lines "${alive_dir}/httprobe.txt") additional hosts"
    fi

    # Copy full httpx output for tech detection
    if [[ -f "${alive_dir}/httpx_full.txt" ]]; then
        cp "${alive_dir}/httpx_full.txt" "$alive_full"
    fi

    local alive_count
    alive_count=$(count_lines "$alive_file")
    log_success "Total alive hosts: $alive_count"

    echo "$alive_count"
}
