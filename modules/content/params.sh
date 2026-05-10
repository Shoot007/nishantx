#!/bin/bash
#=============================================================
# NishantX - Parameter Discovery Module
#=============================================================

run_param_discovery() {
    local domain="$1"
    local output_dir="$2"
    local params_dir="${output_dir}/params"
    local all_params="${params_dir}/all_params.txt"

    log_module "PARAMETER DISCOVERY"

    local total_tools=2
    local current=0

    # --- paramspider ---
    show_progress $((++current)) $total_tools "Param Discovery"
    if require_tool paramspider; then
        log_info "Running paramspider..."
        paramspider -d "$domain" --level high --quiet -o "${params_dir}/paramspider_urls.txt" 2>/dev/null
        # Extract unique parameters
        if [[ -f "${params_dir}/paramspider_urls.txt" ]]; then
            grep -oP '(?<=\?|&)[^=]+' "${params_dir}/paramspider_urls.txt" 2>/dev/null | sort -u > "${params_dir}/paramspider_params.txt"
        fi
        log_success "paramspider: $(count_lines "${params_dir}/paramspider_params.txt") unique parameters"
    fi

    # --- arjun ---
    show_progress $((++current)) $total_tools "Param Discovery"
    if require_tool arjun; then
        log_info "Running arjun..."
        local alive_file="${output_dir}/alive/alive.txt"
        if [[ -f "$alive_file" ]]; then
            # Test a sample of alive hosts for parameters
            head -20 "$alive_file" | while IFS= read -r url; do
                arjun -u "$url" --stable -t "$THREADS" -o "${params_dir}/arjun_${url//[^a-zA-Z0-9]/_}.txt" 2>/dev/null
            done
            # Combine arjun results
            cat "${params_dir}"/arjun_*.txt 2>/dev/null | sort -u > "${params_dir}/arjun_params.txt"
            log_success "arjun: $(count_lines "${params_dir}/arjun_params.txt") parameter findings"
        else
            arjun -u "https://${domain}" --stable -t "$THREADS" -o "${params_dir}/arjun_single.txt" 2>/dev/null
            log_success "arjun: completed"
        fi
    fi

    # --- Extract parameters from collected URLs ---
    log_info "Extracting parameters from collected URLs..."
    local urls_file="${output_dir}/urls/all_urls.txt"
    if [[ -f "$urls_file" ]]; then
        grep -oP '(?<=\?|&)[^=]+' "$urls_file" 2>/dev/null | sort -u > "${params_dir}/url_extracted_params.txt"
        log_success "URL parameter extraction: $(count_lines "${params_dir}/url_extracted_params.txt") parameters"
    fi

    # --- Merge all ---
    cat "${params_dir}"/*params*.txt 2>/dev/null | sort -u > "$all_params"
    dedup_file "$all_params"

    local param_count
    param_count=$(count_lines "$all_params")
    log_success "Total unique parameters: $param_count"

    echo "$param_count"
}
