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

# Function to properly configure CopyQ
configure_copyq() {
    echo -e "${YELLOW}Configuring CopyQ clipboard manager...${RESET}"
    
    # Kill any existing CopyQ process
    pkill copyq 2>/dev/null
    sleep 1
    
    # Create the config directory if it doesn't exist
    mkdir -p ~/.config/copyq
    
    # Configure CopyQ with Win+V shortcut using the main configuration file
    cat > ~/.config/copyq/copyq.conf << EOL
[General]
plugin_priority=itemimage, itemencrypted, itemfakevim, itemnotes, itempinned, itemsync, itemtags, itemtext

[Options]
activate_closes=true
activate_focuses=true
activate_item_with_single_click=false
activate_pastes=true
always_on_top=false
autostart=true
check_clipboard=true
check_selection=false
clipboard_notification_lines=0
clipboard_tab=&clipboard
close_on_unfocus=true
command_history_size=100
confirm_exit=true
copy_clipboard=false
copy_selection=false
disable_tray=false
edit_ctrl_return=true
editor=gedit %1
expire_tab=0
hide_main_window=false
hide_tabs=false
hide_toolbar=false
hide_toolbar_labels=true
item_popup_interval=0
language=en
max_process_manager_rows=1000
maxitems=200
move=true
notification_horizontal_offset=10
notification_maximum_height=100
notification_maximum_width=300
notification_position=3
notification_vertical_offset=10
number_search=false
row_index_from_one=true
run_selection=true
save_filter_history=false
show_advanced_command_settings=false
show_simple_items=false
show_tab_item_count=false
tab_tree=false
tabs=&clipboard
text_tab_width=8
text_wrap=true
transparency=0
transparency_focused=0
tray_commands=true
tray_images=true
tray_item_paste=true
tray_items=5
tray_tab=
tray_tab_is_current=true
vi=false

[Shortcuts]
about=
change_tab_icon=ctrl+shift+t
commands=f6
copy_selected_items=ctrl+c
delete_item=del
edit=f2
edit_notes=shift+f2
editor=ctrl+e
exit=ctrl+q
export=ctrl+s
find_items=f3
help=f1
import=ctrl+i
item-menu=shift+f10
move_down=ctrl+down
move_to_bottom=ctrl+end
move_to_clipboard=
move_to_top=ctrl+home
move_up=ctrl+up
new=ctrl+n
new_tab=ctrl+t
next_tab=right
paste_selected_items=ctrl+v
preferences=ctrl+p
previous_tab=left
process_manager=ctrl+shift+z
remove_tab=ctrl+w
rename_tab=ctrl+f2
reverse_selected_items=ctrl+shift+r
show-log=f12
show_clipboard_content=ctrl+shift+c
show_item_content=f4
show_item_preview=f7
sort_selected_items=ctrl+shift+s
system-run=f5
toggle_clipboard_storing=ctrl+shift+x

[Tabs]
1\icon=
1\max_item_count=0
1\name=&clipboard
1\store_items=true
size=1

[Theme]
alt_bg=#f8f8f8
alt_item_css=
bg=#ffffff
css=
css_template_items=items
css_template_main_window=main_window
css_template_notification=notification
css_template_tooltip=tooltip
cur_item_css="\n    ;border: 0.1em solid ${sel_bg}"
edit_bg=#ffffff
edit_fg=#000000
edit_font=
fg=#000000
find_bg=#ff0
find_fg=#000
find_font=
font=
font_antialiasing=true
hover_item_css=
icon_size=16
item_css=
item_spacing=
menu_bar_css="\n    ;background: ${bg}\n    ;color: ${fg}"
menu_bar_disabled_css="\n    ;color: ${bg - #666}"
menu_bar_selected_css="\n    ;background: ${sel_bg}\n    ;color: ${sel_fg}"
menu_css="\n    ;border: 1px solid ${sel_bg}\n    ;background: ${bg}\n    ;color: ${fg}"
notes_bg=#ffffdc
notes_css=
notes_fg=#000000
notes_font=
notification_bg=#333
notification_fg=#ddd
notification_font=
num_fg=#000000
num_font=
search_bar="\n    ;background: ${edit_bg}\n    ;color: ${edit_fg}\n    ;border: 1px solid ${alt_bg}\n    ;margin: 2px"
search_bar_focused="\n    ;border: 1px solid ${sel_bg}"
sel_bg=#308cc6
sel_fg=#ffffff
sel_item_css=
show_number=true
show_scrollbars=true
style_main_window=false
tab_bar_css="\n    ;background: ${bg - #222}"
tab_bar_item_counter="\n    ;color: ${fg - #044 + #400}\n    ;font-size: 6pt"
tab_bar_scroll_buttons_css="\n    ;background: ${bg - #222}\n    ;color: ${fg}\n    ;border: 0"
tab_bar_sel_item_counter="\n    ;color: ${sel_bg - #044 + #400}"
tab_bar_tab_selected_css="\n    ;padding: 0.5em\n    ;background: ${bg}\n    ;border: 0.05em solid ${bg}\n    ;color: ${fg}"
tab_bar_tab_unselected_css="\n    ;border: 0.05em solid ${bg}\n    ;padding: 0.5em\n    ;background: ${bg - #222}\n    ;color: ${fg - #333}"
tab_tree_css="\n    ;color: ${fg}\n    ;background-color: ${bg}"
tab_tree_item_counter="\n    ;color: ${fg - #044 + #400}\n    ;font-size: 6pt"
tab_tree_sel_item_counter="\n    ;color: ${sel_fg - #044 + #400}"
tab_tree_sel_item_css="\n    ;color: ${sel_fg}\n    ;background-color: ${sel_bg}\n    ;border-radius: 2px"
tool_bar_css="\n    ;color: ${fg}\n    ;background-color: ${bg}\n    ;border: 0"
tool_button_css="\n    ;color: ${fg}\n    ;background: ${bg}\n    ;border: 0\n    ;border-radius: 2px"
tool_button_pressed_css="\n    ;background: ${sel_bg}"
tool_button_selected_css="\n    ;background: ${sel_bg - #222}\n    ;color: ${sel_fg}\n    ;border: 1px solid ${sel_bg}"
use_system_icons=false

[Commands]
1\Command=copyq: toggle()
1\GlobalShortcut=meta+v
1\Icon=\xf01c
1\IsGlobalShortcut=true
1\Name=Show/hide main window
size=1
EOL

    # Start CopyQ
    nohup copyq >/dev/null 2>&1 &
    sleep 2
    
    # Verify CopyQ is running
    if ! pgrep -x copyq >/dev/null; then
        echo -e "${RED}Failed to start CopyQ.${RESET}"
        echo -e "${YELLOW}Attempting to restart CopyQ...${RESET}"
        nohup copyq >/dev/null 2>&1 &
        sleep 2
        
        if ! pgrep -x copyq >/dev/null; then
            echo -e "${RED}Unable to start CopyQ. Please check your installation.${RESET}"
        else
            echo -e "${GREEN}CopyQ has been started.${RESET}"
        fi
    else
        echo -e "${GREEN}CopyQ is running.${RESET}"
    fi
    
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
    
    echo -e "${GREEN}CopyQ has been configured to start automatically on login.${RESET}"
}

# Function to check if a shortcut exists and is already assigned
check_shortcut_conflict() {
    local shortcut=$1
    local command=$2
    local check=$(gsettings list-recursively | grep -i "$shortcut" || true)
    
    if [[ -n "$check" ]]; then
        echo -e "${YELLOW}Warning: Shortcut $shortcut is already assigned:${RESET}"
        echo -e "$check"
        read -p "Do you want to override this shortcut? [Y/n]: " override
        if [[ "$override" =~ ^[Nn]$ ]]; then
            echo -e "${YELLOW}Skipping shortcut assignment.${RESET}"
            return 1
        fi
    fi
    return 0
}

# Function to set up screenshot shortcut (Win+Shift+S)
setup_screenshot_shortcut() {
    echo -e "${YELLOW}Setting up Win+Shift+S screenshot shortcut...${RESET}"
    
    # Check for conflicts
    if ! check_shortcut_conflict "<Super>shift_L s" "screenshot"; then
        return
    fi
    
    # Determine which screenshot tool is available
    SCREENSHOT_CMD=""
    
    if command -v gnome-screenshot &> /dev/null; then
        SCREENSHOT_CMD="gnome-screenshot -a"  # Area selection mode
    elif command -v cinnamon-screenshot &> /dev/null; then
        SCREENSHOT_CMD="cinnamon-screenshot -a"  # Area selection mode
    elif command -v spectacle &> /dev/null; then
        SCREENSHOT_CMD="spectacle -r"  # Region mode for KDE
    else
        echo -e "${YELLOW}Installing screenshot tool...${RESET}"
        sudo apt update
        sudo apt install -y gnome-screenshot
        SCREENSHOT_CMD="gnome-screenshot -a"
    fi
    
    # Try multiple approaches for better compatibility
    
    # Approach 1: Direct dconf write (more reliable in some cases)
    echo "Configuring shortcut using dconf..."
    
    # Get a list of existing custom keybindings
    KEYBINDINGS=$(gsettings get org.cinnamon.desktop.keybindings custom-list 2>/dev/null || echo "[]")
    
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
    
    # Use different approaches based on desktop environment
    if gsettings list-schemas | grep -q "org.cinnamon.desktop.keybindings"; then
        # Cinnamon desktop environment
        echo "Detected Cinnamon desktop. Configuring shortcut..."
        
        # Update the keybinding list
        gsettings set org.cinnamon.desktop.keybindings custom-list "$NEW_BINDING"
        
        # Set the command for the new keybinding
        gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/${CUSTOM_NUM}/ command "$SCREENSHOT_CMD"
        
        # Set the name for the new keybinding
        gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/${CUSTOM_NUM}/ name "Area screenshot"
        
        # Set the binding for the new keybinding (Super+Shift+S)
        gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/${CUSTOM_NUM}/ binding "['<Super>shift_L s']"
    elif gsettings list-schemas | grep -q "org.gnome.settings-daemon.plugins.media-keys"; then
        # GNOME desktop environment
        echo "Detected GNOME desktop. Configuring shortcut..."
        
        # For GNOME, use custom-keybindings
        CURRENT_KEYS=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
        CUSTOM_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom-screenshot/"
        
        # Format as an array
        if [[ "$CURRENT_KEYS" == "@as []" || "$CURRENT_KEYS" == "[]" ]]; then
            NEW_KEYS="['$CUSTOM_PATH']"
        else
            # Remove brackets and add new path
            CURRENT_KEYS="${CURRENT_KEYS%]}"
            CURRENT_KEYS="${CURRENT_KEYS#[}"
            NEW_KEYS="[$CURRENT_KEYS, '$CUSTOM_PATH']"
        fi
        
        # Set the list of custom keybindings
        gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$NEW_KEYS"
        
        # Configure the custom keybinding
        gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$CUSTOM_PATH name "Area screenshot"
        gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$CUSTOM_PATH command "$SCREENSHOT_CMD"
        gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$CUSTOM_PATH binding "<Super>shift_L s"
    else
        # Fallback: Create custom shortcut using xbindkeys
        echo "Using xbindkeys as fallback method..."
        sudo apt-get install -y xbindkeys
        mkdir -p ~/.config/
        echo "\"$SCREENSHOT_CMD\"" > ~/.xbindkeysrc
        echo "  Mod4 + shift + s" >> ~/.xbindkeysrc
        
        # Kill and restart xbindkeys
        pkill xbindkeys || true
        xbindkeys &
        
        # Add xbindkeys to startup
        mkdir -p ~/.config/autostart/
        cat > ~/.config/autostart/xbindkeys.desktop << EOL
[Desktop Entry]
Name=xbindkeys
GenericName=Shortcut Manager
Comment=Launch commands with keyboard shortcuts
Exec=xbindkeys
Terminal=false
Type=Application
X-GNOME-Autostart-enabled=true
EOL
    fi
    
    echo -e "${GREEN}Win+Shift+S shortcut has been set up for area screenshot!${RESET}"
    echo -e "${YELLOW}You may need to log out and log back in for this shortcut to work properly.${RESET}"
}

# Function to verify shortcut setup
verify_shortcuts() {
    echo -e "${YELLOW}Verifying shortcuts...${RESET}"
    
    # Verify CopyQ is running 
    if ! pgrep -x copyq >/dev/null; then
        echo -e "${RED}CopyQ is not running. Try starting it manually with 'copyq'${RESET}"
        needs_restart=true
    else
        echo -e "${GREEN}✓ CopyQ is running${RESET}"
    fi
    
    # Check if the Win+V shortcut is configured in CopyQ
    if grep -q "GlobalShortcut=meta+v" ~/.config/copyq/copyq.conf 2>/dev/null; then
        echo -e "${GREEN}✓ Win+V shortcut is configured${RESET}"
    else
        echo -e "${RED}Win+V shortcut configuration not found${RESET}"
        needs_restart=true
    fi
    
    # Check for screenshot shortcut in various configurations
    if gsettings list-recursively | grep -q -i "'<Super>shift_L s'" || 
       grep -q "Mod4 + shift + s" ~/.xbindkeysrc 2>/dev/null; then
        echo -e "${GREEN}✓ Win+Shift+S shortcut is configured${RESET}"
    else
        echo -e "${RED}Win+Shift+S shortcut configuration not found${RESET}"
        needs_restart=true
    fi
    
    if [[ "$needs_restart" == true ]]; then
        echo -e "${YELLOW}Some settings may require a session restart to take effect.${RESET}"
        read -p "Do you want to log out now to apply all changes? [y/N]: " restart
        if [[ "$restart" =~ ^[Yy]$ ]]; then
            echo -e "${GREEN}Logging out in 5 seconds...${RESET}"
            sleep 5
            # Different desktop environments use different commands for logout
            gnome-session-quit --logout --no-prompt 2>/dev/null || \
            cinnamon-session-quit --logout --no-prompt 2>/dev/null || \
            pkill -15 -t tty"$XDG_VTNR" Xorg 2>/dev/null || \
            loginctl terminate-session ${XDG_SESSION_ID-} 2>/dev/null || \
            kill -9 -1 2>/dev/null
        fi
    fi
}

# Main execution
install_copyq
configure_copyq
setup_screenshot_shortcut
verify_shortcuts

echo ""
echo -e "${GREEN}Setup completed!${RESET}"
echo -e "${YELLOW}Instructions:${RESET}"
echo "1. Press Win+V to show/hide clipboard history"
echo "2. Press Win+Shift+S to capture a screenshot of selected area"
echo "3. CopyQ will start automatically on login"
echo ""
echo -e "${GREEN}If shortcuts don't work after logging back in, you may need to manually${RESET}"
echo -e "${GREEN}configure them in your system's keyboard settings.${RESET}"