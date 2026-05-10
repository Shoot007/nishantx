#!/bin/bash
#=============================================================
# NishantX - Port Scanning Module
#=============================================================

run_port_scan() {
    local domain="$1"
    local output_dir="$2"
    local ports_dir="${output_dir}/ports"
    local subs_file="${output_dir}/subdomains/subdomains.txt"

    log_module "PORT SCANNING"

    if [[ ! -f "$subs_file" ]] || [[ $(count_lines "$subs_file") -eq 0 ]]; then
        log_warn "No subdomains found - skipping port scan"
        return
    fi

    local total_tools=3
    local current=0

    # --- naabu ---
    show_progress $((++current)) $total_tools "Port Scan"
    if require_tool naabu; then
        log_info "Running naabu..."
        local naabu_opts="-l $subs_file -silent -t $THREADS"
        if [[ "$STEALTH_MODE" == "true" ]]; then
            naabu_opts+=" -rate 50"
        else
            naabu_opts+=" -rate $PORT_SCAN_RATE"
        fi
        if [[ -n "$PORT_EXCLUDE" ]]; then
            naabu_opts+=" -exclude-ports $PORT_EXCLUDE"
        fi
        if [[ "$DEEP_SCAN" == "true" ]]; then
            naabu_opts+=" -p -"
        else
            naabu_opts+=" -top-ports $PORT_TOP_PORTS"
        fi
        eval naabu $naabu_opts -o "${ports_dir}/naabu_ports.txt" 2>/dev/null
        log_success "naabu: $(count_lines "${ports_dir}/naabu_ports.txt") port entries"
    fi

    # --- rustscan ---
    show_progress $((++current)) $total_tools "Port Scan"
    if require_tool rustscan; then
        log_info "Running rustscan..."
        local rustscan_opts="-iL $subs_file --quiet"
        if [[ "$STEALTH_MODE" == "true" ]]; then
            rustscan_opts+=" --batch-size 50 --timeout 3000"
        else
            rustscan_opts+=" --batch-size 450 --timeout 3000"
        fi
        if [[ "$DEEP_SCAN" == "true" ]]; then
            rustscan_opts+=" -p 1-65535"
        else
            rustscan_opts+=" -p 1-$PORT_TOP_PORTS"
        fi
        eval rustscan $rustscan_opts -- -sV -oN "${ports_dir}/rustscan_nmap.txt" 2>/dev/null
        log_success "rustscan: completed"
    fi

    # --- nmap ---
    show_progress $((++current)) $total_tools "Port Scan"
    if require_tool nmap; then
        log_info "Running nmap service detection..."
        local nmap_target
        # If naabu found ports, use those for targeted nmap
        if [[ -f "${ports_dir}/naabu_ports.txt" ]] && [[ $(count_lines "${ports_dir}/naabu_ports.txt") -gt 0 ]]; then
            # Extract unique hosts from naabu output
            cut -d: -f1 "${ports_dir}/naabu_ports.txt" | sort -u > "${ports_dir}/nmap_targets.txt"
            nmap_target="${ports_dir}/nmap_targets.txt"
            nmap -iL "$nmap_target" -sV -sC --top-ports "$PORT_TOP_PORTS" \
                -T4 --open -oA "${ports_dir}/nmap_full" 2>/dev/null
        else
            nmap "$domain" -sV -sC --top-ports "$PORT_TOP_PORTS" \
                -T4 --open -oA "${ports_dir}/nmap_full" 2>/dev/null
        fi
        log_success "nmap: completed"
    fi

    # Parse and combine all port results
    if [[ -f "${ports_dir}/naabu_ports.txt" ]]; then
        cp "${ports_dir}/naabu_ports.txt" "${ports_dir}/all_ports.txt"
    fi
    if [[ -f "${ports_dir}/nmap_full.nmap" ]]; then
        grep "open" "${ports_dir}/nmap_full.nmap" 2>/dev/null >> "${ports_dir}/all_ports.txt"
    fi
    dedup_file "${ports_dir}/all_ports.txt" 2>/dev/null

    log_success "Port scanning complete"
}
