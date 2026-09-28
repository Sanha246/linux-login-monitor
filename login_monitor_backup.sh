#!/bin/bash

REPORT="login_report.txt"

show_header() {
    clear
    echo "=========================================="
    echo "       LINUX LOGIN ACTIVITY MONITOR"
    echo "=========================================="
    echo ""
}

show_summary() {
    SUCCESS=$(sudo journalctl -u ssh --no-pager | grep -ic "accepted")
    FAILED=$(sudo journalctl -u ssh --no-pager | grep -ic "failed")

    echo "Date and Time : $(date)"
    echo "Current User : $(whoami)"
    echo ""
    echo "Successful SSH Logins : $SUCCESS"
    echo "Failed SSH Logins     : $FAILED"
    echo ""
}

show_logins() {
    echo "Recent Successful Logins"
    echo "------------------------------------------"

    sudo journalctl -u ssh --no-pager |
    grep -i "accepted" |
    tail -10

    echo ""
}

show_failed() {
    echo "Failed Login Attempts"
    echo "------------------------------------------"

    sudo journalctl -u ssh --no-pager |
    grep -i "failed" |
    tail -10

    echo ""
}

show_ips() {
    echo "Login Source IP Addresses"
    echo "------------------------------------------"

    sudo journalctl -u ssh --no-pager |
    grep -i "accepted" |
    awk '{print $(NF-3)}' |
    sort |
    uniq -c |
    sort -nr

    echo ""
}

generate_report() {

    SUCCESS=$(sudo journalctl -u ssh --no-pager | grep -ic "accepted")
    FAILED=$(sudo journalctl -u ssh --no-pager | grep -ic "failed")

    {
        echo "=========================================="
        echo "       LINUX LOGIN ACTIVITY REPORT"
        echo "=========================================="
        echo ""
        echo "Date and Time : $(date)"
        echo "Current User : $(whoami)"
        echo ""
        echo "Successful SSH Logins : $SUCCESS"
        echo "Failed SSH Logins     : $FAILED"
        echo ""
        echo "Login Source IP Addresses"
        echo "------------------------------------------"

        sudo journalctl -u ssh --no-pager |
        grep -i "accepted" |
        awk '{print $(NF-3)}' |
        sort |
        uniq -c |
        sort -nr

        echo ""
        echo "Recent SSH Events"
        echo "------------------------------------------"

        sudo journalctl -u ssh --no-pager |
        grep -Ei "accepted|failed" |
        tail -10

        echo ""
        echo "=========================================="
    } > "$REPORT"

    echo "Report generated successfully!"
    echo "Saved as: $REPORT"
    echo ""
}

while true
do

    show_header

    echo "1. Show Login Summary"
    echo "2. Show Successful Logins"
    echo "3. Show Failed Logins"
    echo "4. Show Source IP Addresses"
    echo "5. Generate Security Report"
    echo "6. Exit"
    echo ""

    read -p "Enter your choice: " choice

    case $choice in

        1)
            show_summary
            read -p "Press Enter to continue..."
            ;;

        2)
            show_logins
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
            generate_report
            read -p "Press Enter to continue..."
            ;;

        6)
            echo "Exiting Login Activity Monitor..."
            exit 0
            ;;

        *)
            echo "Invalid choice!"
            sleep 2
            ;;

    esac

done
