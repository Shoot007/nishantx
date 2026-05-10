#!/bin/bash
#=============================================================
# NishantX - Git & Secret Discovery Module
#=============================================================

run_git_secret_scan() {
    local domain="$1"
    local output_dir="$2"
    local git_dir="${output_dir}/temp"
    local report_dir="${output_dir}/nuclei"

    log_module "GIT & SECRET DISCOVERY"

    local alive_file="${output_dir}/alive/alive.txt"
    local urls_file="${output_dir}/urls/all_urls.txt"

    local total_tools=2
    local current=0

    # --- git-dumper ---
    show_progress $((++current)) $total_tools "Git/Secret Scan"
    if require_tool git-dumper; then
        log_info "Checking for exposed .git directories..."
        if [[ -f "$alive_file" ]]; then
            while IFS= read -r host; do
                local git_url="${host}/.git/"
                local status
                status=$(curl -s -o /dev/null -w "%{http_code}" "$git_url" --max-time 5 2>/dev/null)
                if [[ "$status" == "200" || "$status" == "403" ]]; then
                    log_warn "Exposed .git found: $git_url (Status: $status)"
                    echo "$git_url" >> "${git_dir}/exposed_git.txt"
                    # Try to dump
                    local safe_name
                    safe_name=$(echo "$host" | sed 's/[^a-zA-Z0-9]/_/g')
                    git-dumper "$git_url" "${git_dir}/git_dump_${safe_name}" 2>/dev/null
                    if [[ -d "${git_dir}/git_dump_${safe_name}" ]]; then
                        log_critical "Git repository dumped from: $git_url"
                        notify_critical "$domain" "Exposed .git repository at $git_url"
                    fi
                fi
            done < <(head -20 "$alive_file")
        fi
        log_success "git-dumper: $(count_lines "${git_dir}/exposed_git.txt") exposed .git dirs"
    fi

    # --- trufflehog ---
    show_progress $((++current)) $total_tools "Git/Secret Scan"
    if require_tool trufflehog; then
        log_info "Running trufflehog for secrets..."
        if [[ -f "$urls_file" ]]; then
            # Check for GitHub repos related to domain
            trufflehog github --org="$domain" --no-update 2>/dev/null > "${git_dir}/trufflehog.txt"
            log_success "trufflehog: $(count_lines "${git_dir}/trufflehog.txt") findings"
        fi
    fi

    # --- Built-in .env/.config file check ---
    log_info "Checking for exposed sensitive files..."
    local sensitive_files=(
        ".env" ".env.bak" ".env.old" ".env.local" ".env.production"
        ".git/config" ".svn/entries" ".hg/store"
        "config.php" "config.yml" "config.json" "config.ini"
        "database.yml" "wp-config.php" "configuration.php"
        ".htaccess" ".htpasswd" "robots.txt" "sitemap.xml"
        "crossdomain.xml" ".DS_Store" "web.config"
        "package.json" "composer.json" "Gemfile"
        "id_rsa" "id_dsa" ".ssh/authorized_keys"
        "backup.sql" "dump.sql" "database.sql"
        "phpinfo.php" "info.php" "test.php"
        "server-status" "server-info"
    )

    if [[ -f "$alive_file" ]]; then
        while IFS= read -r host; do
            for file in "${sensitive_files[@]}"; do
                local status
                status=$(curl -s -o /dev/null -w "%{http_code}" "${host}/${file}" --max-time 3 2>/dev/null)
                if [[ "$status" == "200" ]]; then
                    log_warn "Exposed file: ${host}/${file}"
                    echo "${host}/${file}" >> "${git_dir}/exposed_files.txt"
                fi
            done
        done < <(head -10 "$alive_file")
    fi
    dedup_file "${git_dir}/exposed_files.txt" 2>/dev/null
    log_success "Exposed files: $(count_lines "${git_dir}/exposed_files.txt") found"

    # Move results to proper location
    if [[ -f "${git_dir}/exposed_git.txt" ]]; then
        cp "${git_dir}/exposed_git.txt" "${output_dir}/nuclei/exposed_git.txt" 2>/dev/null
    fi
    if [[ -f "${git_dir}/exposed_files.txt" ]]; then
        cp "${git_dir}/exposed_files.txt" "${output_dir}/nuclei/exposed_files.txt" 2>/dev/null
    fi

    log_success "Git & secret discovery complete"
}
