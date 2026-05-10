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
    # Format: "cname_match_pattern|service_name|expected_status|body_fingerprint"
    local takeover_signatures=(
        "github\.io|GitHub Pages|404|There isn't a GitHub Pages site here"
        "herokuapp\.com|Heroku|404|No such app"
        "s3\.amazonaws\.com|AWS S3|404|NoSuchBucket"
        "cloudfront\.net|CloudFront|403|Bad Request"
        "azure\.websites\.net|Azure|404|404 Web Site not found"
        "shopify\.com|Shopify|404|Sorry, this shop is currently unavailable"
        "tumblr\.com|Tumblr|404|Whatever you were looking for doesn't currently exist"
        "wordpress\.com|WordPress|404|Do you want to register"
        "teamwork\.com|Teamwork|404|Oops - We didn't find your site"
        "helpjuice\.com|HelpJuice|404|We could not find what you're looking for"
        "helpscout\.net|HelpScout|404|No settings were found for this company"
        "cargo\.site|Cargo|404|If you're moving your domain away from Cargo"
        "statuspage\.io|StatusPage|404|You are being redirected"
        "uservoice\.com|UserVoice|404|This UserVoice subdomain is currently available"
        "surge\.sh|Surge|404|project not found"
        "bitbucket\.io|BitBucket|404|Repository not found"
        "intercom\.help|Intercom|404|This page is reserved for artistic dogs"
        "webflow\.io|Webflow|404|The page you are looking for doesn't exist or has been moved"
        "readme\.io|ReadMe|404|Project doesnt exist"
        "pantheon\.io|Pantheon|404|404 error unknown site"
        "smartling\.com|Smartling|404|Domain is not configured"
        "acquia\.com|Acquia|404|The site you are looking for could not be found"
        "fastly\.net|Fastly|403|Fastly error: unknown domain"
        "ngrok\.io|Ngrok|404|Tunnel .* not found"
    )

    # Check CNAMEs for each subdomain
    while IFS= read -r sub; do
        local cname
        cname=$(dig +short "$sub" CNAME 2>/dev/null | head -1)
        [[ -z "$cname" ]] && continue

        for sig in "${takeover_signatures[@]}"; do
            local cname_pattern
            cname_pattern=$(echo "$sig" | cut -d'|' -f1)
            local service
            service=$(echo "$sig" | cut -d'|' -f2)
            local expected_status
            expected_status=$(echo "$sig" | cut -d'|' -f3)
            local fingerprint
            fingerprint=$(echo "$sig" | cut -d'|' -f4-)

            if echo "$cname" | grep -qE "$cname_pattern"; then
                local body
                body=$(curl -s "https://${sub}" --max-time 5 2>/dev/null)
                if echo "$body" | grep -qi "$fingerprint"; then
                    log_critical "Potential takeover: $sub -> $cname (service: $service)"
                    echo "$sub|$cname|$service" >> "${takeover_dir}/builtin_takeover.txt"
                    notify_critical "$domain" "Potential subdomain takeover: $sub ($service)"
                fi
            fi
        done
    done < <(head -200 "$subs_file")

    dedup_file "${takeover_dir}/builtin_takeover.txt" 2>/dev/null
    log_success "Takeover check complete"
}
