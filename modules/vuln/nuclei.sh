#!/bin/bash
#=============================================================
# NishantX - Nuclei Vulnerability Scanner Module
#=============================================================

run_nuclei_scan() {
    local domain="$1"
    local output_dir="$2"
    local nuclei_dir="${output_dir}/nuclei"
    local subs_file="${output_dir}/subdomains/subdomains.txt"

    log_module "NUCLEI VULNERABILITY SCANNING"

    if ! require_tool nuclei; then
        log_warn "nuclei not found - skipping vulnerability scan"
        return
    fi

    if [[ ! -f "$subs_file" ]] || [[ $(count_lines "$subs_file") -eq 0 ]]; then
        log_warn "No subdomains found - skipping nuclei scan"
        return
    fi

    local total_tools=4
    local current=0

    # Update templates first
    show_progress $((++current)) $total_tools "Nuclei Scan"
    log_info "Updating nuclei templates..."
    nuclei -ut 2>/dev/null

    # --- Full vulnerability scan ---
    show_progress $((++current)) $total_tools "Nuclei Scan"
    log_info "Running nuclei vulnerability scan..."
    local nuclei_opts="-l $subs_file -t ${NUCLEI_TEMPLATES_DIR} -silent -t $THREADS -severity $NUCLEI_SEVERITY"
    if [[ -n "$NUCLEI_TAGS" ]]; then
        nuclei_opts+=" -tags $NUCLEI_TAGS"
    fi
    if [[ "$STEALTH_MODE" == "true" ]]; then
        nuclei_opts+=" -rate-limit 50"
    fi
    eval nuclei $nuclei_opts \
        -o "${nuclei_dir}/nuclei_vulns.txt" \
        -jsonl "${nuclei_dir}/nuclei_vulns.jsonl" 2>/dev/null
    log_success "nuclei vulns: $(count_lines "${nuclei_dir}/nuclei_vulns.txt") findings"

    # --- Exposed panels/templates ---
    show_progress $((++current)) $total_tools "Nuclei Scan"
    log_info "Running nuclei for exposed panels..."
    nuclei -l "$subs_file" -t "${NUCLEI_TEMPLATES_DIR}/exposures" -silent \
        -o "${nuclei_dir}/exposed_panels.txt" 2>/dev/null
    log_success "Exposed panels: $(count_lines "${nuclei_dir}/exposed_panels.txt") findings"

    # --- Misconfiguration templates ---
    show_progress $((++current)) $total_tools "Nuclei Scan"
    log_info "Running nuclei misconfiguration checks..."
    nuclei -l "$subs_file" -t "${NUCLEI_TEMPLATES_DIR}/misconfiguration" -silent \
        -o "${nuclei_dir}/misconfig.txt" 2>/dev/null
    log_success "Misconfigurations: $(count_lines "${nuclei_dir}/misconfig.txt") findings"

    # --- CVE scan ---
    log_info "Running nuclei CVE templates..."
    nuclei -l "$subs_file" -t "${NUCLEI_TEMPLATES_DIR}/cves" -silent \
        -severity critical,high \
        -o "${nuclei_dir}/cves.txt" 2>/dev/null
    log_success "CVEs: $(count_lines "${nuclei_dir}/cves.txt") findings"

    # Check for critical findings
    if [[ -s "${nuclei_dir}/nuclei_vulns.txt" ]]; then
        local critical_count
        critical_count=$(grep -c "\[critical\]" "${nuclei_dir}/nuclei_vulns.txt" 2>/dev/null || echo "0")
        if [[ $critical_count -gt 0 ]]; then
            log_critical "$critical_count CRITICAL vulnerabilities found!"
            notify_critical "$domain" "$critical_count CRITICAL vulnerabilities found by nuclei"
        fi
    fi

    log_success "Nuclei scanning complete"
}
