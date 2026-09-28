#!/bin/bash
#
# Linux Login Activity Monitor  (v3)
# Sections: Authentication / Login Types / Source Analysis / Reports
#
# Usage:  sudo ./login_monitor.sh
# Config: AUTH_LOG=/path/to/log ./login_monitor.sh   (optional override)

AUTH_LOG="${AUTH_LOG:-/var/log/auth.log}"
ALERT_THRESHOLD="${ALERT_THRESHOLD:-5}"     # failed attempts per IP before alert
REPORT_DIR="${REPORT_DIR:-$HOME/login_reports}"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

# IPv4 or IPv6 address
IP_RE='(([0-9]{1,3}\.){3}[0-9]{1,3}|[0-9a-fA-F]*:[0-9a-fA-F:]+)'

# ---------- banner ----------
show_banner() {
    local cols; cols=$(tput cols 2>/dev/null || echo 80)
    if (( cols >= 145 )); then
        echo -e "${GREEN}"
        cat << 'BANNER'
██╗     ██╗███╗   ██╗██╗   ██╗██╗  ██╗    ██╗      ██████╗  ██████╗ ██╗███╗   ██╗    ███╗   ███╗ ██████╗ ███╗   ██╗██╗████████╗ ██████╗ ██████╗ 
██║     ██║████╗  ██║██║   ██║╚██╗██╔╝    ██║     ██╔═══██╗██╔════╝ ██║████╗  ██║    ████╗ ████║██╔═══██╗████╗  ██║██║╚══██╔══╝██╔═══██╗██╔══██╗
██║     ██║██╔██╗ ██║██║   ██║ ╚███╔╝     ██║     ██║   ██║██║  ███╗██║██╔██╗ ██║    ██╔████╔██║██║   ██║██╔██╗ ██║██║   ██║   ██║   ██║██████╔╝
██║     ██║██║╚██╗██║██║   ██║ ██╔██╗     ██║     ██║   ██║██║   ██║██║██║╚██╗██║    ██║╚██╔╝██║██║   ██║██║╚██╗██║██║   ██║   ██║   ██║██╔══██╗
███████╗██║██║ ╚████║╚██████╔╝██╔╝ ██╗    ███████╗╚██████╔╝╚██████╔╝██║██║ ╚████║    ██║ ╚═╝ ██║╚██████╔╝██║ ╚████║██║   ██║   ╚██████╔╝██║  ██║
╚══════╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝    ╚══════╝ ╚═════╝  ╚═════╝ ╚═╝╚═╝  ╚═══╝    ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝
BANNER
        echo -e "${NC}"
    else
        # Terminal too narrow for the big banner: use a compact one
        echo -e "${GREEN}======================================================"
        echo "           LINUX LOGIN ACTIVITY MONITOR"
        echo -e "======================================================${NC}"
        echo -e "${YELLOW}(tip: zoom out the terminal, Ctrl + minus, to see the full banner)${NC}"
    fi
}

# ---------- log source ----------
# Uses auth.log if readable, otherwise falls back to the systemd journal.
get_log() {
    if [[ -r "$AUTH_LOG" ]]; then
        tr -d '\000' < "$AUTH_LOG"
    elif command -v journalctl &>/dev/null; then
        journalctl -t sshd -t sshd-session -t sudo -t su -t login --no-pager -o short 2>/dev/null | tr -d '\000'
    fi
}

check_log() {
    if [[ ! -r "$AUTH_LOG" ]] && ! command -v journalctl &>/dev/null; then
        echo -e "${RED}No readable log. Run with sudo or set AUTH_LOG.${NC}"; exit 1
    fi
    if [[ -z "$(get_log | head -n1)" ]]; then
        echo -e "${RED}Log is empty or unreadable. Try: sudo $0${NC}"; exit 1
    fi
}

# ---------- helpers ----------
pause() { echo; read -rp "Press Enter to continue..."; }

header() {
    clear
    echo -e "${GREEN}======================================================"
    printf "  %s\n" "$1"
    echo -e "======================================================${NC}\n"
}

is_private_ip() {
    [[ "$1" =~ ^(10\.|127\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[01])\.|169\.254\.|::1$|fe80:) ]]
}

# Prints piped input, or a friendly message if there is nothing
show_or_none() {
    local out; out=$(cat)
    if [[ -n "$out" ]]; then
        echo "$out"
    else
        echo -e "${YELLOW}No matching entries found in the log yet.${NC}"
    fi
}

failed_lines()  { get_log | grep -E "Failed password|Invalid user|authentication failure"; }
success_lines() { get_log | grep -E "Accepted (password|publickey|keyboard-interactive)"; }
failed_ip_counts() {
    failed_lines | grep -Eo "from $IP_RE" | awk '{print $2}' | sort | uniq -c | sort -rn
}

# ---------- Section 1: Authentication ----------
show_login_summary() {
    header "LOGIN SUMMARY"
    local ok bad
    ok=$(success_lines | wc -l); bad=$(failed_lines | wc -l)
    echo -e "Successful logins : ${GREEN}$ok${NC}"
    echo -e "Failed logins     : ${RED}$bad${NC}"
    echo -e "Total attempts    : ${CYAN}$((ok + bad))${NC}"
    echo -e "Unique failed IPs : ${YELLOW}$(failed_ip_counts | wc -l)${NC}"
}
show_successful_logins() { header "SUCCESSFUL LOGINS (last 50)"; success_lines | tail -n 50 | show_or_none; }
show_failed_logins()     { header "FAILED LOGINS (last 50)";     failed_lines  | tail -n 50 | show_or_none; }

# ---------- Section 2: Login types ----------
show_ssh_logins() {
    header "SSH LOGINS"
    get_log | grep -E "sshd.*(Accepted|Failed)" | tail -n 50 | show_or_none
}
show_sudo_usage() {
    header "SUDO USAGE"
    get_log | grep -E "sudo:.*COMMAND=" | tail -n 50 | show_or_none
}
show_su_usage() {
    header "SU (SWITCH USER) EVENTS"
    get_log | grep -E "su(\[[0-9]+\])?: " | grep -Ei "session opened|failed|FAILED su|\(to " | tail -n 50 | show_or_none
}
show_local_logins() {
    header "LOCAL / CONSOLE LOGINS"
    get_log | grep -E "login\[[0-9]+\]|systemd-logind.*New session|lightdm|gdm" | tail -n 50 | show_or_none
}

# ---------- Section 3: Source analysis ----------
show_source_ips() {
    header "SOURCE IP ADDRESSES (all attempts)"
    local out
    out=$(get_log | grep -Eo "from $IP_RE" | awk '{print $2}' | sort | uniq -c | sort -rn \
        | awk '{printf "%-8s %s\n", $1, $2}')
    if [[ -n "$out" ]]; then
        printf "%-8s %s\n" "COUNT" "IP"
        echo "$out"
    else
        echo -e "${YELLOW}No source IPs found in the log yet.${NC}"
    fi
}

show_failed_ip_locations() {
    header "FAILED LOGIN — IP LOCATIONS"
    local counts; counts=$(failed_ip_counts)
    if [[ -z "$counts" ]]; then echo -e "${YELLOW}No failed logins found.${NC}"; return; fi
    if ! command -v curl &>/dev/null; then
        echo -e "${RED}curl not installed: sudo apt install curl${NC}"; return
    fi
    printf "${YELLOW}%-7s %-16s %s${NC}\n" "COUNT" "IP" "LOCATION (ISP)"
    echo "------------------------------------------------------------"
    while read -r count ip; do
        [[ -z "$ip" ]] && continue
        if is_private_ip "$ip"; then
            printf "%-7s %-16s %s\n" "$count" "$ip" "Private / local network"
            continue
        fi
        local info
        info=$(curl -s --max-time 4 "http://ip-api.com/line/${ip}?fields=status,country,regionName,city,isp")
        if [[ "$(sed -n '1p' <<< "$info")" == "success" ]]; then
            printf "%-7s %-16s %s, %s, %s (%s)\n" "$count" "$ip" \
                "$(sed -n '4p' <<< "$info")" "$(sed -n '3p' <<< "$info")" \
                "$(sed -n '2p' <<< "$info")" "$(sed -n '5p' <<< "$info")"
        else
            printf "%-7s %-16s %s\n" "$count" "$ip" "Lookup failed (no internet / rate limit)"
        fi
        sleep 1.5   # stay under ip-api free limit (45 req/min)
    done <<< "$counts"
}

# ---------- Section 4: Reports ----------
generate_security_report() {
    header "GENERATE SECURITY REPORT"
    mkdir -p "$REPORT_DIR"
    local file="$REPORT_DIR/security_report_$(date +%Y%m%d_%H%M%S).txt"
    {
        echo "SECURITY REPORT - $(date)"
        echo "Host: $(hostname)   Log: $AUTH_LOG"
        echo "=========================================="
        echo "Successful logins : $(success_lines | wc -l)"
        echo "Failed logins     : $(failed_lines | wc -l)"
        echo "Sudo commands     : $(get_log | grep -c 'sudo:.*COMMAND=')"
        echo
        echo "Top failed-login source IPs:"
        failed_ip_counts | head -n 10 | awk '{printf "  %-6s %s\n", $1, $2}'
        echo
        echo "Users targeted by failed logins:"
        failed_lines | grep -Eo "(for (invalid user )?|Invalid user )[A-Za-z0-9._-]+" \
            | awk '{print $NF}' | sort | uniq -c | sort -rn | head -n 10 | awk '{printf "  %-6s %s\n", $1, $2}'
    } | tee "$file"
    echo -e "\n${GREEN}Saved to: $file${NC}"
}

security_alert_check() {
    header "SECURITY ALERT CHECK (threshold: $ALERT_THRESHOLD)"
    local hits
    hits=$(failed_ip_counts | awk -v t="$ALERT_THRESHOLD" '$1 >= t {printf "  [ALERT] %s failed attempts from %s\n", $1, $2}')
    if [[ -n "$hits" ]]; then
        echo -e "${RED}$hits${NC}"
        echo -e "\n${YELLOW}Possible brute-force. Consider: sudo ufw deny from <IP>${NC}"
    else
        echo -e "${GREEN}No IPs at or above the threshold. All clear.${NC}"
    fi
}

# ---------- menus ----------
run_menu() {   # run_menu "TITLE" "opt1|func1" "opt2|func2" ...
    local title="$1"; shift
    local items=("$@") n=$# choice i
    while true; do
        header "$title"
        for i in "${!items[@]}"; do echo "$((i+1)). ${items[$i]%%|*}"; done
        echo "$((n+1)). Back to Main Menu"
        echo
        read -rp "Enter your choice: " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= n )); then
            "${items[$((choice-1))]##*|}"; pause
        elif [[ "$choice" == "$((n+1))" ]]; then return
        else echo -e "${RED}Invalid choice.${NC}"; sleep 1; fi
    done
}

main_menu() {
    while true; do
        clear
        show_banner
        echo
        echo "1. Authentication     (summary, successful, failed)"
        echo "2. Login Types        (SSH, sudo, su, local console)"
        echo "3. Source Analysis    (IPs, failed-login locations)"
        echo "4. Reports            (security report, alert check)"
        echo "5. Exit"
        echo
        read -rp "Enter your choice: " choice
        case "$choice" in
            1) run_menu "AUTHENTICATION" \
                "Show Login Summary|show_login_summary" \
                "Show Successful Logins|show_successful_logins" \
                "Show Failed Logins|show_failed_logins" ;;
            2) run_menu "LOGIN TYPES" \
                "SSH Logins|show_ssh_logins" \
                "Sudo Usage|show_sudo_usage" \
                "Su (Switch User) Events|show_su_usage" \
                "Local / Console Logins|show_local_logins" ;;
            3) run_menu "SOURCE ANALYSIS" \
                "Show Source IP Addresses|show_source_ips" \
                "Show Failed Login IP Locations|show_failed_ip_locations" ;;
            4) run_menu "REPORTS" \
                "Generate Security Report|generate_security_report" \
                "Security Alert Check|security_alert_check" ;;
            5) echo "Goodbye."; exit 0 ;;
            *) echo -e "${RED}Invalid choice.${NC}"; sleep 1 ;;
        esac
    done
}

# Only start the UI when executed directly (lets the functions be tested/sourced)
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    check_log
    main_menu
fi
