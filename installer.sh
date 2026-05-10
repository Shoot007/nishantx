#!/bin/bash
#=============================================================
# NishantX - Dependency Installer
#=============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

echo -e "${RED}${BOLD}"
echo -e '███╗   ██╗██╗███████╗██╗  ██╗ █████╗ ███╗   ██╗████████╗██╗  ██╗'
echo -e '████╗  ██║██║██╔════╝██║  ██║██╔══██╗████╗  ██║╚══██╔══╝╚██╗██╔╝'
echo -e '██╔██╗ ██║██║███████╗███████║███████║██╔██╗ ██║   ██║    ╚███╔╝ '
echo -e '██║╚██╗██║██║╚════██║██╔══██║██╔══██║██║╚██╗██║   ██║    ██╔██╗ '
echo -e '██║ ╚████║██║███████║██║  ██║██║  ██║██║ ╚████║   ██║   ██╔╝ ██╗'
echo -e '╚═╝  ╚═══╝╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝'
echo -e "${RESET}"
echo -e "${CYAN}${BOLD}  Dependency Installer${RESET}"
echo -e ""

# Check if running on Kali/Debian/Ubuntu
if ! grep -qi "kali\|debian\|ubuntu" /etc/os-release 2>/dev/null; then
    echo -e "${YELLOW}[!] Warning: This installer is designed for Kali Linux / Debian / Ubuntu${RESET}"
    echo -e "${YELLOW}[!] Some packages may not be available on other distributions${RESET}"
    read -rp "Continue anyway? (y/N): " confirm
    [[ "$confirm" != "y" && "$confirm" != "Y" ]] && exit 1
fi

# Update package lists
echo -e "${CYAN}[+] Updating package lists...${RESET}"
sudo apt-get update -qq 2>/dev/null

# Install system dependencies
echo -e "${CYAN}[+] Installing system dependencies...${RESET}"
sudo apt-get install -y -qq \
    git curl wget nmap masscan jq python3 python3-pip python3-venv \
    libssl-dev zlib1g-dev build-essential \
    seclists wordlists dirb dnsrecon \
    nikto sslscan testssl.sh whatweb wafw00f \
    dnsenum fierce \
    2>/dev/null

# Install Go (if not present)
if ! command -v go >/dev/null 2>&1; then
    echo -e "${CYAN}[+] Installing Go...${RESET}"
    wget -q https://go.dev/dl/go1.21.5.linux-amd64.tar.gz -O /tmp/go.tar.gz
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf /tmp/go.tar.gz
    rm -f /tmp/go.tar.gz
    export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
    echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> ~/.bashrc
    echo -e "${GREEN}[\$] Go installed successfully${RESET}"
else
    echo -e "${GREEN}[\$] Go already installed: $(go version)${RESET}"
fi

export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin

# Go-based tools
GO_TOOLS=(
    "github.com/projectdiscovery/subfinder/v2/cmd/subfinder"
    "github.com/tomnomnom/assetfinder"
    "github.com/OWASP/Amass/v3/... "
    "github.com/Findomain/Findomain"
    "github.com/projectdiscovery/httpx/cmd/httpx"
    "github.com/projectdiscovery/naabu/v2/cmd/naabu"
    "github.com/projectdiscovery/nuclei/v3/cmd/nuclei"
    "github.com/projectdiscovery/dnsx/cmd/dnsx"
    "github.com/projectdiscovery/shuffledns/cmd/shuffledns"
    "github.com/projectdiscovery/katana/cmd/katana"
    "github.com/lc/gau/v2/cmd/gau"
    "github.com/hakluke/hakrawler"
    "github.com/jaeles-project/gospider"
    "github.com/ffuf/ffuf/v2"
    "github.com/epi052/feroxbuster"
    "github.com/dwisiswant0/tlsx"
    "github.com/sensepost/gowitness"
    "github.com/hahwul/dalfox/v2"
    "github.com/michenil/subzy"
    "github.com/punk-security/dnsrecon"
    "github.com/shmilylty/nacos"
)

echo -e "${CYAN}[+] Installing Go-based tools...${RESET}"
for tool in "${GO_TOOLS[@]}"; do
    tool_name=$(basename "$tool")
    if command -v "$tool_name" >/dev/null 2>&1; then
        echo -e "${GREEN}  [\$] $tool_name already installed${RESET}"
    else
        echo -e "${YELLOW}  [*] Installing $tool_name...${RESET}"
        go install -v "$tool"@latest 2>/dev/null
        if command -v "$tool_name" >/dev/null 2>&1; then
            echo -e "${GREEN}  [\$] $tool_name installed${RESET}"
        else
            echo -e "${RED}  [!] Failed to install $tool_name${RESET}"
        fi
    fi
done

# Python-based tools
echo -e "${CYAN}[+] Installing Python-based tools...${RESET}"

# arjun
pip3 install arjun 2>/dev/null && echo -e "${GREEN}  [\$] arjun installed${RESET}" || echo -e "${RED}  [!] arjun install failed${RESET}"

# paramspider
pip3 install paramspider 2>/dev/null && echo -e "${GREEN}  [\$] paramspider installed${RESET}" || echo -e "${RED}  [!] paramspider install failed${RESET}"

# theHarvester
pip3 install theHarvester 2>/dev/null && echo -e "${GREEN}  [\$] theHarvester installed${RESET}" || echo -e "${RED}  [!] theHarvester install failed${RESET}"

# holehe
pip3 install holehe 2>/dev/null && echo -e "${GREEN}  [\$] holehe installed${RESET}" || echo -e "${RED}  [!] holehe install failed${RESET}"

# sherlock
pip3 install sherlock-project 2>/dev/null && echo -e "${GREEN}  [\$] sherlock installed${RESET}" || echo -e "${RED}  [!] sherlock install failed${RESET}"

# sqlmap
pip3 install sqlmap 2>/dev/null && echo -e "${GREEN}  [\$] sqlmap installed${RESET}" || echo -e "${RED}  [!] sqlmap install failed${RESET}"

# XSStrike
if [[ ! -d "/opt/XSStrike" ]]; then
    sudo git clone https://github.com/s0md3v/XSStrike.git /opt/XSStrike 2>/dev/null
    sudo ln -sf /opt/XSStrike/xsstrike /usr/local/bin/xsstrike 2>/dev/null
fi
echo -e "${GREEN}  [\$] XSStrike installed${RESET}"

# SecretFinder
if [[ ! -d "/opt/SecretFinder" ]]; then
    sudo git clone https://github.com/m4ll0k/SecretFinder.git /opt/SecretFinder 2>/dev/null
    pip3 install -r /opt/SecretFinder/requirements.txt 2>/dev/null
fi
echo -e "${GREEN}  [\$] SecretFinder installed${RESET}"

# LinkFinder
if [[ ! -d "/opt/LinkFinder" ]]; then
    sudo git clone https://github.com/GerbenJavado/LinkFinder.git /opt/LinkFinder 2>/dev/null
    pip3 install -r /opt/LinkFinder/requirements.txt 2>/dev/null
fi
echo -e "${GREEN}  [\$] LinkFinder installed${RESET}"

# xnLinkFinder
pip3 install xnLinkFinder 2>/dev/null && echo -e "${GREEN}  [\$] xnLinkFinder installed${RESET}" || echo -e "${RED}  [!] xnLinkFinder install failed${RESET}"

# git-dumper
pip3 install git-dumper 2>/dev/null && echo -e "${GREEN}  [\$] git-dumper installed${RESET}" || echo -e "${RED}  [!] git-dumper install failed${RESET}"

# trufflehog
pip3 install trufflehog 2>/dev/null && echo -e "${GREEN}  [\$] trufflehog installed${RESET}" || echo -e "${RED}  [!] trufflehog install failed${RESET}"

# s3scanner
pip3 install s3scanner 2>/dev/null && echo -e "${GREEN}  [\$] s3scanner installed${RESET}" || echo -e "${RED}  [!] s3scanner install failed${RESET}"

# cloud_enum
if [[ ! -d "/opt/cloud_enum" ]]; then
    sudo git clone https://github.com/initstring/cloud_enum.git /opt/cloud_enum 2>/dev/null
    pip3 install -r /opt/cloud_enum/requirements.txt 2>/dev/null
fi
echo -e "${GREEN}  [\$] cloud_enum installed${RESET}"

# wpscan
gem install wpscan 2>/dev/null && echo -e "${GREEN}  [\$] wpscan installed${RESET}" || echo -e "${RED}  [!] wpscan install failed${RESET}"

# droopescan
pip3 install droopescan 2>/dev/null && echo -e "${GREEN}  [\$] droopescan installed${RESET}" || echo -e "${RED}  [!] droopescan install failed${RESET}"

# rustscan
if ! command -v rustscan >/dev/null 2>&1; then
    wget -q https://github.com/RustScan/RustScan/releases/latest/download/rustscan_2.1.0_amd64.deb -O /tmp/rustscan.deb 2>/dev/null
    sudo dpkg -i /tmp/rustscan.deb 2>/dev/null
    rm -f /tmp/rustscan.deb
fi
echo -e "${GREEN}  [\$] rustscan installed${RESET}"

# puredns
go install github.com/d3mondev/puredns/v2/cmd/puredns@latest 2>/dev/null
echo -e "${GREEN}  [\$] puredns installed${RESET}"

# httprobe
go install github.com/tomnomnom/httprobe@latest 2>/dev/null
echo -e "${GREEN}  [\$] httprobe installed${RESET}"

# github-subdomains
go install github.com/gwen001/github-subdomains@latest 2>/dev/null
echo -e "${GREEN}  [\$] github-subdomains installed${RESET}"

# chaos client
go install github.com/projectdiscovery/chaos-client/cmd/chaos@latest 2>/dev/null
echo -e "${GREEN}  [\$] chaos-client installed${RESET}"

# gobuster
go install github.com/OJ/gobuster/v3@latest 2>/dev/null
echo -e "${GREEN}  [\$] gobuster installed${RESET}"

# dirsearch
pip3 install dirsearch 2>/dev/null && echo -e "${GREEN}  [\$] dirsearch installed${RESET}" || echo -e "${RED}  [!] dirsearch install failed${RESET}"

# eyewitness
if [[ ! -d "/opt/EyeWitness" ]]; then
    sudo git clone https://github.com/FortyNorthSecurity/EyeWitness.git /opt/EyeWitness 2>/dev/null
    cd /opt/EyeWitness && sudo python3 setup.py install 2>/dev/null
fi
echo -e "${GREEN}  [\$] EyeWitness installed${RESET}"

# Nuclei templates
echo -e "${CYAN}[+] Downloading nuclei templates...${RESET}"
nuclei -update-templates 2>/dev/null

# Resolvers
echo -e "${CYAN}[+] Setting up DNS resolvers...${RESET}"
if [[ ! -f "/usr/share/resolvers.txt" ]]; then
    echo -e "8.8.8.8\n8.8.4.4\n1.1.1.1\n1.0.0.1\n9.9.9.9\n208.67.222.222\n208.67.220.220" | sudo tee /usr/share/resolvers.txt >/dev/null
fi

# Make nishantx.sh executable
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
chmod +x "${SCRIPT_DIR}/nishantx.sh"

# Final check
echo -e ""
echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${GREEN}${BOLD}  INSTALLATION VERIFICATION${RESET}"
echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

TOOLS=(
    subfinder assetfinder amass findomain httpx httprobe naabu rustscan
    nmap nuclei dnsx shuffledns whatweb wafw00f ffuf feroxbuster
    dirsearch gobuster gau katana hakrawler waybackurls gospider
    arjun sqlmap dalfox nikto sslscan testssl.sh wpscan
    theHarvester sherlock gowitness jq curl dig
)

installed=0
missing=0
for tool in "${TOOLS[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
        echo -e "${GREEN}  [\$] ${tool}${RESET}"
        ((installed++))
    else
        echo -e "${RED}  [!] ${tool} - NOT FOUND${RESET}"
        ((missing++))
    fi
done

echo -e ""
echo -e "${GREEN}${BOLD}  Installed: ${installed} | Missing: ${missing}${RESET}"
echo -e ""
echo -e "${CYAN}  Run: ./nishantx.sh -d example.com${RESET}"
echo -e "${CYAN}  Help: ./nishantx.sh -h${RESET}"
echo -e ""
