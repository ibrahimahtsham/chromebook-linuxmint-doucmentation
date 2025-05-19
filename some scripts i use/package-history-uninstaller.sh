#!/bin/bash

# Colors
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
BLUE="\e[34m"
CYAN="\e[36m"
RESET="\e[0m"

# Function to check for required tools
check_requirements() {
    for cmd in apt-get dpkg; do
        if ! command -v $cmd &> /dev/null; then
            echo -e "${RED}Error: $cmd not found. This script requires $cmd to function.${RESET}"
            exit 1
        fi
    done
}

# Function to get packages sorted by installation date
get_packages_by_date() {
    echo -e "${YELLOW}Analyzing package installation history...${RESET}"
    
    # Get timestamps from dpkg info directory
    local packages=()
    local timestamps=()
    
    # Read package timestamps from list files
    while read -r file; do
        pkg=$(basename "$file" .list)
        timestamp=$(stat -c %Y "$file")
        packages+=("$pkg")
        timestamps+=("$timestamp")
    done < <(find /var/lib/dpkg/info -name "*.list" -type f)
    
    # Sort packages by timestamp (most recent first)
    local sorted_packages=()
    for i in $(for i in "${!timestamps[@]}"; do echo "$i ${timestamps[$i]}"; done | sort -k2 -nr | cut -d' ' -f1); do
        # Skip packages that start with lib or end with -dev (to reduce clutter)
        if [[ ! "${packages[$i]}" =~ ^lib ]] && [[ ! "${packages[$i]}" =~ -dev$ ]]; then
            local pkg_desc=$(apt-cache show ${packages[$i]} 2>/dev/null | grep -m 1 "Description:" | sed 's/Description: //')
            local install_date=$(date -d @${timestamps[$i]} "+%Y-%m-%d %H:%M")
            sorted_packages+=("${packages[$i]}|${install_date}|${pkg_desc:0:40}")
        fi
    done
    
    # Output the sorted packages
    printf '%s\n' "${sorted_packages[@]}"
}

# Function to display and manage packages
manage_packages() {
    local packages=("$@")
    local total=${#packages[@]}
    local page=0
    local per_page=10
    local total_pages=$(( (total + per_page - 1) / per_page ))
    
    local filter=""
    
    while true; do
        clear
        echo -e "${BLUE}📦 Package Installation History and Uninstaller${RESET}"
        echo "---------------------------------------------------------"
        
        if [[ -n "$filter" ]]; then
            echo -e "${YELLOW}Filtering by: ${filter}${RESET}"
        fi
        
        echo -e "${CYAN}Page $(( page + 1 ))/$total_pages${RESET} (${total} packages total)"
        echo ""
        
        # Calculate range for current page
        local start=$((page * per_page))
        local end=$(( start + per_page - 1 ))
        [[ $end -ge $total ]] && end=$(( total - 1 ))
        
        # Display packages with numbers
        for i in $(seq $start $end); do
            local pkg="${packages[$i]}"
            local name=$(echo "$pkg" | cut -d'|' -f1)
            local date=$(echo "$pkg" | cut -d'|' -f2)
            local desc=$(echo "$pkg" | cut -d'|' -f3)
            
            echo -e "${GREEN}$(( i - start + 1 )).${RESET} ${CYAN}${name}${RESET}"
            echo "   ${YELLOW}Installed:${RESET} ${date}"
            echo "   ${desc}"
            echo ""
        done
        
        echo "---------------------------------------------------------"
        echo -e "${YELLOW}Commands:${RESET}"
        echo "• Enter number to uninstall a package"
        echo "• n: Next page | p: Previous page"
        echo "• s: Search packages | r: Reset search"
        echo "• i: Show more info about a package"
        echo "• q: Quit"
        
        read -p "> " choice
        
        case "$choice" in
            [0-9]*)
                local index=$((start + choice - 1))
                if [ $index -ge $start ] && [ $index -le $end ]; then
                    local pkg=$(echo "${packages[$index]}" | cut -d'|' -f1)
                    uninstall_package "$pkg"
                    # Refresh packages list after uninstall
                    if [[ $? -eq 0 ]]; then
                        packages=()
                        while IFS= read -r line; do
                            packages+=("$line")
                        done < <(get_packages_by_date)
                        total=${#packages[@]}
                        total_pages=$(( (total + per_page - 1) / per_page ))
                        [[ $page -ge $total_pages ]] && page=$((total_pages - 1))
                    fi
                else
                    echo -e "${RED}Invalid selection${RESET}"
                    read -p "Press Enter to continue..." dummy
                fi
                ;;
            n|N)
                if [[ $page -lt $((total_pages - 1)) ]]; then
                    ((page++))
                else
                    echo -e "${YELLOW}Already on the last page${RESET}"
                    read -p "Press Enter to continue..." dummy
                fi
                ;;
            p|P)
                if [[ $page -gt 0 ]]; then
                    ((page--))
                else
                    echo -e "${YELLOW}Already on the first page${RESET}"
                    read -p "Press Enter to continue..." dummy
                fi
                ;;
            s|S)
                read -p "Enter search term: " filter
                
                # Filter the packages array based on the search term
                local filtered_packages=()
                for pkg in "${packages[@]}"; do
                    if echo "$pkg" | grep -qi "$filter"; then
                        filtered_packages+=("$pkg")
                    fi
                done
                
                if [[ ${#filtered_packages[@]} -eq 0 ]]; then
                    echo -e "${RED}No packages match your search term${RESET}"
                    read -p "Press Enter to continue..." dummy
                    filter=""
                else
                    packages=("${filtered_packages[@]}")
                    total=${#packages[@]}
                    total_pages=$(( (total + per_page - 1) / per_page ))
                    page=0
                fi
                ;;
            r|R)
                echo -e "${YELLOW}Refreshing package list...${RESET}"
                packages=()
                while IFS= read -r line; do
                    packages+=("$line")
                done < <(get_packages_by_date)
                total=${#packages[@]}
                total_pages=$(( (total + per_page - 1) / per_page ))
                page=0
                filter=""
                ;;
            i|I)
                read -p "Enter package number for more info: " pkg_num
                local index=$((start + pkg_num - 1))
                if [ $index -ge $start ] && [ $index -le $end ]; then
                    local pkg=$(echo "${packages[$index]}" | cut -d'|' -f1)
                    clear
                    echo -e "${BLUE}Package Information: ${CYAN}$pkg${RESET}\n"
                    apt-cache show "$pkg" | less
                else
                    echo -e "${RED}Invalid selection${RESET}"
                    read -p "Press Enter to continue..." dummy
                fi
                ;;
            q|Q)
                return 0
                ;;
            *)
                echo -e "${RED}Invalid option${RESET}"
                read -p "Press Enter to continue..." dummy
                ;;
        esac
    done
}

# Function to uninstall a package
uninstall_package() {
    local pkg=$1
    echo -e "${YELLOW}About to uninstall: ${CYAN}$pkg${RESET}"
    echo -e "${RED}Warning: This may remove other dependent packages as well!${RESET}"
    read -p "Are you sure? (y/N): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Uninstalling $pkg...${RESET}"
        sudo apt-get remove "$pkg"
        
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}Package $pkg successfully uninstalled${RESET}"
            read -p "Would you like to autoremove unused dependencies? (y/N): " auto_confirm
            if [[ "$auto_confirm" =~ ^[Yy]$ ]]; then
                sudo apt-get autoremove -y
            fi
            return 0
        else
            echo -e "${RED}Failed to uninstall $pkg${RESET}"
            read -p "Press Enter to continue..." dummy
            return 1
        fi
    else
        echo -e "${YELLOW}Uninstall cancelled${RESET}"
        read -p "Press Enter to continue..." dummy
        return 1
    fi
}

# Check if running as root and display warning
check_root() {
    if [ "$(id -u)" -eq 0 ]; then
        echo -e "${RED}Warning: You are running this script as root.${RESET}"
        echo -e "${YELLOW}It's recommended to run as a regular user with sudo privileges.${RESET}"
        read -p "Continue anyway? (y/N): " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "Exiting..."
            exit 0
        fi
    fi
}

# Main function
main() {
    clear
    echo -e "${BLUE}=== Package Installation History and Uninstaller ===${RESET}"
    echo -e "${YELLOW}This tool shows your installed packages sorted by installation date${RESET}"
    echo -e "${YELLOW}and allows you to uninstall them.${RESET}"
    echo ""
    
    check_requirements
    check_root
    
    echo -e "${GREEN}Loading package history...${RESET}"
    
    # Get packages sorted by installation date
    local packages=()
    while IFS= read -r line; do
        packages+=("$line")
    done < <(get_packages_by_date)
    
    if [[ ${#packages[@]} -eq 0 ]]; then
        echo -e "${RED}No package information found${RESET}"
        exit 1
    fi
    
    # Display packages and handle user interaction
    manage_packages "${packages[@]}"
    
    echo -e "${GREEN}Thanks for using Package History and Uninstaller!${RESET}"
}

# Run the main function
main