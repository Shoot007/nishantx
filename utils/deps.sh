#!/bin/bash
#=============================================================
# NishantX - Dependency Checker & Auto-Installer
#=============================================================

# Colors for installer
INSTALLER_GREEN='\033[1;32m'
INSTALLER_RED='\033[1;31m'
INSTALLER_YELLOW='\033[1;33m'
INSTALLER_CYAN='\033[0;36m'
INSTALLER_RESET='\033[0m'

# Export PATH for Go tools
export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"

# Required tools list with their install methods
# Format: "tool_name|category|install_command|fallback_message"
DEPS=(
    # System tools
    "curl|system|sudo apt-get install -y curl|Curl is required for HTTP requests"
    "jq|system|sudo apt-get install -y jq|jq is required for JSON parsing"
    "nmap|system|sudo apt-get install -y nmap|nmap is required for port scanning"
    "dig|system|sudo apt-get install -y dnsutils|dig is required for DNS enumeration"
    "git|system|sudo apt-get install -y git|git is required for cloning tools"
    
    # Go-based tools
    "subfinder|go|go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest|SubFinder is required for subdomain enumeration"
    "httpx|go|go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest|httpx is required for alive detection"
    "naabu|go|go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest|naabu is required for port scanning"
    "nuclei|go|go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest|nuclei is required for vulnerability scanning"
    "dnsx|go|go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest|dnsx is required for DNS resolution"
    "katana|go|go install -v github.com/projectdiscovery/katana/cmd/katana@latest|katana is required for URL crawling"
    "gau|go|go install -v github.com/lc/gau/v2/cmd/gau@latest|gau is required for URL collection"
    "ffuf|go|go install -v github.com/ffuf/ffuf/v2@latest|ffuf is required for directory fuzzing"
    "assetfinder|go|go install -v github.com/tomnomnom/assetfinder@latest|assetfinder is required for subdomain discovery"
    "httprobe|go|go install -v github.com/tomnomnom/httprobe@latest|httprobe is required for alive detection"
    "gobuster|go|go install -v github.com/OJ/gobuster/v3@latest|gobuster is required for directory scanning"
    "dalfox|go|go install -v github.com/hahwul/dalfox/v2@latest|dalfox is required for XSS detection"
    "gospider|go|go install -v github.com/jaeles-project/gospider@latest|gospider is required for URL crawling"
    "shuffledns|go|go install -v github.com/projectdiscovery/shuffledns/cmd/shuffledns@latest|shuffledns is required for DNS resolution"
    "puredns|go|go install -v github.com/d3mondev/puredns/v2/cmd/puredns@latest|puredns is required for DNS bruteforce"
    "chaos|go|go install -v github.com/projectdiscovery/chaos-client/cmd/chaos@latest|chaos is required for subdomain enumeration"
    "subzy|go|go install -v github.com/michenil/subzy@latest|subzy is required for takeover detection"
    
    # Python-based tools (installed via pip)
    "arjun|pip|pip3 install arjun|arjun is required for parameter discovery"
    "sqlmap|pip|pip3 install sqlmap|sqlmap is required for SQL injection detection"
    "paramspider|pip|pip3 install paramspider|paramspider is required for parameter discovery"
    "dirsearch|pip|pip3 install dirsearch|dirsearch is required for directory fuzzing"
    "wpscan|gem|gem install wpscan|wpscan is required for WordPress scanning"
    "theHarvester|pip|pip3 install theHarvester|theHarvester is required for OSINT"
    "holehe|pip|pip3 install holehe|holehe is required for OSINT"
    "sherlock|pip|pip3 install sherlock-project|sherlock is required for OSINT"
    "trufflehog|pip|pip3 install trufflehog|trufflehog is required for secret detection"
    "git-dumper|pip|pip3 install git-dumper|git-dumper is required for git extraction"
    "s3scanner|pip|pip3 install s3scanner|s3scanner is required for S3 bucket discovery"
    "xnLinkFinder|pip|pip3 install xnLinkFinder|xnLinkFinder is required for JS analysis"
    "feroxbuster|cargo|cargo install feroxbuster|feroxbuster is required for directory scanning"
    
    # System package tools
    "whatweb|system|sudo apt-get install -y whatweb|whatweb is required for technology detection"
    "wafw00f|system|sudo apt-get install -y wafw00f|wafw00f is required for WAF detection"
    "sslscan|system|sudo apt-get install -y sslscan|sslscan is required for SSL analysis"
    "testssl.sh|system|sudo apt-get install -y testssl.sh|testssl.sh is required for SSL testing"
    "nikto|system|sudo apt-get install -y nikto|nikto is required for web scanning"
    "dnsenum|system|sudo apt-get install -y dnsenum|dnsenum is required for DNS enumeration"
    "fierce|system|sudo apt-get install -y fierce|fierce is required for DNS enumeration"
)

# Check if Go is installed
check_go() {
    if ! command -v go >/dev/null 2>&1; then
        echo -e "${INSTALLER_RED}[!] Go is not installed${INSTALLER_RESET}"
        echo -e "${INSTALLER_YELLOW}[*] Installing Go...${INSTALLER_RESET}"
        
        # Download and install Go
        local go_version="1.21.5"
        local go_file="go${go_version}.linux-amd64.tar.gz"
        
        wget -q "https://go.dev/dl/${go_file}" -O "/tmp/${go_file}" 2>/dev/null || {
            echo -e "${INSTALLER_RED}[!] Failed to download Go${INSTALLER_RESET}"
            echo -e "${INSTALLER_YELLOW}[*] Please install Go manually:${INSTALLER_RESET}"
            echo -e "   sudo apt-get install -y golang-go"
            echo -e "   OR"
            echo -e "   wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz"
            echo -e "   sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz"
            return 1
        }
        
        sudo rm -rf /usr/local/go
        sudo tar -C /usr/local -xzf "/tmp/${go_file}" 2>/dev/null
        rm -f "/tmp/${go_file}"
        
        # Add to PATH
        export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"
        echo 'export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"' >> ~/.bashrc
        
        if command -v go >/dev/null 2>&1; then
            echo -e "${INSTALLER_GREEN}[$] Go $(go version | awk '{print $3}') installed successfully${INSTALLER_RESET}"
            return 0
        else
            echo -e "${INSTALLER_RED}[!] Go installation failed${INSTALLER_RESET}"
            return 1
        fi
    fi
    return 0
}

# Check a single tool
check_tool_install() {
    local tool_name="$1"
    local install_cmd="$2"
    local fallback_msg="$3"
    
    echo -e "${INSTALLER_YELLOW}[*] Installing ${tool_name}...${INSTALLER_RESET}"
    
    if eval "$install_cmd" 2>/dev/null; then
        echo -e "${INSTALLER_GREEN}[$] ${tool_name} installed successfully${INSTALLER_RESET}"
        return 0
    else
        echo -e "${INSTALLER_RED}[!] Failed to install ${tool_name}${INSTALLER_RESET}"
        echo -e "${INSTALLER_YELLOW}[*] ${fallback_msg}${INSTALLER_RESET}"
        return 1
    fi
}

# Check and install Python-based GitHub tools
check_github_python_tools() {
    echo -e ""
    echo -e "${INSTALLER_CYAN}${BOLD}Checking GitHub Python Tools...${INSTALLER_RESET}"
    
    # SecretFinder
    if [[ ! -f "/opt/SecretFinder/SecretFinder.py" ]]; then
        echo -e "${INSTALLER_YELLOW}[*] Installing SecretFinder...${INSTALLER_RESET}"
        sudo git clone https://github.com/m4ll0k/SecretFinder.git /opt/SecretFinder 2>/dev/null
        sudo pip3 install -r /opt/SecretFinder/requirements.txt 2>/dev/null
        echo -e "${INSTALLER_GREEN}[$] SecretFinder installed${INSTALLER_RESET}"
    fi
    
    # LinkFinder
    if [[ ! -f "/opt/LinkFinder/linkfinder.py" ]]; then
        echo -e "${INSTALLER_YELLOW}[*] Installing LinkFinder...${INSTALLER_RESET}"
        sudo git clone https://github.com/GerbenJavado/LinkFinder.git /opt/LinkFinder 2>/dev/null
        sudo pip3 install -r /opt/LinkFinder/requirements.txt 2>/dev/null
        echo -e "${INSTALLER_GREEN}[$] LinkFinder installed${INSTALLER_RESET}"
    fi
    
    # cloud_enum
    if [[ ! -f "/opt/cloud_enum/cloud_enum.py" ]]; then
        echo -e "${INSTALLER_YELLOW}[*] Installing cloud_enum...${INSTALLER_RESET}"
        sudo git clone https://github.com/initstring/cloud_enum.git /opt/cloud_enum 2>/dev/null
        sudo pip3 install -r /opt/cloud_enum/requirements.txt 2>/dev/null
        echo -e "${INSTALLER_GREEN}[$] cloud_enum installed${INSTALLER_RESET}"
    fi
}

# Main dependency check function
check_and_install_deps() {
    echo -e ""
    echo -e "${INSTALLER_CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${INSTALLER_RESET}"
    echo -e "${INSTALLER_CYAN}${BOLD}  NishantX Dependency Checker${INSTALLER_RESET}"
    echo -e "${INSTALLER_CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${INSTALLER_RESET}"
    echo -e ""
    
    local missing_count=0
    local installed_count=0
    local manual_install=()
    
    # First check Go
    if ! check_go; then
        echo -e "${INSTALLER_RED}[!] Go installation failed - many tools require Go${INSTALLER_RESET}"
    fi
    
    # Check system update
    echo -e "${INSTALLER_CYAN}[*] Updating package lists...${INSTALLER_RESET}"
    sudo apt-get update -qq 2>/dev/null || echo -e "${INSTALLER_YELLOW}[!] Could not update packages (no sudo?)${INSTALLER_RESET}"
    
    # Check each dependency
    for dep in "${DEPS[@]}"; do
        IFS='|' read -r tool_name category install_cmd fallback_msg <<< "$dep"
        
        # Check if tool exists
        if command -v "$tool_name" >/dev/null 2>&1; then
            echo -e "${INSTALLER_GREEN}[$] ${tool_name} already installed${INSTALLER_RESET}"
            ((installed_count++))
        else
            echo -e "${INSTALLER_YELLOW}[*] ${tool_name} not found - attempting auto-install...${INSTALLER_RESET}"
            
            case "$category" in
                go)
                    if check_tool_install "$tool_name" "$install_cmd" "$fallback_msg"; then
                        ((installed_count++))
                    else
                        ((missing_count++))
                        manual_install+=("$tool_name: $install_cmd")
                    fi
                    ;;
                pip)
                    if check_tool_install "$tool_name" "$install_cmd" "$fallback_msg"; then
                        ((installed_count++))
                    else
                        ((missing_count++))
                        manual_install+=("$tool_name: $install_cmd")
                    fi
                    ;;
                system)
                    if check_tool_install "$tool_name" "$install_cmd" "$fallback_msg"; then
                        ((installed_count++))
                    else
                        ((missing_count++))
                        manual_install+=("$tool_name: sudo apt-get install $tool_name")
                    fi
                    ;;
                gem)
                    if check_tool_install "$tool_name" "$install_cmd" "$fallback_msg"; then
                        ((installed_count++))
                    else
                        ((missing_count++))
                        manual_install+=("$tool_name: $install_cmd")
                    fi
                    ;;
                cargo)
                    if check_tool_install "$tool_name" "$install_cmd" "$fallback_msg"; then
                        ((installed_count++))
                    else
                        ((missing_count++))
                        manual_install+=("$tool_name: $install_cmd")
                    fi
                    ;;
            esac
        fi
    done
    
    # Check Python tools from GitHub
    check_github_python_tools
    
    # Summary
    echo -e ""
    echo -e "${INSTALLER_CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${INSTALLER_RESET}"
    echo -e "${INSTALLER_CYAN}${BOLD}  Dependency Check Summary${INSTALLER_RESET}"
    echo -e "${INSTALLER_CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${INSTALLER_RESET}"
    echo -e "${INSTALLER_GREEN}  Installed/Found: ${installed_count}${INSTALLER_RESET}"
    
    if [[ $missing_count -gt 0 ]]; then
        echo -e "${INSTALLER_RED}  Failed to install: ${missing_count}${INSTALLER_RESET}"
        echo -e ""
        echo -e "${INSTALLER_YELLOW}${BOLD}Manual installation required for:${INSTALLER_RESET}"
        for item in "${manual_install[@]}"; do
            echo -e "  ${INSTALLER_RED}- ${item}${INSTALLER_RESET}"
        done
        echo -e ""
        echo -e "${INSTALLER_YELLOW}Run the following commands manually:${INSTALLER_RESET}"
        for item in "${manual_install[@]}"; do
            echo -e "  ${INSTALLER_CYAN}${item#*: }${INSTALLER_RESET}"
        done
        echo -e ""
        echo -e "${INSTALLER_YELLOW}Alternatively, run: sudo ./installer.sh${INSTALLER_RESET}"
        return 1
    else
        echo -e "${INSTALLER_GREEN}  All dependencies satisfied!${INSTALLER_RESET}"
        return 0
    fi
}

# Quick check only (no install)
quick_deps_check() {
    local essential_tools=("curl" "jq" "nmap" "subfinder" "httpx" "nuclei" "dnsx")
    local missing=()
    
    for tool in "${essential_tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing+=("$tool")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_warn "Missing essential tools: ${missing[*]}"
        log_info "Run: ./nishantx.sh --install-deps"
        return 1
    fi
    return 0
}
