#!/bin/bash
#=============================================================
# NishantX - Cloud Enumeration Module
#=============================================================

run_cloud_enum() {
    local domain="$1"
    local output_dir="$2"
    local cloud_dir="${output_dir}/cloud"

    log_module "CLOUD ENUMERATION"

    local total_tools=2
    local current=0

    # --- s3scanner ---
    show_progress $((++current)) $total_tools "Cloud Enum"
    if require_tool s3scanner; then
        log_info "Running s3scanner..."
        echo "$domain" | s3scanner scan 2>/dev/null > "${cloud_dir}/s3_buckets.txt"
        log_success "s3scanner: $(count_lines "${cloud_dir}/s3_buckets.txt") buckets found"
    fi

    # --- cloud_enum ---
    show_progress $((++current)) $total_tools "Cloud Enum"
    if [[ -f "/opt/cloud_enum/cloud_enum.py" ]]; then
        log_info "Running cloud_enum..."
        python3 /opt/cloud_enum/cloud_enum.py -k "$domain" -t "$THREADS" 2>/dev/null > "${cloud_dir}/cloud_enum.txt"
        log_success "cloud_enum: $(count_lines "${cloud_dir}/cloud_enum.txt") findings"
    fi

    # --- Built-in S3 bucket check ---
    log_info "Running built-in S3 bucket discovery..."
    local bucket_names=(
        "${domain//./-}"
        "${domain//./}"
        "www-${domain//./-}"
        "backup-${domain//./-}"
        "data-${domain//./-}"
        "assets-${domain//./-}"
        "media-${domain//./-}"
        "static-${domain//./-}"
        "logs-${domain//./-}"
        "dev-${domain//./-}"
        "prod-${domain//./-}"
        "staging-${domain//./-}"
        "test-${domain//./-}"
        "${domain%%.*}"
        "www-${domain%%.*}"
    )

    for bucket in "${bucket_names[@]}"; do
        for region in "s3.amazonaws.com" "s3-us-west-2.amazonaws.com" "s3-eu-west-1.amazonaws.com"; do
            local status
            status=$(curl -s -o /dev/null -w "%{http_code}" "https://${bucket}.${region}" --max-time 5 2>/dev/null)
            if [[ "$status" == "200" ]]; then
                log_warn "Open S3 bucket found: ${bucket}.${region}"
                echo "${bucket}.${region} (OPEN - $status)" >> "${cloud_dir}/builtin_s3.txt"
            elif [[ "$status" == "403" ]]; then
                echo "${bucket}.${region} (EXISTS - $status)" >> "${cloud_dir}/builtin_s3.txt"
            fi
        done
    done

    dedup_file "${cloud_dir}/builtin_s3.txt" 2>/dev/null
    log_success "Built-in S3 check: $(count_lines "${cloud_dir}/builtin_s3.txt") buckets identified"

    # --- Azure blob storage check ---
    log_info "Checking Azure blob storage..."
    local azure_names=("${domain//./}" "${domain%%.*}" "www${domain//./}")
    for name in "${azure_names[@]}"; do
        local status
        status=$(curl -s -o /dev/null -w "%{http_code}" "https://${name}.blob.core.windows.net" --max-time 5 2>/dev/null)
        if [[ "$status" != "000" ]]; then
            echo "${name}.blob.core.windows.net (Status: $status)" >> "${cloud_dir}/azure_blobs.txt"
        fi
    done
    dedup_file "${cloud_dir}/azure_blobs.txt" 2>/dev/null

    # --- GCP bucket check ---
    log_info "Checking Google Cloud Storage..."
    for name in "${domain//./-}" "${domain%%.*}"; do
        local status
        status=$(curl -s -o /dev/null -w "%{http_code}" "https://storage.googleapis.com/${name}" --max-time 5 2>/dev/null)
        if [[ "$status" == "200" ]]; then
            log_warn "Open GCS bucket found: $name"
            echo "storage.googleapis.com/${name} (OPEN)" >> "${cloud_dir}/gcp_buckets.txt"
        fi
    done
    dedup_file "${cloud_dir}/gcp_buckets.txt" 2>/dev/null

    log_success "Cloud enumeration complete"
}
