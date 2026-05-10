#!/bin/bash
#=============================================================
# NishantX - Directory & Content Discovery Module
#=============================================================

run_dir_fuzzing() {
    local domain="$1"
    local output_dir="$2"
    local dirs_dir="${output_dir}/dirs"

    log_module "DIRECTORY & CONTENT DISCOVERY"

    local alive_file="${output_dir}/alive/alive.txt"
    if [[ ! -f "$alive_file" ]] || [[ $(count_lines "$alive_file") -eq 0 ]]; then
        log_warn "No alive hosts found - skipping directory fuzzing"
        return
    fi

    local total_tools=4
    local current=0
    local wordlist="$DIRS_WORDLIST"
    [[ ! -f "$wordlist" ]] && wordlist="/usr/share/wordlists/dirb/common.txt"

    # Build target list (top 10 alive hosts to avoid excessive scanning)
    local targets_file="${dirs_dir}/targets.txt"
    head -10 "$alive_file" > "$targets_file"

    # --- ffuf ---
    show_progress $((++current)) $total_tools "Dir Fuzzing"
    if require_tool ffuf; then
        log_info "Running ffuf..."
        while IFS= read -r target; do
            local safe_name
            safe_name=$(echo "$target" | sed 's/[^a-zA-Z0-9]/_/g')
            ffuf -u "${target}/FUZZ" -w "$wordlist" -t "$THREADS" \
                -mc 200,201,204,301,302,307,401,403,500 \
                -rate "$RATE_LIMIT" \
                -H "User-Agent: $(random_ua)" \
                -o "${dirs_dir}/ffuf_${safe_name}.json" \
                -of json \
                -silent 2>/dev/null

            # Extract found paths from JSON
            if [[ -f "${dirs_dir}/ffuf_${safe_name}.json" ]]; then
                jq -r '.results[].url' "${dirs_dir}/ffuf_${safe_name}.json" 2>/dev/null >> "${dirs_dir}/ffuf_paths.txt"
            fi
        done < "$targets_file"
        dedup_file "${dirs_dir}/ffuf_paths.txt" 2>/dev/null
        log_success "ffuf: $(count_lines "${dirs_dir}/ffuf_paths.txt") paths found"
    fi

    # --- feroxbuster ---
    show_progress $((++current)) $total_tools "Dir Fuzzing"
    if require_tool feroxbuster; then
        log_info "Running feroxbuster..."
        while IFS= read -r target; do
            local safe_name
            safe_name=$(echo "$target" | sed 's/[^a-zA-Z0-9]/_/g')
            feroxbuster -u "$target" -w "$wordlist" -t "$THREADS" \
                --rate-limit "$RATE_LIMIT" \
                --no-recursion \
                -q -o "${dirs_dir}/ferox_${safe_name}.txt" 2>/dev/null
        done < "$targets_file"
        cat "${dirs_dir}"/ferox_*.txt 2>/dev/null | sort -u > "${dirs_dir}/ferox_paths.txt"
        log_success "feroxbuster: $(count_lines "${dirs_dir}/ferox_paths.txt") paths found"
    fi

    # --- dirsearch ---
    show_progress $((++current)) $total_tools "Dir Fuzzing"
    if require_tool dirsearch; then
        log_info "Running dirsearch..."
        dirsearch -l "$targets_file" -w "$wordlist" -t "$THREADS" \
            --quiet --format=simple -o "${dirs_dir}/dirsearch.txt" 2>/dev/null
        log_success "dirsearch: completed"
    fi

    # --- gobuster ---
    show_progress $((++current)) $total_tools "Dir Fuzzing"
    if require_tool gobuster; then
        log_info "Running gobuster dir..."
        while IFS= read -r target; do
            local safe_name
            safe_name=$(echo "$target" | sed 's/[^a-zA-Z0-9]/_/g')
            gobuster dir -u "$target" -w "$wordlist" -t "$THREADS" \
                -q --no-error -o "${dirs_dir}/gobuster_${safe_name}.txt" 2>/dev/null
        done < "$targets_file"
        cat "${dirs_dir}"/gobuster_*.txt 2>/dev/null | sort -u > "${dirs_dir}/gobuster_paths.txt"
        log_success "gobuster: $(count_lines "${dirs_dir}/gobuster_paths.txt") paths found"
    fi

    # --- Merge all discovered paths ---
    cat "${dirs_dir}"/*paths*.txt "${dirs_dir}"/dirsearch.txt 2>/dev/null | sort -u > "${dirs_dir}/all_dirs.txt"
    dedup_file "${dirs_dir}/all_dirs.txt"

    log_success "Directory fuzzing complete: $(count_lines "${dirs_dir}/all_dirs.txt") unique paths"
}
