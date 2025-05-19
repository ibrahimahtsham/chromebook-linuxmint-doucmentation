#!/bin/bash

# Colors
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
BLUE="\e[34m"
CYAN="\e[36m"
RESET="\e[0m"

# Required packages
PACKAGES=("tcpdump" "dnsutils" "net-tools" "tshark" "iftop" "arp-scan" "nmap" "gawk")

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

check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}This script requires root access.${RESET}"
        echo -e "${YELLOW}Please run with: sudo $0${RESET}"
        exit 1
    fi
}

# Automatically select the best interface
get_best_interface() {
    # First try to find a wireless interface with an IP address
    best_interface=$(ip -o link show | grep -i "state UP" | grep -i wireless | head -n 1 | awk -F': ' '{print $2}')
    
    # If no wireless interface, try any interface that's UP with an IP (excluding loopback)
    if [[ -z "$best_interface" ]]; then
        best_interface=$(ip -o link show | grep -i "state UP" | grep -v "LOOPBACK" | head -n 1 | awk -F': ' '{print $2}')
    fi
    
    # Still nothing? Try any non-loopback interface
    if [[ -z "$best_interface" ]]; then
        best_interface=$(ip -o link show | grep -v "LOOPBACK" | head -n 1 | awk -F': ' '{print $2}')
    fi
    
    echo "$best_interface"
}

# Get network gateway
get_gateway() {
    gateway=$(ip route | grep default | awk '{print $3}' | head -n 1)
    echo "$gateway"
}

# Function to monitor DNS with filtering
monitor_dns_with_filter() {
    local interface=$1
    local filter=$2
    
    echo -e "\n${GREEN}▶ Monitoring DNS lookups (websites being visited)...${RESET}"
    echo -e "${YELLOW}Using network connection: $interface${RESET}"
    echo -e "${CYAN}Trying to capture traffic from all network devices${RESET}"
    echo -e "${YELLOW}Press Ctrl+C when you want to stop monitoring${RESET}"
    
    if [[ -n "$filter" ]]; then
        echo -e "${GREEN}Filtering for: $filter${RESET}"
        echo ""
        sudo tcpdump -i $interface -l -n -v 'udp port 53' | grep --line-buffered -i "$filter"
    else
        echo -e "${GREEN}Showing all DNS queries (type a filter term to narrow results)${RESET}"
        echo -e "${YELLOW}While monitoring: press Tab then type a domain to filter (e.g. facebook)${RESET}"
        echo ""
        # Using awk to format the output more clearly
        sudo tcpdump -i $interface -l -n -v 'udp port 53' | awk '/A\?/ {print "\033[36m" $1 " \033[33mDevice:\033[0m " $3 " \033[33mlookup:\033[0m " $8}'
    fi
}

scan_network_devices() {
    local interface=$1
    
    echo -e "\n${GREEN}▶ Scanning for all devices on your network...${RESET}"
    echo -e "${YELLOW}Using network connection: $interface${RESET}"
    echo -e "${YELLOW}This may take a few minutes for a thorough scan...${RESET}"
    
    # Get the network range
    local ip=$(ip -o -4 addr show $interface | awk '{print $4}' | cut -d/ -f1)
    local prefix=$(ip -o -4 addr show $interface | awk '{print $4}' | cut -d/ -f2)
    local gateway=$(get_gateway)
    
    if [[ -z "$ip" ]]; then
        echo -e "${RED}Could not determine IP address.${RESET}"
        return
    fi
    
    # Extract network base for scanning
    local base_ip=$(echo $ip | cut -d. -f1-3)
    
    echo -e "${CYAN}Your IP address: $ip${RESET}"
    echo -e "${CYAN}Gateway: $gateway${RESET}"
    echo -e "${CYAN}Scanning network: $base_ip.0/24${RESET}"
    echo ""
    
    # Deep network scan with device identification
    echo -e "${GREEN}Quick scan using ARP...${RESET}"
    sudo arp-scan --interface=$interface --localnet
    
    echo -e "\n${GREEN}Detailed scan (identifies phones and other devices)...${RESET}"
    echo -e "${YELLOW}This will take longer but provide better device information${RESET}"
    
    # Only proceed with nmap if the user wants to
    read -p "Run detailed device scan? This may take 3-5 minutes [Y/n]: " confirm
    if [[ "$confirm" =~ ^[Yy]$ || -z "$confirm" ]]; then
        sudo nmap -sn $base_ip.0/24 --script broadcast-dhcp-discover
    fi
}

# Enhanced menu with filtering options
show_menu() {
    clear
    echo -e "${BLUE}🌐 Network Monitoring Tool${RESET}"
    echo "-----------------------------------------"
    echo "1) Monitor DNS lookups (websites being visited)"
    echo "2) Monitor all network traffic by device"
    echo "3) Scan for devices on your network (finds phones)"
    echo "4) Monitor bandwidth usage by application"
    echo "5) Capture all network traffic to a file"
    echo "6) View website requests on your network"
    echo "7) Search for specific network activity"
    echo "8) Exit"
    echo "-----------------------------------------"
    read -p "Choose an option [1-8]: " choice

    # Get the best available interface automatically
    interface=$(get_best_interface)
    if [[ -z "$interface" ]]; then
        echo -e "${RED}Error: No network interface found.${RESET}"
        echo -e "${YELLOW}Please check your network connection.${RESET}"
        read -p "Press Enter to continue..." key
        show_menu
        return
    fi
    
    case "$choice" in
        1)
            echo -e "\n${CYAN}Do you want to filter for specific domains?${RESET}"
            read -p "Enter filter term (leave empty for all): " filter
            
            # Enable promiscuous mode temporarily to try to capture more traffic
            echo -e "${YELLOW}Enabling promiscuous mode to try capturing traffic from other devices...${RESET}"
            sudo ip link set $interface promisc on
            
            monitor_dns_with_filter "$interface" "$filter"
            
            # Disable promiscuous mode when done
            sudo ip link set $interface promisc off
            ;;
        2)
            echo -e "\n${GREEN}▶ Monitoring network traffic by device...${RESET}"
            echo -e "${YELLOW}Using network connection: $interface${RESET}"
            echo -e "${YELLOW}Press q to stop monitoring${RESET}"
            sudo iftop -i $interface -P || {
                echo -e "${RED}Error running traffic monitor.${RESET}"
            }
            ;;
        3)
            scan_network_devices "$interface"
            ;;
        4)
            echo -e "\n${GREEN}▶ Monitoring bandwidth usage by application...${RESET}"
            echo -e "${YELLOW}Press q to stop monitoring${RESET}"
            sudo nethogs || {
                echo -e "${RED}Error running application bandwidth monitor.${RESET}"
            }
            ;;
        5)
            echo -e "\n${GREEN}▶ Capturing network traffic to file...${RESET}"
            echo -e "${YELLOW}Using network connection: $interface${RESET}"
            filename="network_capture_$(date +%Y%m%d_%H%M%S).pcap"
            
            echo -e "${CYAN}Do you want to capture specific traffic?${RESET}"
            echo "1) All traffic"
            echo "2) DNS traffic only (domains)"
            echo "3) HTTP/HTTPS traffic only (websites)"
            echo "4) Custom filter"
            read -p "Choose filter [1-4]: " filter_choice
            
            filter_cmd=""
            case "$filter_choice" in
                2) filter_cmd="udp port 53" ;;
                3) filter_cmd="tcp port 80 or tcp port 443" ;;
                4) 
                    read -p "Enter tcpdump filter expression: " custom_filter
                    filter_cmd="$custom_filter"
                    ;;
                *) filter_cmd="" ;;
            esac
            
            echo -e "Saving to: ${GREEN}$filename${RESET}"
            echo -e "${YELLOW}Press Ctrl+C when you want to stop capturing${RESET}"
            
            if [[ -n "$filter_cmd" ]]; then
                sudo tcpdump -i $interface -w $filename "$filter_cmd" || {
                    echo -e "${RED}Error capturing network traffic.${RESET}"
                }
            else
                sudo tcpdump -i $interface -w $filename || {
                    echo -e "${RED}Error capturing network traffic.${RESET}"
                }
            fi
            
            echo -e "${GREEN}File saved as $filename${RESET}"
            ;;
        6)
            echo -e "\n${GREEN}▶ Monitoring website requests...${RESET}"
            echo -e "${YELLOW}Using network connection: $interface${RESET}"
            echo -e "${CYAN}Do you want to filter for specific sites?${RESET}"
            read -p "Enter filter term (leave empty for all): " web_filter
            echo -e "${YELLOW}Press Ctrl+C when you want to stop monitoring${RESET}"
            echo ""
            
            if [[ -n "$web_filter" ]]; then
                sudo tcpdump -i $interface -A -s 0 'tcp port 80 or tcp port 443' | grep -E --line-buffered -i "Host:|GET|POST|$web_filter" || {
                    echo -e "${RED}Error monitoring website requests.${RESET}"
                }
            else
                sudo tcpdump -i $interface -A -s 0 'tcp port 80 or tcp port 443' | grep -E --line-buffered 'Host:|GET|POST' || {
                    echo -e "${RED}Error monitoring website requests.${RESET}"
                }
            fi
            ;;
        7)
            echo -e "\n${GREEN}▶ Search for specific network activity${RESET}"
            read -p "Enter search term (domain, IP, etc): " search_term
            
            if [[ -z "$search_term" ]]; then
                echo -e "${RED}Search term cannot be empty.${RESET}"
            else
                echo -e "\n${YELLOW}Searching for: $search_term${RESET}"
                echo -e "${YELLOW}Press Ctrl+C when you want to stop searching${RESET}"
                sudo tcpdump -i $interface -l -n | grep --line-buffered -i "$search_term"
            fi
            ;;
        8)
            echo -e "${GREEN}👋 Exiting...${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Invalid choice. Please enter a number between 1 and 8.${RESET}"
            ;;
    esac
    read -p "Press Enter to return to the menu..." key
    show_menu
}

# Main
clear
echo -e "${BLUE}=== Enhanced Network Traffic Monitor ===${RESET}"
echo -e "${YELLOW}This tool helps you monitor network activity, including other devices${RESET}"
echo -e "${YELLOW}NOTE: Monitoring other devices only works on certain network configurations${RESET}"
check_root
check_and_install
show_menu