#!/bin/bash

# ==========================================================
# LINUX LOGIN ACTIVITY MONITOR
# Cybersecurity Project - Bash
# ==========================================================

REPORT_FILE="$HOME/linux-login-monitor/security_report.txt"
ALERT_THRESHOLD=3


# ----------------------------------------------------------
# GET SSH LOGS
# ----------------------------------------------------------

get_logs() {
    sudo journalctl -u ssh --no-pager 2>/dev/null
}


# ----------------------------------------------------------
# COUNT SUCCESSFUL LOGINS
# ----------------------------------------------------------

successful_logins() {
    get_logs | grep -i "Accepted password" | wc -l
}


# ----------------------------------------------------------
# COUNT FAILED LOGINS
# ----------------------------------------------------------

failed_logins() {
    get_logs | grep -i "Failed password" | wc -l
}


# ----------------------------------------------------------
# GET FAILED LOGIN IP ADDRESSES
# Removes local/private addresses
# ----------------------------------------------------------

get_failed_ips() {

    get_logs |
    grep -i "Failed password" |
    awk '{
        for (i=1; i<=NF; i++) {
            if ($i=="from") {
                print $(i+1)
            }
        }
    }' |
    sort -u |
    while read -r IP
    do

        # Ignore IPv6 loopback
        [ "$IP" = "::1" ] && continue

        # Ignore IPv4 loopback
        echo "$IP" | grep -Eq '^127\.' && continue

        # Ignore private 10.x.x.x
        echo "$IP" | grep -Eq '^10\.' && continue

        # Ignore private 192.168.x.x
        echo "$IP" | grep -Eq '^192\.168\.' && continue

        # Ignore private 172.16.x.x - 172.31.x.x
        echo "$IP" | grep -Eq '^172\.(1[6-9]|2[0-9]|3[0-1])\.' && continue

        # Ignore link-local 169.254.x.x
        echo "$IP" | grep -Eq '^169\.254\.' && continue

        # Ignore IPv6 link-local
        echo "$IP" | grep -Eiq '^fe80:' && continue

        echo "$IP"

    done
}


# ----------------------------------------------------------
# SHOW LOGIN SUMMARY
# ----------------------------------------------------------

show_summary() {

    clear

    SUCCESS=$(successful_logins)
    FAILED=$(failed_logins)

    echo "=========================================="
    echo "       LINUX LOGIN ACTIVITY MONITOR"
    echo "=========================================="
    echo
    echo "Date and Time        : $(date)"
    echo "System User          : $(whoami)"
    echo "Hostname             : $(hostname)"
    echo
    echo "------------- LOGIN SUMMARY -------------"
    echo
    echo "Successful SSH Logins : $SUCCESS"
    echo "Failed SSH Logins     : $FAILED"
    echo "Alert Threshold       : $ALERT_THRESHOLD"
    echo

    if [ "$FAILED" -ge "$ALERT_THRESHOLD" ]; then

        echo "STATUS  : SECURITY ALERT"
        echo "MESSAGE : Multiple failed SSH login attempts detected."

    elif [ "$FAILED" -gt 0 ]; then

        echo "STATUS  : WARNING"
        echo "MESSAGE : Failed SSH login attempts detected."

    else

        echo "STATUS  : NORMAL"
        echo "MESSAGE : No failed SSH login attempts detected."

    fi

    echo
    echo "=========================================="
}


# ----------------------------------------------------------
# SHOW SUCCESSFUL LOGINS
# ----------------------------------------------------------

show_successful() {

    clear

    echo "=========================================="
    echo "          SUCCESSFUL SSH LOGINS"
    echo "=========================================="
    echo

    LOGS=$(get_logs | grep -i "Accepted password")

    if [ -z "$LOGS" ]; then

        echo "No successful SSH logins found."

    else

        echo "$LOGS"

    fi

    echo
    echo "=========================================="
}


# ----------------------------------------------------------
# SHOW FAILED LOGINS
# ----------------------------------------------------------

show_failed() {

    clear

    echo "=========================================="
    echo "             FAILED SSH LOGINS"
    echo "=========================================="
    echo

    LOGS=$(get_logs | grep -i "Failed password")

    if [ -z "$LOGS" ]; then

        echo "No failed SSH logins found."

    else

        echo "$LOGS"

    fi

    echo
    echo "=========================================="
}


# ----------------------------------------------------------
# SHOW FAILED PUBLIC IP LOCATIONS
# ----------------------------------------------------------

show_locations() {

    clear

    echo "=========================================="
    echo "        FAILED LOGIN IP LOCATIONS"
    echo "=========================================="
    echo

    IPS=$(get_failed_ips)

    if [ -z "$IPS" ]; then

        echo "No public failed-login IP addresses found."
        echo
        echo "Local addresses such as ::1 are ignored."

        echo
        echo "=========================================="
        return

    fi


    for IP in $IPS
    do

        echo "IP Address : $IP"

        RESULT=$(curl -s --max-time 10 "https://ipwho.is/$IP")

        if echo "$RESULT" | jq -e '.success == true' >/dev/null 2>&1; then

            echo "$RESULT" | jq -r '"Country    : \(.country)
Region     : \(.region)
City       : \(.city)"'

        else

            echo "Country    : Unknown"
            echo "Region     : Unknown"
            echo "City       : Unknown"

        fi

        echo "------------------------------------------"

    done

    echo
    echo "=========================================="
}


# ----------------------------------------------------------
# GENERATE SECURITY REPORT
# ----------------------------------------------------------

generate_report() {

    SUCCESS=$(successful_logins)
    FAILED=$(failed_logins)

    {
        echo "=========================================="
        echo "        LINUX LOGIN SECURITY REPORT"
        echo "=========================================="
        echo
        echo "Date and Time : $(date)"
        echo "System User   : $(whoami)"
        echo "Hostname      : $(hostname)"
        echo
        echo "------------- LOGIN SUMMARY -------------"
        echo
        echo "Successful SSH Logins : $SUCCESS"
        echo "Failed SSH Logins     : $FAILED"
        echo "Alert Threshold       : $ALERT_THRESHOLD"
        echo

        if [ "$FAILED" -ge "$ALERT_THRESHOLD" ]; then

            echo "Status  : SECURITY ALERT"
            echo "Message : Multiple failed SSH login attempts detected."

        elif [ "$FAILED" -gt 0 ]; then

            echo "Status  : WARNING"
            echo "Message : Failed SSH login attempts detected."

        else

            echo "Status  : NORMAL"
            echo "Message : No failed SSH login attempts detected."

        fi

        echo
        echo "--------- PUBLIC FAILED LOGIN IPS --------"
        echo

        IPS=$(get_failed_ips)

        if [ -z "$IPS" ]; then

            echo "No public failed-login IP addresses found."

        else

            echo "$IPS"

        fi

        echo
        echo "=========================================="

    } > "$REPORT_FILE"

    echo
    echo "Security report generated:"
    echo "$REPORT_FILE"
}


# ----------------------------------------------------------
# SECURITY ALERT CHECK
# ----------------------------------------------------------

security_alert() {

    clear

    FAILED=$(failed_logins)

    echo "=========================================="
    echo "             SECURITY ALERT"
    echo "=========================================="
    echo

    if [ "$FAILED" -ge "$ALERT_THRESHOLD" ]; then

        echo "ALERT: Multiple failed SSH login attempts!"
        echo
        echo "Failed Attempts : $FAILED"
        echo "Threshold       : $ALERT_THRESHOLD"
        echo
        echo "Public Failed Login IPs:"
        echo

        IPS=$(get_failed_ips)

        if [ -z "$IPS" ]; then
            echo "No public IP addresses found."
        else
            echo "$IPS"
        fi

    elif [ "$FAILED" -gt 0 ]; then

        echo "WARNING: Failed SSH login attempts detected."
        echo
        echo "Failed Attempts : $FAILED"

    else

        echo "NORMAL: No failed SSH login attempts detected."

    fi

    echo
    echo "=========================================="
}


# ----------------------------------------------------------
# MAIN MENU
# ----------------------------------------------------------

while true
do
    clear

    echo "=================================================="
    echo "             LINUX LOGIN ACTIVITY MONITOR"
    echo "=================================================="
    echo
    echo "1. Show Login Summary"
    echo "2. Show Successful Logins"
    echo "3. Show Failed Logins"
    echo "4. Show Source IP Addresses"
    echo "5. Show Failed IP Locations"
    echo "6. Generate Security Report"
    echo "7. Security Alert Check"
    echo "8. Exit"
    echo

    read -p "Enter your choice: " choice

    case $choice in

        1)
            show_summary
            read -p "Press Enter to continue..."
            ;;

        2)
            show_successful
            read -p "Press Enter to continue..."
            ;;

        3)
            show_failed
            read -p "Press Enter to continue..."
            ;;

        4)
            show_ips
            read -p "Press Enter to continue..."
            ;;

        5)
            get_failed_ip_location
            read -p "Press Enter to continue..."
            ;;

        6)
            generate_report
            read -p "Press Enter to continue..."
            ;;

        7)
            security_alert
            read -p "Press Enter to continue..."
            ;;

        8)
            echo
            echo "Exiting Login Activity Monitor..."
            exit 0
            ;;

        *)
            echo
            echo "Invalid choice!"
            sleep 2
            ;;

    esac
done
