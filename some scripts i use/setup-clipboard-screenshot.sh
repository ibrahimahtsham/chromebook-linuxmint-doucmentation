#!/bin/bash

# Colors for better readability
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
BLUE="\e[34m"
RESET="\e[0m"

echo -e "${BLUE}=== Windows-like Clipboard and Screenshot Setup ===${RESET}"
echo "This script will:"
echo "1. Install CopyQ clipboard manager (similar to Win+V in Windows 10)"
echo "2. Configure Win+V to open CopyQ clipboard history"
echo "3. Configure Win+Shift+S for screenshot selection tool"
echo ""

# Check if running as root
if [ "$(id -u)" -eq 0 ]; then
    echo -e "${RED}Please don't run this script as root/sudo.${RESET}"
    echo "It will prompt for elevation when needed."
    exit 1
fi

# Function to install CopyQ
install_copyq() {
    echo -e "${YELLOW}Installing CopyQ clipboard manager...${RESET}"
    
    # Check if CopyQ is already installed
    if command -v copyq &> /dev/null; then
        echo -e "${GREEN}CopyQ is already installed!${RESET}"
    else
        echo "Installing CopyQ..."
        sudo apt update
        sudo apt install -y copyq
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}CopyQ installed successfully!${RESET}"
        else
            echo -e "${RED}Failed to install CopyQ.${RESET}"
            exit 1
        fi
    fi
}

# Function to set up clipboard shortcut (Win+V)
setup_clipboard_shortcut() {
    echo -e "${YELLOW}Setting up Win+V clipboard shortcut...${RESET}"
    
    # Start CopyQ if not running
    pgrep copyq &> /dev/null || copyq &

    # Create custom command to show clipboard
    mkdir -p ~/.config/copyq
    
    # Add the show clipboard command to CopyQ configuration
    cat > ~/.config/copyq/copyq-show-clipboard.ini << EOL
[Commands]
1\Command=copyq: toggle()
1\GlobalShortcut=meta+v
1\Icon=\xf0ea
1\IsGlobalShortcut=true
1\Name=Show/hide main window
size=1
EOL

    echo -e "${GREEN}Win+V shortcut has been set up to toggle CopyQ clipboard history!${RESET}"
    echo "You may need to log out and log back in for the shortcut to take effect."
}

# Function to set up screenshot shortcut (Win+Shift+S)
setup_screenshot_shortcut() {
    echo -e "${YELLOW}Setting up Win+Shift+S screenshot shortcut...${RESET}"
    
    # Determine which screenshot tool is available
    SCREENSHOT_CMD=""
    
    if command -v gnome-screenshot &> /dev/null; then
        SCREENSHOT_CMD="gnome-screenshot -a"  # Area selection mode
    elif command -v cinnamon-screenshot &> /dev/null; then
        SCREENSHOT_CMD="cinnamon-screenshot -a"  # Area selection mode
    else
        echo -e "${YELLOW}Installing screenshot tool...${RESET}"
        sudo apt update
        sudo apt install -y gnome-screenshot
        SCREENSHOT_CMD="gnome-screenshot -a"
    fi
    
    # Use gsettings to set keyboard shortcut for Cinnamon
    echo "Setting up custom keybinding for screenshots..."
    
    # Get a list of existing custom keybindings
    KEYBINDINGS=$(gsettings get org.cinnamon.desktop.keybindings custom-list)
    
    # Remove brackets and split by comma
    KEYBINDINGS="${KEYBINDINGS//[/}"
    KEYBINDINGS="${KEYBINDINGS//]/}"
    
    # If the list is empty, start with custom0
    if [[ "$KEYBINDINGS" == "" ]]; then
        NEW_BINDING="['custom0']"
        CUSTOM_NUM="custom0"
    else
        # Find the next available custom slot
        LAST_NUM=$(echo $KEYBINDINGS | tr "," "\n" | grep -o "[0-9]*" | sort -n | tail -1)
        NEXT_NUM=$((LAST_NUM + 1))
        CUSTOM_NUM="custom$NEXT_NUM"
        NEW_BINDING="${KEYBINDINGS}, 'custom$NEXT_NUM'"
        NEW_BINDING="[${NEW_BINDING}]"
    fi
    
    # Update the keybinding list
    gsettings set org.cinnamon.desktop.keybindings custom-list "$NEW_BINDING"
    
    # Set the command for the new keybinding
    gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/${CUSTOM_NUM}/ command "$SCREENSHOT_CMD"
    
    # Set the name for the new keybinding
    gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/${CUSTOM_NUM}/ name "Area screenshot"
    
    # Set the binding for the new keybinding (Super+Shift+S)
    gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/${CUSTOM_NUM}/ binding "['<Super>shift_L s']"
    
    echo -e "${GREEN}Win+Shift+S shortcut has been set up for area screenshot!${RESET}"
}

# Main execution
install_copyq
setup_clipboard_shortcut
setup_screenshot_shortcut

echo ""
echo -e "${GREEN}Setup completed!${RESET}"
echo -e "${YELLOW}Instructions:${RESET}"
echo "1. Press Win+V to show/hide clipboard history"
echo "2. Press Win+Shift+S to capture a screenshot of selected area"
echo "3. CopyQ will start automatically on login"
echo ""
echo "Note: You might need to log out and log back in for all settings to take effect."

# Setup CopyQ to start at login
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/copyq.desktop << EOL
[Desktop Entry]
Name=CopyQ
GenericName=Clipboard Manager
Comment=Advanced clipboard manager with editing and scripting features
Icon=copyq
Exec=copyq
Terminal=false
Type=Application
Categories=Qt;Utility;
Keywords=clipboard;copy;paste;history;
StartupNotify=false
X-GNOME-Autostart-enabled=true
EOL

echo "Done! CopyQ has been added to startup applications."