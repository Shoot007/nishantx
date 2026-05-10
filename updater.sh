#!/bin/bash
#=============================================================
# NishantX - Auto Updater
#=============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

echo -e "${CYAN}${BOLD}[+] NishantX Updater${RESET}"

# Update Go tools
echo -e "${CYAN}[*] Updating Go-based tools...${RESET}"
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin

GO_TOOLS=(
    "github.com/projectdiscovery/subfinder/v2/cmd/subfinder"
    "github.com/projectdiscovery/httpx/cmd/httpx"
    "github.com/projectdiscovery/naabu/v2/cmd/naabu"
    "github.com/projectdiscovery/nuclei/v3/cmd/nuclei"
    "github.com/projectdiscovery/dnsx/cmd/dnsx"
    "github.com/projectdiscovery/shuffledns/cmd/shuffledns"
    "github.com/projectdiscovery/katana/cmd/katana"
    "github.com/lc/gau/v2/cmd/gau"
    "github.com/ffuf/ffuf/v2"
    "github.com/hahwul/dalfox/v2"
    "github.com/tomnomnom/httprobe"
    "github.com/tomnomnom/assetfinder"
    "github.com/OJ/gobuster/v3"
)

for tool in "${GO_TOOLS[@]}"; do
    tool_name=$(basename "$tool")
    echo -e "${YELLOW}  [*] Updating $tool_name...${RESET}"
    go install -v "$tool"@latest 2>/dev/null
    if command -v "$tool_name" >/dev/null 2>&1; then
        echo -e "${GREEN}  [\$] $tool_name updated${RESET}"
    else
        echo -e "${RED}  [!] $tool_name update failed${RESET}"
    fi
done

# Update nuclei templates
echo -e "${CYAN}[*] Updating nuclei templates...${RESET}"
nuclei -ut 2>/dev/null
echo -e "${GREEN}[\$] Nuclei templates updated${RESET}"

# Update Python tools
echo -e "${CYAN}[*] Updating Python tools...${RESET}"
pip3 install --upgrade -q arjun paramspider sqlmap dalfox 2>/dev/null
echo -e "${GREEN}[\$] Python tools updated${RESET}"

# Update NishantX itself (if git repo)
if [[ -d "${SCRIPT_DIR}/.git" ]]; then
    echo -e "${CYAN}[*] Updating NishantX framework...${RESET}"
    git -C "$SCRIPT_DIR" pull 2>/dev/null
    echo -e "${GREEN}[\$] NishantX updated${RESET}"
fi

echo -e ""
echo -e "${GREEN}${BOLD}Update complete!${RESET}"
