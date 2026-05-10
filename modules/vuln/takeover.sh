#!/bin/bash
#=============================================================
# NishantX - Subdomain Takeover Detection Module
#=============================================================

run_takeover_check() {
    local domain="$1"
    local output_dir="$2"
    local takeover_dir="${output_dir}/takeover"
    local subs_file="${output_dir}/subdomains/subdomains.txt"

    log_module "SUBDOMAIN TAKEOVER DETECTION"

    if [[ ! -f "$subs_file" ]] || [[ $(count_lines "$subs_file") -eq 0 ]]; then
        log_warn "No subdomains found - skipping takeover check"
        return
    fi

    local total_tools=2
    local current=0

    # --- subzy ---
    show_progress $((++current)) $total_tools "Takeover Check"
    if require_tool subzy; then
        log_info "Running subzy..."
        subzy run --targets "$subs_file" --timeout 10 --threads "$THREADS" \
            --output "${takeover_dir}/subzy.txt" 2>/dev/null
        log_success "subzy: $(count_lines "${takeover_dir}/subzy.txt") findings"
    fi

    # --- nuclei takeover templates ---
    show_progress $((++current)) $total_tools "Takeover Check"
    if require_tool nuclei; then
        log_info "Running nuclei takeover templates..."
        nuclei -l "$subs_file" -t "${NUCLEI_TEMPLATES_DIR}/takeovers" -silent \
            -o "${takeover_dir}/nuclei_takeover.txt" 2>/dev/null
        log_success "nuclei takeover: $(count_lines "${takeover_dir}/nuclei_takeover.txt") findings"
    fi

    # --- Built-in fingerprint check for common takeover services ---
    log_info "Running built-in takeover fingerprint check..."
    local takeover_signatures=(
        "CNAME.*github.io:404:There isn't a GitHub Pages site here"
        "CNAME.*herokuapp.com:404:No such app"
        "CNAME.*aws.*s3:NoSuchBucket"
        "CNAME.*cloudfront.net:403:Bad Request"
        "CNAME.*azure.*:404:404 Web Site not found"
        "CNAME.*shopify.com:404:Sorry, this shop is currently unavailable"
        "CNAME.*tumblr.com:404:Whatever you were looking for doesn't currently exist"
        "CNAME.*wordpress.com:404:Do you want to register"
        "CNAME.*teamwork.com:404:Oops - We didn't find your site"
        "CNAME.*helpjuice.com:404:We could not find what you're looking for"
        "CNAME.*helpscout.net:404:No settings were found for this company"
        "CNAME.*cargo.site:404:If you're moving your domain away from Cargo"
        "CNAME.*statuspage.io:404:You are being redirected"
        "CNAME.*uservoice.com:404:This UserVoice subdomain is currently available"
        "CNAME.*surge.sh:404:project not found"
        "CNAME.*bitbucket.io:404:Repository not found"
        "CNAME.*intercom.help:404:This page is reserved for artistic dogs"
        "CNAME.*webflow.io:404:The page you are looking for doesn't exist or has been moved"
        "CNAME.*readme.io:404:Project doesnt exist"
        "CNAME.*pantheon.io:404:404 error unknown site"
        "CNAME.*smartling.com:404:Domain is not configured"
        "CNAME.*acquia.com:404:The site you are looking for could not be found"
        "CNAME.*fastly.com:403:Fastly error: unknown domain"
        "CNAME.*ngrok.io:404:Tunnel .*.ngrok.io not found"
    )

    # Check CNAMEs for each subdomain
    while IFS= read -r sub; do
        local cname
        cname=$(dig +short "$sub" CNAME 2>/dev/null | head -1)
        [[ -z "$cname" ]] && continue

        for sig in "${takeover_signatures[@]}"; do
            local service
            service=$(echo "$sig" | cut -d: -f1)
            local pattern
            pattern=$(echo "$sig" | cut -d: -f3-)

            if echo "$cname" | grep -qi "$service"; then
                local response
                response=$(curl -s -o /dev/null -w "%{http_code}" "https://${sub}" --max-time 5 2>/dev/null)
                local body
                body=$(curl -s "https://${sub}" --max-time 5 2>/dev/null)
                if echo "$body" | grep -qi "$pattern"; then
                    log_critical "Potential takeover: $sub -> $cname (fingerprint: $service)"
                    echo "$sub|$cname|$service" >> "${takeover_dir}/builtin_takeover.txt"
                    notify_critical "$domain" "Potential subdomain takeover: $sub ($service)"
                fi
            fi
        done
    done < <(head -200 "$subs_file")

    dedup_file "${takeover_dir}/builtin_takeover.txt" 2>/dev/null
    log_success "Takeover check complete"
}
