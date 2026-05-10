#!/bin/bash
#=============================================================
# NishantX - DNS Enumeration Module
#=============================================================

run_dns_enum() {
    local domain="$1"
    local output_dir="$2"
    local dns_dir="${output_dir}/dns"

    log_module "DNS ENUMERATION"

    local total_tools=5
    local current=0

    # --- dnsx ---
    show_progress $((++current)) $total_tools "DNS Enum"
    if require_tool dnsx; then
        log_info "Running dnsx for DNS records..."
        local subs_file="${output_dir}/subdomains/subdomains.txt"
        if [[ -f "$subs_file" ]]; then
            dnsx -l "$subs_file" -silent -a -aaaa -cname -mx -ns -soa -txt \
                -t "$THREADS" -o "${dns_dir}/dnsx_records.txt" 2>/dev/null
            log_success "dnsx: $(count_lines "${dns_dir}/dnsx_records.txt") records"
        fi
    fi

    # --- dig ---
    show_progress $((++current)) $total_tools "DNS Enum"
    log_info "Running dig for DNS records..."
    dig "$domain" A +short >> "${dns_dir}/a_records.txt" 2>/dev/null
    dig "$domain" AAAA +short >> "${dns_dir}/aaaa_records.txt" 2>/dev/null
    dig "$domain" MX +short >> "${dns_dir}/mx_records.txt" 2>/dev/null
    dig "$domain" NS +short >> "${dns_dir}/ns_records.txt" 2>/dev/null
    dig "$domain" TXT +short >> "${dns_dir}/txt_records.txt" 2>/dev/null
    dig "$domain" SOA +short >> "${dns_dir}/soa_records.txt" 2>/dev/null
    dig "$domain" CNAME +short >> "${dns_dir}/cname_records.txt" 2>/dev/null
    dig "$domain" DKIM +short >> "${dns_dir}/dkim_records.txt" 2>/dev/null
    dig "$domain" DMARC +short >> "${dns_dir}/dmarc_records.txt" 2>/dev/null

    # DMARC specific
    dig "_dmarc.${domain}" TXT +short >> "${dns_dir}/dmarc_records.txt" 2>/dev/null

    # SPF
    dig "$domain" TXT +short | grep "v=spf" >> "${dns_dir}/spf_records.txt" 2>/dev/null

    log_success "dig: DNS records collected"

    # --- dnsenum ---
    show_progress $((++current)) $total_tools "DNS Enum"
    if require_tool dnsenum; then
        log_info "Running dnsenum..."
        dnsenum "$domain" 2>/dev/null > "${dns_dir}/dnsenum.txt"
        log_success "dnsenum: completed"
    fi

    # --- fierce ---
    show_progress $((++current)) $total_tools "DNS Enum"
    if require_tool fierce; then
        log_info "Running fierce..."
        fierce --domain "$domain" 2>/dev/null > "${dns_dir}/fierce.txt"
        log_success "fierce: completed"
    fi

    # --- DNS zone transfer attempt ---
    show_progress $((++current)) $total_tools "DNS Enum"
    log_info "Attempting DNS zone transfer..."
    for ns in $(dig "$domain" NS +short 2>/dev/null); do
        dig "@${ns}" "$domain" AXFR +short >> "${dns_dir}/zone_transfer.txt" 2>/dev/null
    done
    if [[ -s "${dns_dir}/zone_transfer.txt" ]]; then
        log_critical "DNS ZONE TRANSFER SUCCESSFUL - This is a critical finding!"
        notify_critical "$domain" "DNS Zone Transfer Successful"
    else
        log_info "Zone transfer not allowed (expected)"
        rm -f "${dns_dir}/zone_transfer.txt"
    fi

    # Combine all DNS data
    cat "${dns_dir}"/*.txt 2>/dev/null | sort -u > "${dns_dir}/dns_all.txt"
    log_success "DNS enumeration complete"
}
