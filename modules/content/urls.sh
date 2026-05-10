#!/bin/bash
#=============================================================
# NishantX - URL & Endpoint Collection Module
#=============================================================

run_url_collection() {
    local domain="$1"
    local output_dir="$2"
    local urls_dir="${output_dir}/urls"
    local all_urls="${urls_dir}/all_urls.txt"

    log_module "URL & ENDPOINT COLLECTION"

    local total_tools=5
    local current=0

    # --- gau ---
    show_progress $((++current)) $total_tools "URL Collection"
    if require_tool gau; then
        log_info "Running gau..."
        gau --subs "$domain" --threads "$THREADS" --blacklist png,jpg,gif,svg,css,woff,woff2,ttf,eot,ico,mp4,mp3,avi,flv 2>/dev/null > "${urls_dir}/gau_urls.txt"
        log_success "gau: $(count_lines "${urls_dir}/gau_urls.txt") URLs"
    fi

    # --- katana ---
    show_progress $((++current)) $total_tools "URL Collection"
    if require_tool katana; then
        log_info "Running katana..."
        local katana_opts="-d $domain -silent -t $THREADS -jc -aff -d 3"
        if [[ "$DEEP_SCAN" == "true" ]]; then
            katana_opts+=" -depth 5"
        fi
        eval katana $katana_opts -o "${urls_dir}/katana_urls.txt" 2>/dev/null
        log_success "katana: $(count_lines "${urls_dir}/katana_urls.txt") URLs"
    fi

    # --- hakrawler ---
    show_progress $((++current)) $total_tools "URL Collection"
    if require_tool hakrawler; then
        log_info "Running hakrawler..."
        echo "https://${domain}" | hakrawler -t "$THREADS" -d 3 -insecure 2>/dev/null > "${urls_dir}/hakrawler_urls.txt"
        log_success "hakrawler: $(count_lines "${urls_dir}/hakrawler_urls.txt") URLs"
    fi

    # --- waybackurls ---
    show_progress $((++current)) $total_tools "URL Collection"
    if require_tool waybackurls; then
        log_info "Running waybackurls..."
        echo "$domain" | waybackurls 2>/dev/null > "${urls_dir}/wayback_urls.txt"
        log_success "waybackurls: $(count_lines "${urls_dir}/wayback_urls.txt") URLs"
    fi

    # --- gospider ---
    show_progress $((++current)) $total_tools "URL Collection"
    if require_tool gospider; then
        log_info "Running gospider..."
        gospider -s "https://${domain}" -t "$THREADS" -d 3 --q -r -q 2>/dev/null | sed 's/^.* - //g' > "${urls_dir}/gospider_urls.txt"
        log_success "gospider: $(count_lines "${urls_dir}/gospider_urls.txt") URLs"
    fi

    # --- Merge and deduplicate ---
    log_info "Merging and deduplicating URLs..."
    cat "${urls_dir}"/*_urls.txt 2>/dev/null | sort -u > "$all_urls"
    dedup_file "$all_urls"

    # Filter only URLs belonging to target domain
    grep -i "${domain}" "$all_urls" 2>/dev/null > "${urls_dir}/filtered_urls.txt"

    local url_count
    url_count=$(count_lines "$all_urls")
    log_success "Total unique URLs: $url_count"

    echo "$url_count"
}
