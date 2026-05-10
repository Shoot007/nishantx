#!/bin/bash
#=============================================================
# NishantX - Report Generator Module
#=============================================================

generate_report() {
    local domain="$1"
    local output_dir="$2"
    local reports_dir="${output_dir}/reports"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local scan_duration
    scan_duration=$(calc_duration "$SCAN_START_TIME" "$(date +%s)")

    log_module "REPORT GENERATION"

    # --- Gather statistics ---
    local subdomain_count=0
    local alive_count=0
    local url_count=0
    local param_count=0
    local port_count=0
    local nuclei_count=0
    local sqli_count=0
    local xss_count=0
    local js_secrets=0
    local takeover_count=0
    local exposed_count=0

    [[ -f "${output_dir}/subdomains/subdomains.txt" ]] && subdomain_count=$(count_lines "${output_dir}/subdomains/subdomains.txt")
    [[ -f "${output_dir}/alive/alive.txt" ]] && alive_count=$(count_lines "${output_dir}/alive/alive.txt")
    [[ -f "${output_dir}/urls/all_urls.txt" ]] && url_count=$(count_lines "${output_dir}/urls/all_urls.txt")
    [[ -f "${output_dir}/params/all_params.txt" ]] && param_count=$(count_lines "${output_dir}/params/all_params.txt")
    [[ -f "${output_dir}/ports/all_ports.txt" ]] && port_count=$(count_lines "${output_dir}/ports/all_ports.txt")
    [[ -f "${output_dir}/nuclei/nuclei_vulns.txt" ]] && nuclei_count=$(count_lines "${output_dir}/nuclei/nuclei_vulns.txt")
    [[ -f "${output_dir}/sqlmap/sqli_findings.txt" ]] && sqli_count=$(count_lines "${output_dir}/sqlmap/sqli_findings.txt")
    [[ -f "${output_dir}/xss/dalfox_xss.txt" ]] && xss_count=$(count_lines "${output_dir}/xss/dalfox_xss.txt")
    [[ -f "${output_dir}/js/all_secrets.txt" ]] && js_secrets=$(count_lines "${output_dir}/js/all_secrets.txt")
    [[ -f "${output_dir}/takeover/builtin_takeover.txt" ]] && takeover_count=$(count_lines "${output_dir}/takeover/builtin_takeover.txt")
    [[ -f "${output_dir}/nuclei/exposed_files.txt" ]] && exposed_count=$(count_lines "${output_dir}/nuclei/exposed_files.txt")

    # --- Technologies ---
    local tech_list=""
    if [[ -f "${output_dir}/alive/technologies.txt" ]]; then
        tech_list=$(tr '\n' ', ' < "${output_dir}/alive/technologies.txt" | sed 's/,$//')
    fi

    # --- WAF ---
    local waf_info="None detected"
    if [[ -f "${output_dir}/waf/wafw00f.txt" ]]; then
        waf_info=$(grep "is behind" "${output_dir}/waf/wafw00f.txt" 2>/dev/null | head -1)
        [[ -z "$waf_info" ]] && waf_info=$(grep -i "waf" "${output_dir}/waf/wafw00f.txt" 2>/dev/null | head -1)
    fi

    # --- SSL ---
    local ssl_info="Not checked"
    if [[ -f "${output_dir}/ssl/weak_ssl.txt" ]]; then
        ssl_info="Weak configurations found"
    elif [[ -f "${output_dir}/ssl/sslscan.txt" ]]; then
        ssl_info="Checked - no weak configurations"
    fi

    # --- CVEs ---
    local cve_count=0
    [[ -f "${output_dir}/nuclei/cves.txt" ]] && cve_count=$(count_lines "${output_dir}/nuclei/cves.txt")

    # --- Emails ---
    local email_count=0
    [[ -f "${output_dir}/osint/all_emails.txt" ]] && email_count=$(count_lines "${output_dir}/osint/all_emails.txt")

    # ===================== MARKDOWN REPORT =====================
    local md_report="${reports_dir}/report_${domain}.md"
    cat > "$md_report" << MDEOF
# NishantX Security Assessment Report

## Target: ${domain}

| Field | Value |
|-------|-------|
| **Date** | ${timestamp} |
| **Duration** | ${scan_duration} |
| **Framework** | NishantX v1.0.0 |

---

## Executive Summary

Security assessment of **${domain}** identified:
- **${subdomain_count}** subdomains
- **${alive_count}** alive hosts
- **${nuclei_count}** vulnerability findings
- **${cve_count}** CVEs
- **${sqli_count}** SQL injection points
- **${xss_count}** XSS findings
- **${takeover_count}** potential subdomain takeovers
- **${js_secrets}** JS secrets
- **${exposed_count}** exposed sensitive files

---

## 1. Subdomain Enumeration

**Total Subdomains:** ${subdomain_count}

$(if [[ -f "${output_dir}/subdomains/subdomains.txt" ]]; then head -50 "${output_dir}/subdomains/subdomains.txt" | sed 's/^/- /'; else echo "No subdomains found"; fi)

$(if [[ $(count_lines "${output_dir}/subdomains/subdomains.txt") -gt 50 ]]; then echo "... and $(( subdomain_count - 50 )) more"; fi)

## 2. Alive Hosts

**Total Alive:** ${alive_count}

$(if [[ -f "${output_dir}/alive/alive.txt" ]]; then head -30 "${output_dir}/alive/alive.txt" | sed 's/^/- /'; else echo "No alive hosts"; fi)

## 3. Technology Detection

**Technologies:** ${tech_list:-None detected}

$(if [[ -f "${output_dir}/alive/whatweb.txt" ]]; then echo '### WhatWeb Results'; head -20 "${output_dir}/alive/whatweb.txt" | sed 's/^/- /'; fi)

## 4. Port Scanning

**Open Ports Found:** ${port_count}

$(if [[ -f "${output_dir}/ports/all_ports.txt" ]]; then head -50 "${output_dir}/ports/all_ports.txt" | sed 's/^/- /'; fi)

## 5. URL & Endpoint Collection

**Total URLs:** ${url_count}

**Unique Parameters:** ${param_count}

## 6. Directory Discovery

$(if [[ -f "${output_dir}/dirs/all_dirs.txt" ]]; then echo '**Discovered Paths:**'; head -50 "${output_dir}/dirs/all_dirs.txt" | sed 's/^/- /'; else echo "No directories discovered"; fi)

## 7. JavaScript Analysis

**JS Secrets Found:** ${js_secrets}

$(if [[ -f "${output_dir}/js/all_secrets.txt" ]] && [[ $js_secrets -gt 0 ]]; then echo '### Secrets'; head -20 "${output_dir}/js/all_secrets.txt" | sed 's/^/- /'; fi)

$(if [[ -f "${output_dir}/js/regex_secrets.txt" ]] && [[ -s "${output_dir}/js/regex_secrets.txt" ]]; then echo '### Regex Secret Matches'; head -20 "${output_dir}/js/regex_secrets.txt" | sed 's/^/- /'; fi)

## 8. Vulnerability Assessment

### Nuclei Findings: ${nuclei_count}

$(if [[ -f "${output_dir}/nuclei/nuclei_vulns.txt" ]] && [[ $nuclei_count -gt 0 ]]; then head -30 "${output_dir}/nuclei/nuclei_vulns.txt" | sed 's/^/- /'; else echo "No vulnerabilities found by nuclei"; fi)

### CVEs: ${cve_count}

$(if [[ -f "${output_dir}/nuclei/cves.txt" ]] && [[ $cve_count -gt 0 ]]; then head -20 "${output_dir}/nuclei/cves.txt" | sed 's/^/- /'; fi)

### SQL Injection: ${sqli_count}

$(if [[ -f "${output_dir}/sqlmap/sqli_findings.txt" ]] && [[ $sqli_count -gt 0 ]]; then head -10 "${output_dir}/sqlmap/sqli_findings.txt" | sed 's/^/- /'; fi)

### XSS: ${xss_count}

$(if [[ -f "${output_dir}/xss/dalfox_xss.txt" ]] && [[ $xss_count -gt 0 ]]; then head -10 "${output_dir}/xss/dalfox_xss.txt" | sed 's/^/- /'; fi)

## 9. Subdomain Takeover

**Potential Takeovers:** ${takeover_count}

$(if [[ -f "${output_dir}/takeover/builtin_takeover.txt" ]] && [[ $takeover_count -gt 0 ]]; then head -20 "${output_dir}/takeover/builtin_takeover.txt" | sed 's/^/- /'; else echo "No takeover vulnerabilities found"; fi)

## 10. SSL/TLS Analysis

**Status:** ${ssl_info}

$(if [[ -f "${output_dir}/ssl/cert_info.txt" ]]; then echo '### Certificate Info'; cat "${output_dir}/ssl/cert_info.txt" | sed 's/^/- /'; fi)

## 11. WAF Detection

**WAF:** ${waf_info}

## 12. Cloud Resources

$(if [[ -f "${output_dir}/cloud/builtin_s3.txt" ]]; then echo '### S3 Buckets'; cat "${output_dir}/cloud/builtin_s3.txt" | sed 's/^/- /'; fi)

$(if [[ -f "${output_dir}/cloud/azure_blobs.txt" ]]; then echo '### Azure Blobs'; cat "${output_dir}/cloud/azure_blobs.txt" | sed 's/^/- /'; fi)

## 13. Exposed Files & Git

**Exposed Files:** ${exposed_count}

$(if [[ -f "${output_dir}/nuclei/exposed_files.txt" ]] && [[ $exposed_count -gt 0 ]]; then head -20 "${output_dir}/nuclei/exposed_files.txt" | sed 's/^/- /'; fi)

## 14. OSINT

**Emails Found:** ${email_count}

$(if [[ -f "${output_dir}/osint/all_emails.txt" ]] && [[ $email_count -gt 0 ]]; then head -20 "${output_dir}/osint/all_emails.txt" | sed 's/^/- /'; fi)

---

## Risk Summary

| Severity | Count |
|----------|-------|
| Critical | $(grep -c "\[critical\]" "${output_dir}/nuclei/nuclei_vulns.txt" 2>/dev/null || echo "0") |
| High | $(grep -c "\[high\]" "${output_dir}/nuclei/nuclei_vulns.txt" 2>/dev/null || echo "0") |
| Medium | $(grep -c "\[medium\]" "${output_dir}/nuclei/nuclei_vulns.txt" 2>/dev/null || echo "0") |
| Low | $(grep -c "\[low\]" "${output_dir}/nuclei/nuclei_vulns.txt" 2>/dev/null || echo "0") |
| Info | $(grep -c "\[info\]" "${output_dir}/nuclei/nuclei_vulns.txt" 2>/dev/null || echo "0") |

---

*Report generated by NishantX v1.0.0 on ${timestamp}*
*This report is for authorized security assessment purposes only.*
MDEOF

    log_success "Markdown report: $md_report"

    # ===================== JSON REPORT =====================
    local json_report="${reports_dir}/report_${domain}.json"
    cat > "$json_report" << JSONEOF
{
  "framework": "NishantX",
  "version": "1.0.0",
  "target": "${domain}",
  "timestamp": "${timestamp}",
  "duration": "${scan_duration}",
  "statistics": {
    "subdomains": ${subdomain_count},
    "alive_hosts": ${alive_count},
    "urls": ${url_count},
    "parameters": ${param_count},
    "open_ports": ${port_count},
    "vulnerabilities": ${nuclei_count},
    "cves": ${cve_count},
    "sqli": ${sqli_count},
    "xss": ${xss_count},
    "js_secrets": ${js_secrets},
    "takeovers": ${takeover_count},
    "exposed_files": ${exposed_count},
    "emails": ${email_count}
  },
  "technologies": "${tech_list}",
  "waf": "${waf_info}",
  "ssl_status": "${ssl_info}"
}
JSONEOF

    log_success "JSON report: $json_report"

    # ===================== TXT SUMMARY =====================
    local txt_report="${reports_dir}/summary_${domain}.txt"
    cat > "$txt_report" << TXTEOF
========================================================
NISHANTX SECURITY ASSESSMENT SUMMARY
========================================================
Target:   ${domain}
Date:     ${timestamp}
Duration: ${scan_duration}
========================================================
SUBDOMAINS:     ${subdomain_count}
ALIVE HOSTS:    ${alive_count}
URLs:           ${url_count}
PARAMETERS:     ${param_count}
OPEN PORTS:     ${port_count}
========================================================
VULNERABILITIES: ${nuclei_count}
CVES:            ${cve_count}
SQL INJECTIONS:  ${sqli_count}
XSS FINDINGS:    ${xss_count}
TAKEOVERS:       ${takeover_count}
JS SECRETS:      ${js_secrets}
EXPOSED FILES:   ${exposed_count}
EMAILS:          ${email_count}
========================================================
TECHNOLOGIES: ${tech_list:-None}
WAF:          ${waf_info}
SSL:          ${ssl_info}
========================================================
TXTEOF

    log_success "TXT summary: $txt_report"

    # ===================== HTML REPORT =====================
    local html_report="${reports_dir}/report_${domain}.html"
    cat > "$html_report" << HTMLEOF
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>NishantX Report - ${domain}</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:'Courier New',monospace;background:#0a0a0a;color:#00ff41;padding:20px}
.container{max-width:1200px;margin:0 auto}
h1{color:#ff0040;text-align:center;font-size:2em;margin:20px 0;text-shadow:0 0 10px #ff0040}
h2{color:#00ff41;border-bottom:1px solid #00ff41;padding:10px 0;margin:20px 0 10px}
h3{color:#00d4ff;margin:15px 0 5px}
table{width:100%;border-collapse:collapse;margin:10px 0}
th,td{border:1px solid #333;padding:8px 12px;text-align:left}
th{background:#1a1a1a;color:#00ff41}
td{background:#111}
.stats{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:15px;margin:20px 0}
.stat-card{background:#111;border:1px solid #00ff41;border-radius:5px;padding:15px;text-align:center}
.stat-card .number{font-size:2em;color:#00ff41;font-weight:bold}
.stat-card .label{color:#888;font-size:0.9em}
.critical{color:#ff0040;font-weight:bold}
.high{color:#ff6600}
.medium{color:#ffcc00}
.low{color:#00d4ff}
.info{color:#888}
pre{background:#111;border:1px solid #333;padding:10px;overflow-x:auto;border-radius:5px}
.footer{text-align:center;color:#555;margin-top:30px;padding-top:20px;border-top:1px solid #333}
</style>
</head>
<body>
<div class="container">
<h1>&#9889; NISHANTX REPORT</h1>
<table style="width:50%;margin:0 auto">
<tr><th>Target</th><td>${domain}</td></tr>
<tr><th>Date</th><td>${timestamp}</td></tr>
<tr><th>Duration</th><td>${scan_duration}</td></tr>
</table>

<div class="stats">
<div class="stat-card"><div class="number">${subdomain_count}</div><div class="label">Subdomains</div></div>
<div class="stat-card"><div class="number">${alive_count}</div><div class="label">Alive Hosts</div></div>
<div class="stat-card"><div class="number">${url_count}</div><div class="label">URLs</div></div>
<div class="stat-card"><div class="number">${port_count}</div><div class="label">Open Ports</div></div>
<div class="stat-card"><div class="number critical">${nuclei_count}</div><div class="label">Vulnerabilities</div></div>
<div class="stat-card"><div class="number high">${cve_count}</div><div class="label">CVEs</div></div>
<div class="stat-card"><div class="number critical">${sqli_count}</div><div class="label">SQLi</div></div>
<div class="stat-card"><div class="number high">${xss_count}</div><div class="label">XSS</div></div>
<div class="stat-card"><div class="number high">${takeover_count}</div><div class="label">Takeovers</div></div>
<div class="stat-card"><div class="number medium">${js_secrets}</div><div class="label">JS Secrets</div></div>
<div class="stat-card"><div class="number high">${exposed_count}</div><div class="label">Exposed Files</div></div>
<div class="stat-card"><div class="number">${email_count}</div><div class="label">Emails</div></div>
</div>

<h2>Technologies</h2>
<p>${tech_list:-None detected}</p>

<h2>WAF Detection</h2>
<p>${waf_info}</p>

<h2>SSL/TLS Status</h2>
<p>${ssl_info}</p>

<h2>Risk Summary</h2>
<table>
<tr><th>Severity</th><th>Count</th></tr>
<tr><td class="critical">Critical</td><td>$(grep -c "\[critical\]" "${output_dir}/nuclei/nuclei_vulns.txt" 2>/dev/null || echo "0")</td></tr>
<tr><td class="high">High</td><td>$(grep -c "\[high\]" "${output_dir}/nuclei/nuclei_vulns.txt" 2>/dev/null || echo "0")</td></tr>
<tr><td class="medium">Medium</td><td>$(grep -c "\[medium\]" "${output_dir}/nuclei/nuclei_vulns.txt" 2>/dev/null || echo "0")</td></tr>
<tr><td class="low">Low</td><td>$(grep -c "\[low\]" "${output_dir}/nuclei/nuclei_vulns.txt" 2>/dev/null || echo "0")</td></tr>
</table>

<div class="footer">
<p>NishantX v1.0.0 | Authorized Security Assessment Only</p>
</div>
</div>
</body>
</html>
HTMLEOF

    log_success "HTML report: $html_report"
    log_success "All reports generated in ${reports_dir}/"
}
