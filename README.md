# ███╗   ██╗██╗███████╗██╗  ██╗ █████╗ ███╗   ██╗████████╗██╗  ██╗
# ████╗  ██║██║██╔════╝██║  ██║██╔══██╗████╗  ██║╚══██╔══╝╚██╗██╔╝
# ██╔██╗ ██║██║███████╗███████║███████║██╔██╗ ██║   ██║    ╚███╔╝ 
# ██║╚██╗██║██║╚════██║██╔══██║██╔══██║██║╚██╗██║   ██║    ██╔██╗ 
# ██║ ╚████║██║███████║██║  ██║██║  ██║██║ ╚████║   ██║   ██╔╝ ██╗
# ╚═╝  ╚═══╝╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝

**NishantX** — Automated Reconnaissance, Enumeration, OSINT, Attack-Surface Mapping & Vulnerability Assessment Framework

> ⚠️ **AUTHORIZED USE ONLY** — This tool is designed exclusively for authorized penetration testing, lab environments, internal security assessments, and bug bounty programs with explicit permission. Unauthorized use against systems you do not own or have permission to test is illegal.

---

## 🎯 Overview

NishantX automates the entire reconnaissance-to-vulnerability-assessment pipeline from a **single command**:

```bash
./nishantx.sh -d example.com
```

### What it does automatically:

| Phase | Module | Tools Used |
|-------|--------|------------|
| 1 | Subdomain Enumeration | subfinder, assetfinder, amass, findomain, chaos, crt.sh, github-subdomains, waybackurls, gau, shuffledns, dnsx, puredns |
| 2 | Alive Host Discovery | httpx, httprobe |
| 3 | DNS Enumeration | dnsx, dig, dnsenum, fierce, zone transfer |
| 4 | Port Scanning | naabu, rustscan, nmap |
| 5 | Technology Detection | whatweb, httpx, wafw00f, wpscan, droopescan, nikto |
| 6 | URL Collection | gau, katana, hakrawler, waybackurls, gospider |
| 7 | Parameter Discovery | arjun, paramspider |
| 8 | Directory Fuzzing | ffuf, feroxbuster, dirsearch, gobuster |
| 9 | JavaScript Analysis | SecretFinder, LinkFinder, xnLinkFinder, regex secret scan |
| 10 | Vulnerability Scanning | nuclei, nikto, testssl.sh |
| 11 | SQL Injection | sqlmap |
| 12 | XSS Detection | dalfox, XSStrike |
| 13 | SSL/TLS Analysis | sslscan, testssl.sh, openssl |
| 14 | WAF Detection | wafw00f, httpx |
| 15 | Subdomain Takeover | subzy, nuclei takeover templates, built-in fingerprinting |
| 16 | Cloud Enumeration | s3scanner, cloud_enum, built-in S3/Azure/GCP checks |
| 17 | Git & Secret Discovery | git-dumper, trufflehog, exposed file scanner |
| 18 | Screenshot Collection | gowitness, eyewitness |
| 19 | OSINT | theHarvester, holehe, sherlock, Shodan, SecurityTrails, VirusTotal |
| 20 | Report Generation | Markdown, JSON, HTML, TXT |

---

## 📦 Installation

### Prerequisites

- **OS**: Kali Linux (recommended), Debian, or Ubuntu
- **Go**: 1.21+ (installer will handle this)
- **Python**: 3.8+
- **Root**: Some tools require root/sudo

### Quick Install

```bash
git clone https://github.com/yourusername/nishantx.git
cd nishantx
chmod +x nishantx.sh installer.sh updater.sh
sudo ./installer.sh
```

The installer will:
1. Install system packages (nmap, jq, curl, etc.)
2. Install Go and Go-based tools (subfinder, nuclei, httpx, etc.)
3. Install Python tools (arjun, sqlmap, dalfox, etc.)
4. Clone and set up tools from GitHub (XSStrike, SecretFinder, etc.)
5. Download nuclei templates
6. Verify all installations

### Manual Install (individual tools)

If you prefer to install tools individually:

```bash
# Go tools
go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
go install github.com/projectdiscovery/httpx/cmd/httpx@latest
go install github.com/projectdiscovery/naabu/v2/cmd/naabu@latest
go install github.com/projectdiscovery/dnsx/cmd/dnsx@latest
go install github.com/projectdiscovery/katana/cmd/katana@latest
go install github.com/lc/gau/v2/cmd/gau@latest
go install github.com/ffuf/ffuf/v2@latest
go install github.com/hahwul/dalfox/v2@latest

# Python tools
pip3 install sqlmap arjun paramspider theHarvester holehe sherlock-project

# System tools
sudo apt install nmap nikto sslscan whatweb wafw00f dnsenum fierce
```

---

## 🚀 Usage

### Basic Scan

```bash
./nishantx.sh -d example.com
```

### Deep Scan (thorough, slower)

```bash
./nishantx.sh -d example.com --deep
```

### Stealth Mode (rate-limited, slower)

```bash
./nishantx.sh -d example.com --stealth
```

### With Notifications

```bash
./nishantx.sh -d example.com --notify
```

### Resume Interrupted Scan

```bash
./nishantx.sh -d example.com -r
```

### Multi-domain Scan

```bash
./nishantx.sh -l domains.txt
```

### Custom Threads & Output

```bash
./nishantx.sh -d example.com -t 20 -o ./my_output
```

### All Options

```
OPTIONS
    -h              Show help message
    -d <domain>     Target domain
    -l <file>       List of domains (one per line)
    -o <dir>        Output directory (default: results/<domain>)
    -t <threads>    Thread count (default: 10)
    -s              Silent mode (no terminal output)
    -v              Verbose mode
    -r              Resume previous scan
    --deep          Deep scan mode (more thorough, slower)
    --stealth       Stealth mode (rate limited, slower)
    --aggressive    Aggressive mode (faster, noisier)
    --notify        Enable notifications
    --config <file> Custom config file
    --update        Update NishantX and tools
    --api-config    Configure API keys interactively
```

---

## 🔑 API Configuration

Run the interactive API key setup:

```bash
./nishantx.sh --api-config
```

Or manually edit `config/config.conf`:

```bash
# API Keys
SHODAN_API_KEY="your_key_here"
CENSYS_API_ID="your_id_here"
CENSYS_API_SECRET="your_secret_here"
VIRUSTOTAL_API_KEY="your_key_here"
SECURITYTRAILS_API_KEY="your_key_here"
GITHUB_TOKEN="your_token_here"
CHAOS_API_KEY="your_key_here"

# Notifications
TELEGRAM_BOT_TOKEN="your_bot_token"
TELEGRAM_CHAT_ID="your_chat_id"
DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/..."
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/..."
```

### Where to get API keys:

| Service | URL |
|---------|-----|
| Shodan | https://account.shodan.io/ |
| Censys | https://search.censys.io/register |
| VirusTotal | https://www.virustotal.com/gui/join-us |
| SecurityTrails | https://securitytrails.com/app/signup |
| GitHub | https://github.com/settings/tokens |
| Chaos | https://cloud.projectdiscovery.io/ |
| Telegram Bot | https://t.me/botfather |
| Discord Webhook | Server Settings → Integrations → Webhooks |
| Slack Webhook | https://api.slack.com/messaging/webhooks |

---

## 📁 Output Structure

```
results/example.com/
├── subdomains/
│   ├── subdomains.txt          # All unique subdomains
│   └── resolved.txt            # DNS-resolved subdomains
├── alive/
│   ├── alive.txt               # Alive HTTP/HTTPS hosts
│   ├── alive_full.txt          # httpx full output
│   ├── technologies.txt        # Detected technologies
│   ├── whatweb.txt             # WhatWeb results
│   └── wpscan.txt              # WordPress scan results
├── dns/
│   ├── a_records.txt
│   ├── mx_records.txt
│   ├── ns_records.txt
│   ├── txt_records.txt
│   ├── dmarc_records.txt
│   └── dns_all.txt             # Combined DNS data
├── ports/
│   ├── naabu_ports.txt
│   ├── nmap_full.nmap
│   └── all_ports.txt           # Combined port data
├── urls/
│   ├── all_urls.txt            # All collected URLs
│   └── filtered_urls.txt       # Domain-filtered URLs
├── params/
│   ├── all_params.txt          # All discovered parameters
│   └── paramspider_urls.txt
├── dirs/
│   ├── all_dirs.txt            # All discovered paths
│   └── ffuf_paths.txt
├── js/
│   ├── js_urls.txt             # JavaScript file URLs
│   ├── all_secrets.txt         # Secrets found in JS
│   └── regex_secrets.txt       # Regex-matched secrets
├── nuclei/
│   ├── nuclei_vulns.txt        # All nuclei findings
│   ├── cves.txt                # CVE findings
│   ├── exposed_panels.txt
│   ├── misconfig.txt
│   └── exposed_files.txt
├── sqlmap/
│   └── sqli_findings.txt       # SQL injection points
├── xss/
│   ├── dalfox_xss.txt
│   └── xsstrike_xss.txt
├── ssl/
│   ├── sslscan.txt
│   ├── cert_info.txt
│   └── weak_ssl.txt
├── waf/
│   ├── wafw00f.txt
│   └── httpx_waf.txt
├── takeover/
│   ├── builtin_takeover.txt
│   └── nuclei_takeover.txt
├── cloud/
│   ├── builtin_s3.txt
│   ├── azure_blobs.txt
│   └── gcp_buckets.txt
├── screenshots/
│   └── *.png                   # Screenshot captures
├── osint/
│   ├── all_emails.txt
│   ├── harvester.txt
│   └── sherlock.txt
├── reports/
│   ├── report_example.com.md   # Markdown report
│   ├── report_example.com.json # JSON report
│   ├── report_example.com.html # HTML report
│   └── summary_example.com.txt # TXT summary
├── logs/
│   └── nishantx_*.log
└── temp/                       # Temporary files (cleaned up)
```

---

## 📊 Reports

NishantX generates **4 report formats**:

### Markdown Report
Detailed structured report with all findings, severity indicators, and risk summary.

### JSON Report
Machine-readable structured data for integration with other tools.

### HTML Report
Styled hacker-themed dashboard with stat cards and severity tables. Open in any browser.

### TXT Summary
Quick one-page overview of all key metrics.

---

## 🔔 Notifications

Configure webhooks to receive real-time alerts:

- **Telegram**: Scan start/complete, critical findings
- **Discord**: Scan start/complete, critical findings
- **Slack**: Scan start/complete, critical findings

---

## 🛠️ Troubleshooting

### Tool not found
```bash
# Re-run installer
sudo ./installer.sh

# Or install specific tool
go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
```

### Nuclei templates missing
```bash
nuclei -ut
```

### Permission denied
```bash
chmod +x nishantx.sh installer.sh updater.sh
```

### Go path not set
```bash
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> ~/.bashrc
```

### Wordlists missing
```bash
sudo apt install seclists wordlists
```

### DNS resolution issues
```bash
# Create resolvers file
echo -e "8.8.8.8\n8.8.4.4\n1.1.1.1\n9.9.9.9" | sudo tee /usr/share/resolvers.txt
```

---

## 🔄 Updates

```bash
# Update all tools
./nishantx.sh --update

# Or run updater directly
./updater.sh
```

---

## 🏗️ Project Structure

```
nishantx/
├── nishantx.sh              # Main entry point
├── installer.sh             # Dependency installer
├── updater.sh               # Tool updater
├── README.md                # This file
├── config/
│   └── config.conf          # Configuration file
├── core/
│   ├── logging.sh           # Logging & UI system
│   ├── utils.sh             # Utility functions
│   └── notifications.sh     # Notification system
├── modules/
│   ├── recon/
│   │   ├── subdomains.sh    # Subdomain enumeration
│   │   ├── alive.sh         # Alive host discovery
│   │   ├── dns.sh           # DNS enumeration
│   │   ├── ports.sh         # Port scanning
│   │   └── techdetect.sh    # Technology detection
│   ├── content/
│   │   ├── urls.sh          # URL collection
│   │   ├── params.sh        # Parameter discovery
│   │   ├── dirs.sh          # Directory fuzzing
│   │   └── js.sh            # JavaScript analysis
│   ├── vuln/
│   │   ├── nuclei.sh        # Nuclei vulnerability scan
│   │   ├── sqlmap.sh        # SQL injection
│   │   ├── xss.sh           # XSS detection
│   │   ├── ssl.sh           # SSL/TLS analysis
│   │   ├── waf.sh           # WAF detection
│   │   ├── takeover.sh      # Subdomain takeover
│   │   ├── cloud.sh         # Cloud enumeration
│   │   └── git.sh           # Git & secret discovery
│   ├── osint/
│   │   └── osint.sh         # OSINT collection
│   ├── screenshot/
│   │   └── screenshots.sh   # Screenshot capture
│   └── report/
│       └── report.sh        # Report generation
└── utils/                   # Additional utilities
```

---

## 📜 License

This project is for **educational and authorized security testing purposes only**. The author assumes no liability and is not responsible for any misuse or damage caused by this program.

---

## ⚠️ Disclaimer

This tool is intended to be used only on systems you have explicit authorization to test. Unauthorized scanning or exploitation of systems is illegal. Always obtain proper written permission before conducting security assessments. The developer of NishantX is not responsible for any illegal use of this tool.

---

**Built with ❤️ for the security community**
