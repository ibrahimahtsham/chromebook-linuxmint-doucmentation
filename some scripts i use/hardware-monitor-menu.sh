#!/bin/bash

# Colors
GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"

# Required packages
PACKAGES=("cpufrequtils" "thermald" "gnome-system-monitor")

check_and_install() {
    for pkg in "${PACKAGES[@]}"; do
        if ! dpkg -s "$pkg" &> /dev/null; then
            echo -e "${RED}$pkg is not installed.${RESET}"
            read -p "Do you want to install $pkg? [Y/n]: " confirm
            if [[ "$confirm" =~ ^[Yy]$ || -z "$confirm" ]]; then
                sudo apt update && sudo apt install -y "$pkg"
            fi
        else
            echo -e "${GREEN}$pkg is installed.${RESET}"
        fi
    done
}

show_menu() {
    clear
    echo -e "${GREEN}📊 System Performance & Monitoring Menu${RESET}"
    echo "-----------------------------------------"
    echo "1) Show current CPU frequency info        (via cpufreq-info)"
    echo "2) Set CPU governor to performance        (via cpufreq-set)"
    echo "3) Start thermald to help manage temps    (via systemctl)"
    echo "4) Launch GUI System Monitor              (via gnome-system-monitor)"
    echo "5) Exit"
    echo "-----------------------------------------"
    read -p "Choose an option [1-5]: " choice

    case "$choice" in
        1)
            echo -e "\n${GREEN}▶ CPU Frequency Info:${RESET}"
            cpufreq-info | less
            ;;
        2)
            echo -e "\n${GREEN}▶ Setting CPU governor to 'performance'...${RESET}"
            sudo cpufreq-set -r -g performance
            echo -e "${GREEN}✅ Done.${RESET}"
            ;;
        3)
            echo -e "\n${GREEN}▶ Starting thermald service...${RESET}"
            sudo systemctl enable --now thermald
            echo -e "${GREEN}✅ thermald is active.${RESET}"
            ;;
        4)
            echo -e "\n${GREEN}▶ Launching gnome-system-monitor...${RESET}"
            nohup gnome-system-monitor >/dev/null 2>&1 &
            ;;
        5)
            echo -e "${GREEN}👋 Exiting...${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Invalid choice. Try again.${RESET}"
            ;;
    esac
    read -p "Press Enter to continue..." key
    show_menu
}

# Main
check_and_install
show_menu

