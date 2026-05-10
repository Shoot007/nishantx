#!/bin/bash
#=============================================================
# NishantX - Subdomain Enumeration Module
#=============================================================

run_subdomain_enum() {
    local domain="$1"
    local output_dir="$2"
    local subs_dir="${output_dir}/subdomains"
    local all_subs="${subs_dir}/subdomains.txt"
    local temp_dir="${output_dir}/temp"

    log_module "SUBDOMAIN ENUMERATION"
    local total_tools=9
    local current=0

    # --- subfinder ---
    show_progress $((++current)) $total_tools "Subdomain Enum"
    if require_tool subfinder; then
        log_info "Running subfinder..."
        subfinder -d "$domain" -t "$THREADS" -silent 2>/dev/null >> "${temp_dir}/subfinder.txt"
        log_success "subfinder: $(count_lines "${temp_dir}/subfinder.txt") subdomains"
    fi

    # --- assetfinder ---
    show_progress $((++current)) $total_tools "Subdomain Enum"
    if require_tool assetfinder; then
        log_info "Running assetfinder..."
        assetfinder --subs-only "$domain" 2>/dev/null >> "${temp_dir}/assetfinder.txt"
        log_success "assetfinder: $(count_lines "${temp_dir}/assetfinder.txt") subdomains"
    fi

    # --- amass ---
    show_progress $((++current)) $total_tools "Subdomain Enum"
    if require_tool amass; then
        log_info "Running amass (passive)..."
        if [[ "$DEEP_SCAN" == "true" ]]; then
            amass enum -d "$domain" -passive -o "${temp_dir}/amass.txt" 2>/dev/null
        else
            amass enum -d "$domain" -passive -timeout 5 -o "${temp_dir}/amass.txt" 2>/dev/null
        fi
        log_success "amass: $(count_lines "${temp_dir}/amass.txt") subdomains"
    fi

    # --- findomain ---
    show_progress $((++current)) $total_tools "Subdomain Enum"
    if require_tool findomain; then
        log_info "Running findomain..."
        findomain -t "$domain" -q 2>/dev/null >> "${temp_dir}/findomain.txt"
        log_success "findomain: $(count_lines "${temp_dir}/findomain.txt") subdomains"
    fi

    # --- chaos ---
    show_progress $((++current)) $total_tools "Subdomain Enum"
    if require_tool chaos; then
        log_info "Running chaos..."
        if [[ -n "$CHAOS_API_KEY" ]]; then
            chaos -d "$domain" -silent -key "$CHAOS_API_KEY" 2>/dev/null >> "${temp_dir}/chaos.txt"
        else
            chaos -d "$domain" -silent 2>/dev/null >> "${temp_dir}/chaos.txt"
        fi
        log_success "chaos: $(count_lines "${temp_dir}/chaos.txt") subdomains"
    fi

    # --- crt.sh ---
    show_progress $((++current)) $total_tools "Subdomain Enum"
    log_info "Scraping crt.sh..."
    curl -s "https://crt.sh/?q=%25.${domain}&output=json" 2>/dev/null \
        | jq -r '.[].name_value' 2>/dev/null \
        | sed 's/\*\.//g' \
        | sort -u >> "${temp_dir}/crtsh.txt"
    log_success "crt.sh: $(count_lines "${temp_dir}/crtsh.txt") subdomains"

    # --- github-subdomains ---
    show_progress $((++current)) $total_tools "Subdomain Enum"
    if require_tool github-subdomains; then
        log_info "Running github-subdomains..."
        if [[ -n "$GITHUB_TOKEN" ]]; then
            github-subdomains -d "$domain" -t "$THREADS" -q -token "$GITHUB_TOKEN" 2>/dev/null >> "${temp_dir}/github_subs.txt"
        else
            github-subdomains -d "$domain" -t "$THREADS" -q 2>/dev/null >> "${temp_dir}/github_subs.txt"
        fi
        log_success "github-subdomains: $(count_lines "${temp_dir}/github_subs.txt") subdomains"
    fi

    # --- waybackurls ---
    show_progress $((++current)) $total_tools "Subdomain Enum"
    if require_tool waybackurls; then
        log_info "Extracting subdomains from wayback..."
        echo "$domain" | waybackurls 2>/dev/null | sed 's|https\?://||' | sed 's/\/.*//' | sort -u >> "${temp_dir}/wayback_subs.txt"
        log_success "wayback subdomains: $(count_lines "${temp_dir}/wayback_subs.txt")"
    fi

    # --- gau ---
    show_progress $((++current)) $total_tools "Subdomain Enum"
    if require_tool gau; then
        log_info "Extracting subdomains from gau..."
        gau --subs "$domain" 2>/dev/null | sed 's|https\?://||' | sed 's/\/.*//' | sort -u >> "${temp_dir}/gau_subs.txt"
        log_success "gau subdomains: $(count_lines "${temp_dir}/gau_subs.txt")"
    fi

    # --- Merge and deduplicate ---
    log_info "Merging and deduplicating subdomains..."
    cat "${temp_dir}"/*subs*.txt "${temp_dir}"/subfinder.txt "${temp_dir}"/assetfinder.txt "${temp_dir}"/amass.txt "${temp_dir}"/findomain.txt "${temp_dir}"/chaos.txt "${temp_dir}"/crtsh.txt 2>/dev/null \
        | grep -i "\.${domain}$" \
        | sort -u > "$all_subs"

    local total_count
    total_count=$(count_lines "$all_subs")
    log_success "Total unique subdomains: $total_count"

    # --- DNS resolution with shuffledns + dnsx ---
    if [[ "$total_count" -gt 0 ]]; then
        if require_tool shuffledns; then
            log_info "Resolving subdomains with shuffledns..."
            shuffledns -d "$domain" -list "$all_subs" -t "$THREADS" -r "/usr/share/resolvers.txt" -silent 2>/dev/null > "${subs_dir}/resolved.txt"
            log_success "Resolved: $(count_lines "${subs_dir}/resolved.txt") subdomains"
        elif require_tool dnsx; then
            log_info "Resolving subdomains with dnsx..."
            dnsx -l "$all_subs" -silent -r -t "$THREADS" 2>/dev/null | cut -d' ' -f1 > "${subs_dir}/resolved.txt"
            log_success "Resolved: $(count_lines "${subs_dir}/resolved.txt") subdomains"
        fi

        # Use puredns if available for brute forcing
        if require_tool puredns && [[ "$DEEP_SCAN" == "true" ]]; then
            log_info "Brute-forcing subdomains with puredns..."
            puredns bruteforce "$DNS_WORDLIST" "$domain" --resolvers "/usr/share/resolvers.txt" -t "$THREADS" 2>/dev/null >> "${subs_dir}/resolved.txt"
            dedup_file "${subs_dir}/resolved.txt"
            log_success "After puredns: $(count_lines "${subs_dir}/resolved.txt") resolved subdomains"
        fi
    fi

    echo "$total_count"
}
