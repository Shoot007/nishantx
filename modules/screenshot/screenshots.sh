#!/bin/bash
#=============================================================
# NishantX - Screenshot Collection Module
#=============================================================

run_screenshots() {
    local domain="$1"
    local output_dir="$2"
    local screenshot_dir="${output_dir}/screenshots"
    local alive_file="${output_dir}/alive/alive.txt"

    log_module "SCREENSHOT COLLECTION"

    if [[ ! -f "$alive_file" ]] || [[ $(count_lines "$alive_file") -eq 0 ]]; then
        log_warn "No alive hosts found - skipping screenshots"
        return
    fi

    local total_tools=2
    local current=0

    # --- gowitness ---
    show_progress $((++current)) $total_tools "Screenshots"
    if require_tool gowitness; then
        log_info "Running gowitness..."
        gowitness file -f "$alive_file" -t "$THREADS" \
            --timeout "$SCREENSHOT_TIMEOUT" \
            --width "$SCREENSHOT_WIDTH" \
            --height "$SCREENSHOT_HEIGHT" \
            --destination "$screenshot_dir" \
            --log-level error 2>/dev/null
        log_success "gowitness: $(ls "$screenshot_dir"/*.png 2>/dev/null | wc -l) screenshots captured"
    fi

    # --- eyewitness ---
    show_progress $((++current)) $total_tools "Screenshots"
    if require_tool eyewitness; then
        log_info "Running eyewitness..."
        local ew_dir="${screenshot_dir}/eyewitness"
        mkdir -p "$ew_dir"
        eyewitness --web -f "$alive_file" -d "$ew_dir" \
            --timeout "$SCREENSHOT_TIMEOUT" \
            --no-prompt 2>/dev/null
        log_success "eyewitness: completed"
    fi

    # Fallback: if neither tool available, use curl to grab basic response info
    if ! check_tool gowitness && ! check_tool eyewitness; then
        log_warn "No screenshot tool available - capturing response headers instead"
        while IFS= read -r host; do
            local safe_name
            safe_name=$(echo "$host" | sed 's/[^a-zA-Z0-9]/_/g')
            curl -sI "$host" --max-time 10 2>/dev/null > "${screenshot_dir}/${safe_name}_headers.txt"
        done < <(head -30 "$alive_file")
        log_success "Response headers captured for $(ls "${screenshot_dir}"/*_headers.txt 2>/dev/null | wc -l) hosts"
    fi

    log_success "Screenshot collection complete"
}
