#!/bin/bash
#=============================================================
# NishantX - Technology Detection Module
#=============================================================

run_tech_detection() {
    local domain="$1"
    local output_dir="$2"
    local tech_dir="${output_dir}/alive"
    local alive_file="${output_dir}/alive/alive.txt"

    log_module "TECHNOLOGY DETECTION"

    local total_tools=3
    local current=0

    # --- httpx tech-detect (already done in alive check, extract here) ---
    show_progress $((++current)) $total_tools "Tech Detect"
    if [[ -f "${tech_dir}/httpx_full.txt" ]]; then
        log_info "Extracting technologies from httpx results..."
        grep -oP '\[([^\]]+)\]' "${tech_dir}/httpx_full.txt" 2>/dev/null | tr -d '[]' | sort -u > "${tech_dir}/technologies.txt"
        log_success "httpx tech: $(count_lines "${tech_dir}/technologies.txt") technologies detected"
    fi

    # --- whatweb ---
    show_progress $((++current)) $total_tools "Tech Detect"
    if require_tool whatweb; then
        log_info "Running whatweb..."
        if [[ -f "$alive_file" ]]; then
            whatweb -q --color=never "$(head -30 "$alive_file")" 2>/dev/null > "${tech_dir}/whatweb.txt"
            log_success "whatweb: $(count_lines "${tech_dir}/whatweb.txt") results"
        else
            whatweb -q --color=never "https://${domain}" 2>/dev/null > "${tech_dir}/whatweb.txt"
            log_success "whatweb: completed"
        fi
    fi

    # --- CMS detection ---
    show_progress $((++current)) $total_tools "Tech Detect"
    log_info "Running CMS-specific detection..."

    # wpscan (WordPress)
    if require_tool wpscan; then
        log_info "Running wpscan (WordPress)..."
        wpscan --url "https://${domain}" --disable-tls-checks --random-agent \
            --enumerate ap,at,cb,dbe,u,m \
            -o "${tech_dir}/wpscan.txt" 2>/dev/null
        if [[ -s "${tech_dir}/wpscan.txt" ]]; then
            log_success "wpscan: WordPress detected"
        fi
    fi

    # droopescan (Drupal)
    if require_tool droopescan; then
        log_info "Running droopescan (Drupal)..."
        droopescan scan drupal -u "https://${domain}" -t "$THREADS" 2>/dev/null > "${tech_dir}/droopescan.txt"
        if [[ -s "${tech_dir}/droopescan.txt" ]]; then
            log_success "droopescan: completed"
        fi
    fi

    # --- nikto ---
    if require_tool nikto; then
        log_info "Running nikto..."
        nikto -h "https://${domain}" -t "$THREADS" -maxtime 300 \
            -o "${tech_dir}/nikto.txt" -Format txt 2>/dev/null
        log_success "nikto: completed"
    fi

    log_success "Technology detection complete"
}
