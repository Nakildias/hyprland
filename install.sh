#!/bin/bash

# Hyprland Automatic Setup Script for Arch Linux

# This script automates the installation and configuration of Hyprland
# with various user-selectable options and pre-defined settings.

# --- Configuration Variables (DO NOT MODIFY MANUALLY, SET VIA SCRIPT) ---
ACCENT_COLOR=""
GAP_SIZE=""
WAYBAR_POSITION=""
MONITOR_RESOLUTION=""
MONITOR_REFRESH_RATE=""
ENABLE_BATTERY_WAYBAR="false"
# -----------------------------------------------------------------------

# Define colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Helper Functions ---

# Function to display a message box (instead of alert)
show_message() {
    local title="$1"
    local message="$2"
    echo -e "${BLUE}--- $title ---${NC}"
    echo -e "${GREEN}$message${NC}"
    echo -e "${BLUE}-----------------${NC}"
    read -rp "Press Enter to continue..."
}

# Check if running on Arch Linux
check_arch_linux() {
    if [[ -f /etc/arch-release ]]; then
        echo -e "${GREEN}Detected Arch Linux. Proceeding with setup.${NC}"
    else
        echo -e "${RED}Error: This script is intended for Arch Linux only.${NC}"
        show_message "OS Mismatch" "This script is designed for Arch Linux. Exiting."
        exit 1
    fi
}

# Check for AUR helper (yay or paru) and install if not found
install_aur_helper() {
    if ! command -v yay &> /dev/null && ! command -v paru &> /dev/null; then
        echo -e "${YELLOW}AUR helper (yay or paru) not found. Installing yay...${NC}"
        sudo pacman -S --noconfirm base-devel git
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        (cd /tmp/yay && makepkg -si --noconfirm)
        rm -rf /tmp/yay
        if ! command -v yay &> /dev/null; then
            echo -e "${RED}Failed to install yay. Please install yay or paru manually and rerun the script.${NC}"
            show_message "AUR Helper Missing" "Failed to install yay. Please install an AUR helper manually."
            exit 1
        fi
    else
        echo -e "${GREEN}AUR helper (yay or paru) found.${NC}"
    fi
}

# Automatic Package Installation for Arch Linux
install_packages() {
    echo -e "${BLUE}--- Installing necessary packages ---${NC}"

    local packages=(
        hyprland
        waybar
        rofi
        kitty # Terminal
        btop # System monitor
        wlogout # Logout utility
        grim # Screenshot tool
        slurp # Screenshot selection tool
        wl-clipboard # Wayland clipboard
        xdg-utils # For opening browser/file explorer
        polkit-kde-agent # Polkit authentication agent (can also use polkit-gnome)
        pipewire # Audio server
        wireplumber # Session manager for PipeWire
        brightnessctl # Screen brightness control
        pavucontrol # Volume control
        networkmanager # Network management
        seatd # For autostarting Hyprland
        git # For cloning AUR packages
        qt5ct # QT5 configuration tool
        lxappearance # GTK theme configuration
        # Fonts (optional but recommended for a complete setup)
        noto-fonts
        noto-fonts-cjk
        noto-fonts-emoji
        ttf-jetbrains-mono-nerd # Nerd Font for icons
    )

    local aur_packages=(
        full-dracula-theme-git # Dracula theme for GTK/QT
        # Add any other AUR packages if needed, e.g., hyprland-git, waybar-git for latest
    )

    echo -e "${YELLOW}Updating pacman database...${NC}"
    sudo pacman -Syu --noconfirm

    echo -e "${YELLOW}Installing core packages...${NC}"
    sudo pacman -S --noconfirm "${packages[@]}"

    install_aur_helper

    local aur_cmd=""
    if command -v yay &> /dev/null; then
        aur_cmd="yay"
    elif command -v paru &> /dev/null; then
        aur_cmd="paru"
    fi

    if [[ -n "$aur_cmd" ]]; then
        echo -e "${YELLOW}Installing AUR packages using $aur_cmd...${NC}"
        "$aur_cmd" -S --noconfirm "${aur_packages[@]}"
    else
        echo -e "${RED}No AUR helper found. Skipping AUR package installation. Please install 'full-dracula-theme-git' manually.${NC}"
        show_message "AUR Packages Skipped" "Please install 'full-dracula-theme-git' manually if you wish to use the theme."
    fi

    echo -e "${GREEN}Package installation complete.${NC}"
}

# --- User Option Functions ---

ask_accent_color() {
    echo -e "${BLUE}--- Choose your Accent Color ---${NC}"
    echo "1) Dracula Orchid (#9766BF)"
    echo "2) Dracula Pink (#FF79C6)"
    echo "3) Dracula Cyan (#8BE9FD)"
    echo "4) Dracula Green (#50FA7B)"
    echo "5) Dracula Yellow (#F1FA8C)"
    echo "6) Dracula Orange (#FFB86C)"
    echo "7) Dracula Red (#FF5555)"
    echo "8) Dracula Purple (#BD93F9)"
    echo "9) Dracula Blue (#6272A4)"
    echo "10) Custom (Enter Hex Code, e.g., #RRGGBB)"
    read -rp "Enter your choice (1-10): " choice

    case "$choice" in
        1) ACCENT_COLOR="#9766BF";;
        2) ACCENT_COLOR="#FF79C6";;
        3) ACCENT_COLOR="#8BE9FD";;
        4) ACCENT_COLOR="#50FA7B";;
        5) ACCENT_COLOR="#F1FA8C";;
        6) ACCENT_COLOR="#FFB86C";;
        7) ACCENT_COLOR="#FF5555";;
        8) ACCENT_COLOR="#BD93F9";;
        9) ACCENT_COLOR="#6272A4";;
        10)
            read -rp "Enter custom hex color (e.g., #RRGGBB): " custom_color
            if [[ "$custom_color" =~ ^#([0-9A-Fa-f]{6})$ ]]; then
                ACCENT_COLOR="$custom_color"
            else
                echo -e "${RED}Invalid hex color. Using default Dracula Orchid.${NC}"
                ACCENT_COLOR="#9766BF"
            fi
            ;;
        *)
            echo -e "${RED}Invalid choice. Using default Dracula Orchid.${NC}"
            ACCENT_COLOR="#9766BF"
            ;;
    esac
    echo -e "${GREEN}Accent Color set to: $ACCENT_COLOR${NC}"
}

ask_gap_size() {
    echo -e "${BLUE}--- Choose Gap Size ---${NC}"
    echo "1) Small (5px)"
    echo "2) Medium (10px)"
    echo "3) Large (15px)"
    echo "4) Custom (Enter pixel value)"
    read -rp "Enter your choice (1-4): " choice

    case "$choice" in
        1) GAP_SIZE="5";;
        2) GAP_SIZE="10";;
        3) GAP_SIZE="15";;
        4)
            read -rp "Enter custom gap size (pixels, e.g., 8): " custom_gap
            if [[ "$custom_gap" =~ ^[0-9]+$ ]]; then
                GAP_SIZE="$custom_gap"
            else
                echo -e "${RED}Invalid input. Using default Medium (10px).${NC}"
                GAP_SIZE="10"
            fi
            ;;
        *)
            echo -e "${RED}Invalid choice. Using default Medium (10px).${NC}"
            GAP_SIZE="10"
            ;;
    esac
    echo -e "${GREEN}Gap Size set to: ${GAP_SIZE}px${NC}"
}

ask_waybar_position() {
    echo -e "${BLUE}--- Waybar Position ---${NC}"
    echo "1) Top"
    echo "2) Bottom"
    read -rp "Enter your choice (1-2): " choice

    case "$choice" in
        1) WAYBAR_POSITION="top";;
        2) WAYBAR_POSITION="bottom";;
        *)
            echo -e "${RED}Invalid choice. Using default Top.${NC}"
            WAYBAR_POSITION="top"
            ;;
    esac
    echo -e "${GREEN}Waybar will be positioned at the: ${WAYBAR_POSITION}${NC}"
}

ask_resolution() {
    echo -e "${BLUE}--- Monitor Resolution and Refresh Rate ---${NC}"
    echo -e "${YELLOW}This option is for single monitor setups. If you have multiple monitors, you'll need to adjust hyprland.conf manually.${NC}"
    read -rp "Enter your monitor resolution (e.g., 1920x1080): " res
    read -rp "Enter your monitor refresh rate (e.g., 144): " hz

    if [[ "$res" =~ ^[0-9]+x[0-9]+$ && "$hz" =~ ^[0-9]+$ ]]; then
        MONITOR_RESOLUTION="$res"
        MONITOR_REFRESH_RATE="$hz"
        echo -e "${GREEN}Resolution set to ${MONITOR_RESOLUTION}@${MONITOR_REFRESH_RATE}Hz.${NC}"
    else
        echo -e "${RED}Invalid input. Skipping resolution setup. You will need to configure it manually in hyprland.conf.${NC}"
        MONITOR_RESOLUTION=""
        MONITOR_REFRESH_RATE=""
    fi
}

ask_battery_waybar() {
    echo -e "${BLUE}--- Enable Battery in Waybar? ---${NC}"
    read -rp "Do you want to enable battery status in Waybar for laptops? (y/N): " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        ENABLE_BATTERY_WAYBAR="true"
        echo -e "${GREEN}Battery status will be shown in Waybar.${NC}"
    else
        ENABLE_BATTERY_WAYBAR="false"
        echo -e "${YELLOW}Battery status will not be shown in Waybar.${NC}"
    fi
}

# --- Configuration Generation Functions ---

generate_hyprland_conf() {
    echo -e "${BLUE}--- Generating ~/.config/hypr/hyprland.conf ---${NC}"
    mkdir -p ~/.config/hypr

    local monitor_config=""
    if [[ -n "$MONITOR_RESOLUTION" && -n "$MONITOR_REFRESH_RATE" ]]; then
        monitor_config="monitor=,${MONITOR_RESOLUTION},auto,${MONITOR_REFRESH_RATE}"
    else
        monitor_config="# monitor=,preferred,auto,1 # Uncomment and adjust for your monitor"
    fi

    cat << EOF > ~/.config/hypr/hyprland.conf
# This is a Hyprland configuration file generated by the setup script.
# For more information, see the Hyprland Wiki: https://wiki.hyprland.org/

# --- General Settings ---
\$mainMod = SUPER # Set your main modifier key (Windows key)

\$terminal = kitty # Default terminal
\$fileManager = thunar # Default file manager (install thunar or change this)
\$browser = firefox # Default web browser (install firefox or change this)
\$musicApp = spotify # Default music streaming app (install spotify or change this)
\$calculator = galculator # Default calculator (install galculator or change this)
\$steam = steam # Default Steam client (install steam or change this)
\$discord = discord # Default Discord client (install discord or change this)

# Source other config files
source=~/.config/hypr/keybindings.conf
source=~/.config/hypr/windowrules.conf
source=~/.config/hypr/autostart.conf

# Monitor setup
${monitor_config}

# Execute your favorite apps at launch
exec-once = waybar &
exec-once = hyprpaper &
exec-once = dunst & # Notification daemon
exec-once = nm-applet --indicator & # NetworkManager applet
exec-once = blueman-applet & # Bluetooth applet
exec-once = udiskie & # Automount removable media
exec-once = polkit-kde-authentication-agent-1 & # Polkit agent
exec-once = swayidle -w timeout 300 'wlogout' timeout 600 'systemctl suspend' before-sleep 'wlogout' & # Idle management
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP # For applications to pick up Wayland
exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP # For systemd user services

# --- Input Settings ---
input {
    kb_layout = us
    kb_variant =
    kb_model =
    kb_options =
    kb_rules =

    follow_mouse = 1

    touchpad {
        natural_scroll = no
    }

    sensitivity = 1.0 # 0.0 - 1.0, 0.0 = no sensitivity, 1.0 = raw input
}

# --- Gestures (for touchpads) ---
gestures {
    workspace_swipe = yes
}

# --- General ---
general {
    gaps_in = ${GAP_SIZE}
    gaps_out = ${GAP_SIZE}
    border_size = 2
    col.active_border = rgb(${ACCENT_COLOR//\#/}) # Accent color for active border
    col.inactive_border = rgb(282A36) # Dracula background color

    layout = dwindle
    allow_tearing = false
}

# --- Decoration ---
decoration {
    rounding = 10
    blur {
        enabled = true
        size = 5
        passes = 2
        new_optimizations = true
        xray = true # Blur semi-transparent apps
    }
    drop_shadow = yes
    shadow_range = 40
    shadow_render_power = 0.8
    col.shadow = rgba(1A1A1AEE)
}

# --- Animations ---
animations {
    enabled = yes

    bezier = myBezier, 0.05, 0.9, 0.1, 1.05

    animation = windows, 1, 7, myBezier
    animation = windowsOut, 1, 7, default, popin 80%
    animation = border, 1, 10, default
    animation = borderangle, 1, 8, default
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, default
}

# --- Dwindle Layout ---
dwindle {
    pseudotile = yes # Master switch for pseudotiling. Enabling this will make windows enter pseudotiling mode upon being split.
    preserve_split = yes # You probably want this
}

# --- Master Layout ---
master {
    new_is_master = true
}

# --- Misc ---
misc {
    force_default_wallpaper = -1 # Set to 0 to disable hyprpaper
    vfr = true # Variable Refresh Rate
}

# --- Window Rules ---
# Example: windowrule = float,kitty
# windowrule = float,^(pavucontrol)$
# windowrule = float,^(btop)$
# windowrule = float,^(galculator)$
# windowrule = float,^(Steam)$
# windowrule = float,^(discord)$

# --- Keybindings ---
# Defined in ~/.config/hypr/keybindings.conf
EOF

    # Create keybindings.conf
    cat << EOF > ~/.config/hypr/keybindings.conf
# Keybindings for Hyprland

# See https://wiki.hyprland.org/Configuring/Keybindings/ for more

# Move focus with mainMod + arrow keys
bind = \$mainMod, left, movefocus, l
bind = \$mainMod, right, movefocus, r
bind = \$mainMod, up, movefocus, u
bind = \$mainMod, down, movefocus, d

# Switch workspaces with mainMod + [1-9]
bind = \$mainMod, 1, workspace, 1
bind = \$mainMod, 2, workspace, 2
bind = \$mainMod, 3, workspace, 3
bind = \$mainMod, 4, workspace, 4
bind = \$mainMod, 5, workspace, 5
bind = \$mainMod, 6, workspace, 6
bind = \$mainMod, 7, workspace, 7
bind = \$mainMod, 8, workspace, 8
bind = \$mainMod, 9, workspace, 9
bind = \$mainMod, 0, workspace, 10

# Move active window to a workspace with mainMod + SHIFT + [1-9]
bind = \$mainMod SHIFT, 1, movetoworkspace, 1
bind = \$mainMod SHIFT, 2, movetoworkspace, 2
bind = \$mainMod SHIFT, 3, movetoworkspace, 3
bind = \$mainMod SHIFT, 4, movetoworkspace, 4
bind = \$mainMod SHIFT, 5, movetoworkspace, 5
bind = \$mainMod SHIFT, 6, movetoworkspace, 6
bind = \$mainMod SHIFT, 7, movetoworkspace, 7
bind = \$mainMod SHIFT, 8, movetoworkspace, 8
bind = \$mainMod SHIFT, 9, movetoworkspace, 9
bind = \$mainMod SHIFT, 0, movetoworkspace, 10

# Scroll through existing workspaces with mainMod + scroll
bind = \$mainMod, mouse_down, workspace, e+1
bind = \$mainMod, mouse_up, workspace, e-1

# Move/resize windows with mainMod + LMB/RMB and dragging
bindm = \$mainMod, mouse:272, movewindow
bindm = \$mainMod, mouse:273, resizewindow

# --- Custom Keybindings ---
bind = \$mainMod, D, exec, rofi -show drun -theme ~/.config/rofi/dracula.rasi # Rofi
bind = \$mainMod, RETURN, exec, \$terminal # Terminal
bind = \$mainMod, B, exec, \$browser # Web Browser
bind = \$mainMod, E, exec, \$fileManager # File Explorer
bind = \$mainMod, SPACE, togglefloating, # Toggle focused app floating/tiling
bind = \$mainMod, F, fullscreen, # Toggle fullscreen for focused app
bind = \$mainMod, C, exec, \$calculator # Calculator
bind = \$mainMod, M, exec, wlogout # Quit Hyprland (via wlogout)
bind = \$mainMod, P, exec, \$musicApp # Music Streaming App
bind = \$mainMod, Q, killactive, # Quit focused app
bind = \$mainMod, G, exec, \$steam # Steam
bind = \$mainMod, V, exec, \$discord # Discord
bind = \$mainMod, W, exec, pkill -SIGUSR1 waybar # Toggle Waybar

# Screenshot
bind = \$mainMod SHIFT, S, exec, grim -g "\$(slurp)" - | wl-copy # Screenshot selection
bind = \$mainMod, PRINT, exec, grim - | wl-copy # Screenshot entire screen

# Volume control
bind = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
bind = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bind = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle

# Brightness control
bind = , XF86MonBrightnessUp, exec, brightnessctl set +5%
bind = , XF86MonBrightnessDown, exec, brightnessctl set 5%-

# Lock screen (install swaylock-effects or similar)
bind = \$mainMod, L, exec, swaylock # Example: swaylock or wlr-lock
EOF

    # Create windowrules.conf
    cat << EOF > ~/.config/hypr/windowrules.conf
# Window Rules for Hyprland
# Add specific rules here if needed

windowrule = float,^(pavucontrol)$
windowrule = float,^(btop)$
windowrule = float,^(galculator)$
windowrule = float,^(Steam)$
windowrule = float,^(discord)$
EOF

    # Create autostart.conf
    cat << EOF > ~/.config/hypr/autostart.conf
# Autostart applications and services
# This file is sourced by hyprland.conf

# Set GTK/QT theme
exec-once = lxappearance &
exec-once = qt5ct &

# Set wallpaper (adjust path to your preferred wallpaper)
# exec-once = hyprpaper & # Already in hyprland.conf, but keep for reference
# exec-once = hyprpaper --config ~/.config/hypr/hyprpaper.conf # If you use a separate config for hyprpaper

# Example: Set a default wallpaper
exec-once = hyprpaper &
exec-once = sleep 1 && hyprctl hyprpaper wallpaper "DP-1,~/Pictures/wallpapers/dracula-wallpaper.jpg" # Adjust DP-1 and path

# If you want to set a random wallpaper from a directory
# exec-once = hyprpaper &
# exec-once = sleep 1 && hyprctl hyprpaper preload all
# exec-once = sleep 2 && hyprctl hyprpaper wallpaper "DP-1,random"
# exec-once = sleep 3 && hyprctl hyprpaper wallpaper "HDMI-A-1,random" # For second monitor

# Input device configuration (optional)
# exec-once = hyprctl keyword input:numlock_by_default true
EOF

    echo -e "${GREEN}~/.config/hypr/hyprland.conf, keybindings.conf, windowrules.conf, and autostart.conf generated.${NC}"
}

generate_waybar_config() {
    echo -e "${BLUE}--- Generating ~/.config/waybar/config ---${NC}"
    mkdir -p ~/.config/waybar

    local battery_module=""
    if [[ "$ENABLE_BATTERY_WAYBAR" == "true" ]]; then
        battery_module='
        "battery": {
            "format": "{icon} {capacity}%",
            "format-charging": "充電 {capacity}%",
            "format-plugged": "AC {capacity}%",
            "format-alt": "{time} {icon}",
            "format-icons": ["", "", "", "", ""]
        },'
    fi

    local waybar_modules_left=""
    local waybar_modules_center=""
    local waybar_modules_right=""

    if [[ "$WAYBAR_POSITION" == "top" ]]; then
        waybar_modules_left='["hyprland/workspaces", "hyprland/window"]'
        waybar_modules_center='["clock"]'
        waybar_modules_right='["cpu", "memory", "network", "pulseaudio", "backlight", "battery", "tray"]'
    else # bottom
        waybar_modules_left='["hyprland/workspaces", "hyprland/window"]'
        waybar_modules_center='["clock"]'
        waybar_modules_right='["cpu", "memory", "network", "pulseaudio", "backlight", "battery", "tray"]'
    fi


    cat << EOF > ~/.config/waybar/config
// Waybar configuration file generated by the setup script.
// For more information, see: https://github.com/Alexays/Waybar/wiki/Configuration

{
    "layer": "top", // ${WAYBAR_POSITION} or bottom
    "position": "${WAYBAR_POSITION}",
    "mod": "dock",
    "height": 30,
    "spacing": 4,
    "margin-top": 0,
    "margin-bottom": 0,
    "margin-left": 0,
    "margin-right": 0,

    "include": [
        "~/.config/waybar/modules.jsonc" // Example for modular config
    ],

    "modules-left": ${waybar_modules_left},
    "modules-center": ${waybar_modules_center},
    "modules-right": ${waybar_modules_right},

    "hyprland/workspaces": {
        "format": "{icon}",
        "format-icons": {
            "1": "",
            "2": "",
            "3": "",
            "4": "",
            "5": "",
            "6": "",
            "7": "",
            "8": "",
            "9": "",
            "10": "",
            "active": "",
            "default": ""
        },
        "on-click": "activate",
        "all-outputs": true
    },

    "hyprland/window": {
        "format": "" // Do not show focused app name
    },

    "clock": {
        "format": "{:%H:%M}", // Only time
        "tooltip-format": "<big>{:%Y %B %d}</big>\n<small>{:%A}</small>"
    },

    "cpu": {
        "format": " {usage}%",
        "tooltip": true,
        "on-click": "kitty -e btop" // Open btop on click
    },

    "memory": {
        "format": " {percentage}%",
        "tooltip": true,
        "on-click": "kitty -e btop" // Open btop on click
    },

    "network": {
        "format-wifi": " {essid}",
        "format-ethernet": " {ifname}",
        "format-disconnected": "⚠ Disconnected",
        "tooltip-format": "{ifname} {ipaddr}/{cidr}  {bandwidthUpBytes}  {bandwidthDownBytes}"
    },

    "pulseaudio": {
        "format": " {volume}%",
        "format-muted": " Muted",
        "on-click": "pavucontrol"
    },

    "backlight": {
        "format": " {percent}%",
        "tooltip": true
    },

    ${battery_module}

    "tray": {
        "icon-size": 18,
        "spacing": 10
    }
}
EOF
    echo -e "${GREEN}~/.config/waybar/config generated.${NC}"
}

generate_waybar_style() {
    echo -e "${BLUE}--- Generating ~/.config/waybar/style.css ---${NC}"
    mkdir -p ~/.config/waybar

    cat << EOF > ~/.config/waybar/style.css
/* Waybar style.css generated by the setup script. */
/* Dracula Theme with Accent Color */

@define-color background #282A36;
@define-color foreground #F8F8F2;
@define-color current_line #44475A;
@define-color comment #6272A4;
@define-color cyan #8BE9FD;
@define-color green #50FA7B;
@define-color orange #FFB86C;
@define-color pink #FF79C6;
@define-color purple #BD93F9;
@define-color red #FF5555;
@define-color yellow #F1FA8C;
@define-color accent_color ${ACCENT_COLOR};

* {
    border: none;
    border-radius: 0;
    font-family: "JetBrains Mono Nerd Font", "Noto Sans CJK JP", "Noto Color Emoji";
    font-size: 13px;
    min-height: 0;
}

window#waybar {
    background-color: rgba(40, 42, 54, 0.9); /* Semi-transparent dark background */
    border-bottom: 2px solid @accent_color; /* Accent color border */
    color: @foreground;
    transition-property: background-color;
    transition-duration: .5s;
}

window#waybar.hidden {
    opacity: 0.2;
}

#workspaces button {
    padding: 0 5px;
    background-color: transparent;
    color: @comment;
    border-bottom: 2px solid transparent;
}

#workspaces button:hover {
    background-color: @current_line;
    border-bottom: 2px solid @accent_color;
}

#workspaces button.focused {
    color: @accent_color;
    background-color: @current_line;
    border-bottom: 2px solid @accent_color;
}

#workspaces button.urgent {
    background-color: @red;
}

#workspaces button.active {
    color: @accent_color;
}

#mode {
    background-color: @orange;
    border-bottom: 2px solid @accent_color;
}

#clock,
#cpu,
#memory,
#network,
#pulseaudio,
#backlight,
#battery,
#tray,
#hyprland-window {
    padding: 0 10px;
    margin: 0 4px;
    background-color: @current_line;
    border-radius: 8px; /* Rounded corners for modules */
    border: 1px solid @accent_color; /* Accent border for modules */
}

/* Specific module styling */
#clock {
    color: @yellow;
    font-weight: bold;
}

#cpu {
    color: @green;
}

#memory {
    color: @purple;
}

#network {
    color: @cyan;
}

#pulseaudio {
    color: @pink;
}

#backlight {
    color: @orange;
}

#battery {
    color: @green;
}

#battery.charging, #battery.plugged {
    color: @yellow;
}

#battery.critical:not(.charging) {
    color: @red;
}

#tray {
    background-color: @current_line;
    border: 1px solid @accent_color;
}

#custom-media {
    background-color: @purple;
    color: @foreground;
}

#custom-power {
    background-color: @red;
    color: @foreground;
    border-radius: 8px;
    margin-right: 8px;
    padding: 0 15px;
}
EOF
    echo -e "${GREEN}~/.config/waybar/style.css generated.${NC}"
}

setup_rofi() {
    echo -e "${BLUE}--- Setting up Rofi ---${NC}"
    mkdir -p ~/.config/rofi

    # Create a simple Rofi theme based on Dracula
    cat << EOF > ~/.config/rofi/dracula.rasi
/* Rofi Dracula Theme generated by setup script */

configuration {
    modi: "drun,run,ssh";
    font: "JetBrains Mono Nerd Font 10";
    show-icons: true;
    icon-theme: "Papirus"; /* Ensure you have an icon theme installed, e.g., papirus-icon-theme */
    display-drun: "Apps";
    display-run: "Run";
    display-ssh: "SSH";
    sidebar-mode: false;
    scroll-method: 0;
    case-sensitive: false;
    cycle: true;
    hide-scrollbar: true;
    hover-select: true;
}

@theme "dracula" { /* Inherit from the default dracula theme if it exists, or define all colors */
    background-color: #282A36;
    text-color: #F8F8F2;
    border-color: ${ACCENT_COLOR};
    selection-color: #F8F8F2;
    selected-normal-background: #44475A;
    selected-normal-foreground: #F8F8F2;
    normal-background: #282A36;
    normal-foreground: #F8F8F2;
    alternate-normal-background: #282A36;
    alternate-normal-foreground: #F8F8F2;
    urgent-background: #FF5555;
    urgent-foreground: #F8F8F2;
    selected-urgent-background: #FF5555;
    selected-urgent-foreground: #F8F8F2;
    active-background: #BD93F9;
    active-foreground: #F8F8F2;
    selected-active-background: #BD93F9;
    selected-active-foreground: #F8F8F2;
    separator-color: #44475A;
}

window {
    background-color: @background;
    border: 2px;
    border-color: @border-color;
    padding: 10px;
    border-radius: 10px;
}

mainbox {
    background-color: @background;
}

inputbar {
    background-color: @normal-background;
    children: [ prompt, entry ];
    border-radius: 5px;
    padding: 5px;
    margin: 5px;
    border: 1px solid @border-color;
}

prompt {
    enabled: true;
    padding: 0px 5px 0px 0px;
    background-color: @normal-background;
    text-color: @text-color;
}

entry {
    background-color: @normal-background;
    text-color: @text-color;
    placeholder: "Search...";
    placeholder-color: @comment;
}

listview {
    background-color: @background;
    columns: 1;
    lines: 7;
    spacing: 5px;
    cycle: true;
    dynamic: true;
    layout: vertical;
}

element {
    background-color: @normal-background;
    text-color: @normal-foreground;
    padding: 5px;
    border-radius: 5px;
}

element selected {
    background-color: @selected-normal-background;
    text-color: @selected-normal-foreground;
    border: 1px solid @border-color;
}

element-icon {
    size: 1em;
    vertical-align: middle;
}

element-text {
    vertical-align: middle;
}

scrollbar {
    handle-color: @border-color;
    background-color: @current_line;
    border-radius: 5px;
    width: 5px;
}
EOF
    echo -e "${GREEN}Rofi configuration generated.${NC}"
}

setup_gtk_qt_theme() {
    echo -e "${BLUE}--- Setting up GTK and QT themes ---${NC}"

    # GTK Theme (full-dracula-theme-git)
    mkdir -p ~/.config/gtk-3.0
    mkdir -p ~/.config/gtk-4.0

    cat << EOF > ~/.config/gtk-3.0/settings.ini
[Settings]
gtk-application-prefer-dark-theme=true
gtk-theme-name=Dracula
gtk-icon-theme=Papirus # Or your preferred icon theme
gtk-cursor-theme=Dracula
gtk-font-name=Noto Sans 10
EOF

    cat << EOF > ~/.config/gtk-4.0/settings.ini
[Settings]
gtk-application-prefer-dark-theme=true
gtk-theme-name=Dracula
gtk-icon-theme=Papirus # Or your preferred icon theme
gtk-cursor-theme=Dracula
gtk-font-name=Noto Sans 10
EOF

    # QT Theme (full-dracula-theme-git)
    mkdir -p ~/.config/qt5ct
    mkdir -p ~/.config/qt6ct # If qt6ct is installed

    cat << EOF > ~/.config/qt5ct/qt5ct.conf
[Qt5CT]
color_scheme_paths=
icon_theme=Papirus
style=Fusion # Or "Dracula" if it's a Qt style, otherwise Fusion is a good fallback
EOF

    # Check if qt6ct exists and create config
    if command -v qt6ct &> /dev/null; then
        cat << EOF > ~/.config/qt6ct/qt6ct.conf
[Qt6CT]
color_scheme_paths=
icon_theme=Papirus
style=Fusion # Or "Dracula" if it's a Qt style, otherwise Fusion is a good fallback
EOF
    fi

    echo -e "${GREEN}GTK and QT theme settings configured. You may need to run 'lxappearance' and 'qt5ct'/'qt6ct' manually to apply them fully.${NC}"
}

setup_seatd() {
    echo -e "${BLUE}--- Setting up seatd for autostart ---${NC}"
    echo -e "${YELLOW}Enabling and starting seatd service...${NC}"
    sudo systemctl enable seatd --now
    echo -e "${GREEN}seatd service enabled and started.${NC}"
    echo -e "${YELLOW}Adding current user to 'seat' group...${NC}"
    sudo usermod -aG seat "$USER"
    echo -e "${GREEN}User '$USER' added to 'seat' group. A reboot is required for this change to take effect.${NC}"
}

# --- Main Setup Function ---
run_setup() {
    echo -e "${BLUE}--- Starting Hyprland Setup Script ---${NC}"

    check_arch_linux
    install_packages

    ask_accent_color
    ask_gap_size
    ask_waybar_position
    ask_resolution
    ask_battery_waybar

    generate_hyprland_conf
    generate_waybar_config
    generate_waybar_style
    setup_rofi
    setup_gtk_qt_theme
    setup_seatd

    echo -e "${GREEN}--- Hyprland Setup Complete! ---${NC}"
    echo -e "${YELLOW}Please log out and log back in (or reboot) for all changes, especially 'seatd' group membership, to take effect.${NC}"
    echo -e "${YELLOW}You can then select Hyprland from your display manager (e.g., GDM, SDDM, LightDM) or start it manually via 'exec Hyprland' from a TTY after logging in.${NC}"
    echo -e "${YELLOW}Remember to adjust wallpaper path in ~/.config/hypr/autostart.conf if you want a specific one.${NC}"
    echo -e "${YELLOW}If you encounter issues, check the Hyprland Wiki and logs.${NC}"
}

# Run the setup
run_setup

