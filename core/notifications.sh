#!/bin/bash
#=============================================================
# NishantX - Notification System (Telegram, Discord, Slack)
#=============================================================

# Send Telegram notification
notify_telegram() {
    local message="$1"
    [[ -z "$TELEGRAM_BOT_TOKEN" || -z "$TELEGRAM_CHAT_ID" ]] && return

    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="$TELEGRAM_CHAT_ID" \
        -d text="$message" \
        -d parse_mode="HTML" \
        >/dev/null 2>&1

    log_debug "Telegram notification sent"
}

# Send Discord notification
notify_discord() {
    local message="$1"
    [[ -z "$DISCORD_WEBHOOK_URL" ]] && return

    curl -s -X POST "$DISCORD_WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d "{\"content\":\"\`\`\`\n${message}\n\`\`\`\"}" \
        >/dev/null 2>&1

    log_debug "Discord notification sent"
}

# Send Slack notification
notify_slack() {
    local message="$1"
    [[ -z "$SLACK_WEBHOOK_URL" ]] && return

    curl -s -X POST "$SLACK_WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d "{\"text\":\"${message}\"}" \
        >/dev/null 2>&1

    log_debug "Slack notification sent"
}

# Send notification to all configured channels
notify_all() {
    local message="$1"
    [[ "$NOTIFY" != "true" ]] && return

    notify_telegram "$message"
    notify_discord "$message"
    notify_slack "$message"
}

# Notify scan start
notify_scan_start() {
    local domain="$1"
    notify_all "🔴 NishantX Scan Started\nTarget: $domain\nTime: $(date)"
}

# Notify scan complete
notify_scan_complete() {
    local domain="$1"
    local output_dir="$2"
    local subdomain_count
    subdomain_count=$(count_lines "${output_dir}/subdomains/subdomains.txt" 2>/dev/null || echo "0")
    local alive_count
    alive_count=$(count_lines "${output_dir}/alive/alive.txt" 2>/dev/null || echo "0")

    notify_all "🟢 NishantX Scan Complete\nTarget: $domain\nSubdomains: $subdomain_count\nAlive: $alive_count\nTime: $(date)"
}

# Notify critical finding
notify_critical() {
    local domain="$1"
    local finding="$2"
    notify_all "🚨 CRITICAL FINDING\nTarget: $domain\nFinding: $finding"
}
