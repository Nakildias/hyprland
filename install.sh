#!/bin/bash

# Hyprland Automated Setup Script
# This script helps configure Hyprland, Waybar, and Rofi with user-defined options.

# --- Variables ---
HYPR_CONFIG_DIR="$HOME/.config/hypr"
WAYBAR_CONFIG_DIR="$HOME/.config/waybar"
ROFI_CONFIG_DIR="$HOME/.config/rofi"

ACCENT_COLOR=""
GAP_SIZE=""
WAYBAR_POSITION=""
MONITOR_RESOLUTION=""
MONITOR_REFRESH_RATE=""
ENABLE_BATTERY="false"

# --- Functions ---

# Function to display a message box (instead of alert)
show_message() {
    echo "-----------------------------------------------------"
    echo "$1"
    echo "-----------------------------------------------------"
}

# Function to prompt user for accent color
prompt_accent_color() {
    show_message "Choose your Accent Color:"
    declare -A colors
    colors[1]="Dracula Purple (0xBD93F9)"
    colors[2]="Dracula Pink (0xFF79C6)"
    colors[3]="Dracula Green (0x50FA7B)"
    colors[4]="Nord Blue (0x88C0D0)"
    colors[5]="Nord Purple (0xB48EAD)"
    colors[6]="Catppuccin Macchiato Rosewater (0xF5E0DC)"
    colors[7]="Catppuccin Macchiato Flamingo (0xF2CDCD)"
    colors[8]="Gruvbox Orange (0xFE8019)"
    colors[9]="Solarized Cyan (0x2AA198)"
    colors[10]="One Dark Pro Blue (0x61AFEF)"

    for i in "${!colors[@]}"; do
        echo "$i) ${colors[$i]}"
    done
    echo "11) Custom HEX color"

    read -p "Enter your choice (1-11): " color_choice

    case $color_choice in
        1) ACCENT_COLOR="0xBD93F9";;
        2) ACCENT_COLOR="0xFF79C6";;
        3) ACCENT_COLOR="0x50FA7B";;
        4) ACCENT_COLOR="0x88C0D0";;
        5) ACCENT_COLOR="0xB48EAD";;
        6) ACCENT_COLOR="0xF5E0DC";;
        7) ACCENT_COLOR="0xF2CDCD";;
        8) ACCENT_COLOR="0xFE8019";;
        9) ACCENT_COLOR="0x2AA198";;
        10) ACCENT_COLOR="0x61AFEF";;
        11)
            read -p "Enter custom HEX color code (e.g., 0xRRGGBB): " custom_hex
            if [[ ! "$custom_hex" =~ ^0x[0-9a-fA-F]{6}$ ]]; then
                show_message "Invalid HEX color format. Using default: 0xBD93F9"
                ACCENT_COLOR="0xBD93F9"
            else
                ACCENT_COLOR="$custom_hex"
            fi
            ;;
        *)
            show_message "Invalid choice. Using default: 0xBD93F9"
            ACCENT_COLOR="0xBD93F9";;
    esac
}

# Function to prompt user for gap size
prompt_gap_size() {
    show_message "Choose Gap Size:"
    echo "1) Small (5px)"
    echo "2) Medium (10px)"
    echo "3) Large (15px)"
    echo "4) Custom"
    read -p "Enter your choice (1-4): " gap_choice

    case $gap_choice in
        1) GAP_SIZE="5";;
        2) GAP_SIZE="10";;
        3) GAP_SIZE="15";;
        4)
            read -p "Enter custom gap size in pixels (e.g., 8): " custom_gap
            if [[ "$custom_gap" =~ ^[0-9]+$ ]]; then
                GAP_SIZE="$custom_gap"
            else
                show_message "Invalid input. Using default Medium (10px)."
                GAP_SIZE="10"
            fi
            ;;
        *)
            show_message "Invalid choice. Using default Medium (10px)."
            GAP_SIZE="10";;
    esac
}

# Function to prompt user for Waybar position
prompt_waybar_position() {
    show_message "Choose Waybar Position:"
    echo "1) Top"
    echo "2) Bottom"
    read -p "Enter your choice (1-2): " waybar_pos_choice

    case $waybar_pos_choice in
        1) WAYBAR_POSITION="top";;
        2) WAYBAR_POSITION="bottom";;
        *)
            show_message "Invalid choice. Using default Top."
            WAYBAR_POSITION="top";;
    esac
}

# Function to prompt user for monitor resolution and refresh rate
prompt_monitor_settings() {
    show_message "Monitor Settings (for single monitor setups):"
    echo "If you have multiple monitors, you will need to adjust 'monitor=' lines in hyprland.conf manually."
    read -p "Enter your monitor resolution (e.g., 1920x1080): " MONITOR_RESOLUTION
    read -p "Enter your monitor refresh rate (e.g., 144): " MONITOR_REFRESH_RATE

    if [[ ! "$MONITOR_RESOLUTION" =~ ^[0-9]+x[0-9]+$ ]]; then
        show_message "Invalid resolution format. Leaving monitor setting as 'auto'."
        MONITOR_RESOLUTION="auto"
        MONITOR_REFRESH_RATE=""
    elif [[ ! "$MONITOR_REFRESH_RATE" =~ ^[0-9]+$ ]]; then
        show_message "Invalid refresh rate format. Leaving monitor setting as 'auto'."
        MONITOR_RESOLUTION="auto"
        MONITOR_REFRESH_RATE=""
    fi
}

# Function to prompt user for battery in Waybar
prompt_battery_waybar() {
    show_message "Enable Battery Module in Waybar (for laptops)?"
    read -p "Enter 'y' for Yes or 'n' for No: " battery_choice
    if [[ "$battery_choice" =~ ^[Yy]$ ]]; then
        ENABLE_BATTERY="true"
    else
        ENABLE_BATTERY="false"
    fi
}

# Function to create configuration directories
create_config_dirs() {
    show_message "Creating configuration directories..."
    mkdir -p "$HYPR_CONFIG_DIR"
    mkdir -p "$WAYBAR_CONFIG_DIR"
    mkdir -p "$ROFI_CONFIG_DIR"
    show_message "Directories created."
}

# Function to generate hyprland.conf
generate_hyprland_conf() {
    show_message "Generating hyprland.conf..."

    cat << EOF > "$HYPR_CONFIG_DIR/hyprland.conf"
# Hyprland Configuration generated by setup script
# This file is sourced by Hyprland when it starts.

# --- Variables ---
\$mainMod = SUPER
\$accentColor = $ACCENT_COLOR # User-defined accent color

# --- Monitor ---
# For single monitor setup. If you have multiple monitors, adjust this section.
$(if [[ "$MONITOR_RESOLUTION" != "auto" ]]; then
    echo "monitor=,${MONITOR_RESOLUTION}@${MONITOR_REFRESH_RATE},auto,1"
else
    echo "monitor=,preferred,auto,1"
fi)

# --- Autostart (Applications that start with Hyprland) ---
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = /usr/lib/polkit-gnome/polkit-agent-helper-1 # Or other polkit agent like polkit-kde-agent
exec-once = waybar &
exec-once = hyprpaper & # Or your preferred wallpaper setter (e.g., swww)
exec-once = mako & # Notification daemon

# Note: 'seatd-launch hyprland' is used to start Hyprland itself, not as an exec-once command within hyprland.conf.
# You would typically run 'seatd-launch Hyprland' from a TTY or configure your display manager to use it.

# --- General ---
general {
    gaps_in = $GAP_SIZE
    gaps_out = $(($GAP_SIZE * 2)) # Outer gaps are double inner gaps
    border_size = 2
    col.active_border = \$accentColor
    col.inactive_border = 0x66333333 # Dark grey for inactive
    layout = dwindle
    allow_tearing = false
}

# --- Decorations ---
decoration {
    rounding = 5
    blur {
        enabled = true
        size = 3
        passes = 1
        vibrancy = 0.16
        # Semi-transparent apps blur
        # This will apply blur to windows that are semi-transparent.
        # Ensure your applications support transparency for this to work.
    }
    drop_shadow = true
    shadow_range = 4
    shadow_render_power = 0.3
    col.shadow = 0x66000000
}

# --- Animations ---
animations {
    enabled = true
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    animation = windows, 1, 7, myBezier
    animation = windowsOut, 1, 7, default, popin 80%
    animation = border, 1, 10, default
    animation = borderangle, 1, 8, default
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, default
}

# --- Input ---
input {
    kb_layout = us # Change to your keyboard layout
    follow_mouse = 1
    touchpad {
        natural_scroll = false
    }
    sensitivity = 1.0 # 0.0 - 1.0, 0.0 = no sensitivity, 1.0 = full sensitivity
}

# --- Dwindle Layout ---
dwindle {
    pseudotile = true # Master switch for pseudotiling. Enabling it makes windows float when they're not the only window in a workspace.
    preserve_split = true # You probably want this
}

# --- Gestures ---
gestures {
    workspace_swipe = true
}

# --- Window Rules ---
windowrulev2 = opacity 0.8 0.8,class:^(Alacritty|kitty|wezterm)$
windowrulev2 = opacity 0.8 0.8,class:^(Rofi)$
windowrulev2 = float,class:^(Calculator|pavucontrol|btop)$
windowrulev2 = center,class:^(Calculator|pavucontrol|btop)$

# --- Keybindings ---
# Standard Hyprland shortcuts
bind = \$mainMod, Q, killactive, # Quit focused app
bind = \$mainMod, M, exit, # Quit Hyprland
bind = \$mainMod, RETURN, exec, alacritty # Terminal (change to your preferred terminal)
bind = \$mainMod, D, exec, rofi -show drun # Rofi
bind = \$mainMod, B, exec, xdg-open https://google.com # Web Browser
bind = \$mainMod, E, exec, thunar # File Explorer (change to your preferred file manager)
bind = \$mainMod, SPACE, togglefloating, # Toggle focused app floating/tiling
bind = \$mainMod, F, fullscreen, # Toggle fullscreen for focused app
bind = \$mainMod, C, exec, gnome-calculator # Calculator
bind = \$mainMod, P, exec, spotify # Music Streaming App (change to your preferred app)
bind = \$mainMod, G, exec, steam # Steam
bind = \$mainMod, V, exec, discord # Discord

# Workspace switching
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

# Move active window to a workspace
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

# Move focus with arrow keys
bind = \$mainMod, left, movefocus, l
bind = \$mainMod, right, movefocus, r
bind = \$mainMod, up, movefocus, u
bind = \$mainMod, down, movefocus, d

# Move windows with arrow keys
bind = \$mainMod SHIFT, left, movewindow, l
bind = \$mainMod SHIFT, right, movewindow, r
bind = \$mainMod SHIFT, up, movewindow, u
bind = \$mainMod SHIFT, down, movewindow, d

# Resize windows (example, adjust as needed)
bind = \$mainMod CTRL, left, resizeactive, -50 0
bind = \$mainMod CTRL, right, resizeactive, 50 0
bind = \$mainMod CTRL, up, resizeactive, 0 -50
bind = \$mainMod CTRL, down, resizeactive, 0 50

# Scroll through workspaces with mouse
bind = \$mainMod, mouse_down, workspace, e+1
bind = \$mainMod, mouse_up, workspace, e-1

# Move/resize windows with mouse
bindm = \$mainMod, mouse:272, movewindow
bindm = \$mainMod, mouse:273, resizewindow

# Toggle Waybar
bind = \$mainMod, W, exec, pkill -SIGUSR1 waybar

# Screenshots
bind = , Print, exec, grim -g "\$(slurp)" - | wl-copy # Screenshot selected area to clipboard
bind = \$mainMod, Print, exec, grim - | wl-copy # Screenshot full screen to clipboard

# Volume control (requires pulseaudio-utils or pipewire-pulse)
bind = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
bind = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bind = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle

# Brightness control (requires brightnessctl)
bind = , XF86MonBrightnessUp, exec, brightnessctl set +5%
bind = , XF86MonBrightnessDown, exec, brightnessctl set 5%-

# GTK/QT Theme (Instructions will be provided separately)
# For GTK, you'll typically set this via ~/.config/gtk-3.0/settings.ini and ~/.config/gtk-4.0/settings.ini
# For QT, you'll typically set this via qt5ct and qt6ct
# The script will provide instructions on how to apply the full-dracula-theme-git.
EOF
    show_message "hyprland.conf generated successfully."
}

# Function to generate waybar/config
generate_waybar_config() {
    show_message "Generating waybar/config..."

    cat << EOF > "$WAYBAR_CONFIG_DIR/config"
// Waybar configuration generated by setup script

{
    "layer": "top", // "bottom" or "top" based on user choice
    "position": "$WAYBAR_POSITION",
    "mod": "dock",
    "height": 30,
    "spacing": 4,
    "margin-top": 0,
    "margin-bottom": 0,
    "margin-left": 0,
    "margin-right": 0,

    "modules-left": [
        "hyprland/workspaces",
        "hyprland/window"
    ],
    "modules-center": [
        "clock"
    ],
    "modules-right": [
        "cpu",
        "memory",
$(if [[ "$ENABLE_BATTERY" == "true" ]]; then
    echo '        "battery",'
fi)
        "pulseaudio",
        "network",
        "tray"
    ],

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
        "on-click": "activate"
    },

    "hyprland/window": {
        "format": "" // Do not show focused app name
    },

    "clock": {
        "format": "{:%H:%M}", // Time only
        "tooltip-format": "<big>{:%Y %B %d}</big>\n<small>{:%A}</small>\n<small>{:%I:%M %p}</small>"
    },

    "cpu": {
        "format": " {usage}%",
        "tooltip": true,
        "on-click": "alacritty -e btop",
        "interval": 1
    },

    "memory": {
        "format": " {}%",
        "tooltip": true,
        "on-click": "alacritty -e btop",
        "interval": 1
    },
$(if [[ "$ENABLE_BATTERY" == "true" ]]; then
    echo '    "battery": {
        "bat": "",
        "full": "",
        "charging": "ładowanie",
        "format": "{icon} {capacity}%",
        "format-charging": "ładowanie {capacity}%",
        "format-discharging": " {capacity}%",
        "format-full": " {capacity}%",
        "format-alt": "{time} {icon}",
        "tooltip": true,
        "states": {
            "good": 90,
            "warning": 30,
            "critical": 15
        }
    },'
fi)

    "pulseaudio": {
        "format": " {volume}%",
        "format-muted": " Muted",
        "on-click": "pavucontrol",
        "tooltip": true
    },

    "network": {
        "format-wifi": " {essid}",
        "format-ethernet": " {ipaddr}/{ifname}",
        "format-disconnected": " Disconnected",
        "tooltip": true
    },

    "tray": {
        "icon-size": 18,
        "spacing": 10
    }
}
EOF
    show_message "waybar/config generated successfully."
}

# Function to generate waybar/style.css
generate_waybar_style() {
    show_message "Generating waybar/style.css..."

    cat << EOF > "$WAYBAR_CONFIG_DIR/style.css"
/* Waybar Style Sheet generated by setup script */

* {
    border: none;
    border-radius: 5px;
    font-family: "Inter", sans-serif;
    font-size: 13px;
    min-height: 0;
}

window#waybar {
    background-color: rgba(44, 47, 58, 0.8); /* Dark background with transparency */
    border-bottom: 2px solid $ACCENT_COLOR; /* Accent color border */
    color: #f8f8f2; /* Light text color */
}

#workspaces button {
    padding: 0 5px;
    background-color: transparent;
    color: #f8f8f2;
    border-bottom: 2px solid transparent;
}

#workspaces button:hover {
    background-color: rgba(68, 71, 90, 0.5);
    border-bottom: 2px solid \$accentColor;
}

#workspaces button.active {
    background-color: rgba(68, 71, 90, 0.7);
    border-bottom: 2px solid $ACCENT_COLOR;
}

#workspaces button.urgent {
    background-color: #ff5555; /* Red for urgent workspace */
}

#clock,
#cpu,
#memory,
#battery,
#pulseaudio,
#network,
#tray,
#hyprland-window {
    padding: 0 10px;
    margin: 0 4px;
    background-color: rgba(68, 71, 90, 0.4); /* Dracula background for modules */
    border: 1px solid $ACCENT_COLOR; /* Accent color border for modules */
}

#clock {
    font-weight: bold;
}

#cpu {
    color: #ff79c6; /* Pink */
}

#memory {
    color: #50fa7b; /* Green */
}

#battery {
    color: #ffb86c; /* Orange */
}

#battery.charging {
    color: #8be9fd; /* Cyan when charging */
}

#battery.warning {
    color: #ff5555; /* Red when warning */
}

#pulseaudio {
    color: #bd93f9; /* Purple */
}

#network {
    color: #f1fa8c; /* Yellow */
}

#tray {
    background-color: rgba(68, 71, 90, 0.6);
}

/* Tooltips */
tooltip {
    background-color: rgba(44, 47, 58, 0.9);
    border: 1px solid $ACCENT_COLOR;
    border-radius: 5px;
    padding: 10px;
    font-size: 12px;
    color: #f8f8f2;
}
EOF
    show_message "waybar/style.css generated successfully."
}

# Function to generate rofi/config.rasi
generate_rofi_config() {
    show_message "Generating rofi/config.rasi..."

    # Extract hex color without 0x prefix for Rofi
    ROFI_ACCENT_HEX="${ACCENT_COLOR#0x}"

    cat << EOF > "$ROFI_CONFIG_DIR/config.rasi"
/* Rofi configuration generated by setup script */

configuration {
    modi: "drun,run";
    display-drun: "Apps";
    display-run: "Run";
    show-icons: true;
    icon-theme: "Dracula"; /* Assuming Dracula icon theme is installed */
    terminal: "alacritty"; /* Change to your preferred terminal */
    drun-display-format: "{name}";
    font: "Inter 10";
    # theme: "full-dracula-theme-git"; /* DEPRECATED: Theme should be set outside the configuration block */
}

@theme "full-dracula-theme-git"

/* Override colors for borders */
* {
    accent-color: #$ROFI_ACCENT_HEX;
}

window {
    border: 2px;
    border-color: @accent-color;
    border-radius: 8px;
    background-color: #282a36; /* Dracula background */
}

inputbar {
    border: 1px;
    border-color: @accent-color;
    border-radius: 5px;
    background-color: #44475a; /* Dracula foreground */
    padding: 5px;
}

entry {
    placeholder-color: #f8f8f2;
    text-color: #f8f8f2;
}

listview {
    background-color: #282a36;
    border-radius: 5px;
    margin: 5px 0;
}

element {
    padding: 5px;
    background-color: transparent;
    text-color: #f8f8f2;
    border-radius: 3px;
}

element selected {
    background-color: @accent-color;
    text-color: #282a36;
}

element-icon {
    size: 1em;
}
EOF
    show_message "rofi/config.rasi generated successfully."
}

# Function to install necessary packages on Arch Linux
install_packages() {
    show_message "Attempting to install necessary packages..."

    local packages=(
        hyprland
        waybar
        rofi
        alacritty # Or your preferred terminal
        btop
        thunar # Or your preferred file manager
        grim
        slurp
        wl-clipboard
        mako
        brightnessctl
        pulseaudio-ctl
        seatd
        hyprpaper # For wallpaper
        polkit-gnome # Or polkit-kde-agent, lxpolkit etc.
        qt5ct # For QT theme
        qt6ct # For QT theme
    )

    local aur_packages=(
        full-dracula-theme-git
    )

    # Check for AUR helper
    if command -v yay &> /dev/null; then
        show_message "yay found. Using yay to install packages."
        sudo yay -S --noconfirm "${packages[@]}" "${aur_packages[@]}"
    elif command -v paru &> /dev/null; then
        show_message "paru found. Using paru to install packages."
        sudo paru -S --noconfirm "${packages[@]}" "${aur_packages[@]}"
    else
        show_message "No AUR helper (yay/paru) found. Installing core packages with pacman."
        show_message "You will need to manually install AUR packages like 'full-dracula-theme-git'."
        sudo pacman -S --noconfirm "${packages[@]}"
    fi

    # Configure seatd
    show_message "Configuring seatd..."
    sudo usermod -a -G seat "$USER"
    sudo systemctl enable seatd --now
    show_message "Seatd enabled and started. You may need to reboot or log out/in for group changes to take effect."

    show_message "Package installation attempt complete."
}

# Function to provide installation instructions
provide_installation_instructions() {
    show_message "--- Important Next Steps ---"
    echo "1. **Reboot or Log Out/In:** After running this script, it is highly recommended to reboot your system or at least log out and log back in. This ensures that the user group changes for 'seatd' take effect and Hyprland can start correctly."
    echo ""
    echo "2. **Start Hyprland:**"
    echo "   - **From a TTY:** After logging in, you can start Hyprland by typing: \`seatd-launch Hyprland\`"
    echo "   - **From a Display Manager (e.g., GDM, SDDM, LightDM):** Most display managers should automatically detect Hyprland if it's installed correctly. Look for a session option named 'Hyprland' at your login screen. If not, you might need to create a desktop entry for it (usually done by the Hyprland package itself)."
    echo ""
    echo "3. **GTK/Qt Theme (full-dracula-theme-git):**"
    echo "   - If you used yay/paru, 'full-dracula-theme-git' should be installed."
    echo "   - Set the GTK theme using \`lxappearance\` or by manually editing:"
    echo "     \`~/.config/gtk-3.0/settings.ini\`"
    echo "     \`~/.config/gtk-4.0/settings.ini\`"
    echo "     Add/modify these lines under the \`[Settings]\` section:"
    echo "     \`gtk-theme-name=Dracula\`"
    echo "     \`gtk-icon-theme-name=Dracula\`"
    echo "     \`gtk-cursor-theme-name=Dracula\`"
    echo "   - For Qt apps, ensure \`qt5ct\` and \`qt6ct\` are installed (the script tries to install them)."
    echo "     Run \`qt5ct\` and \`qt6ct\` to set the theme to 'Dracula' (if available)."
    echo "     You also need to set the environment variable. Add this to your \`~/.profile\` or \`~/.bashrc\` (or equivalent for your shell):"
    echo "     \`export QT_QPA_PLATFORMTHEME=qt5ct\` (or \`qt6ct\`)"
    echo ""
    echo "4. **Wallpaper (hyprpaper):**"
    echo "   - Edit \`~/.config/hypr/hyprpaper.conf\` to set your wallpaper:"
    echo "     \`preload = /path/to/your/wallpaper.jpg\`"
    echo "     \`wallpaper = ,/path/to/your/wallpaper.jpg\`"
    echo "   - Make sure the wallpaper path is correct and the image exists."
    echo ""
    show_message "--- Final Check ---"
    echo "If shortcuts still don't work after rebooting and starting Hyprland correctly, please check your Hyprland log file (usually in /tmp/hypr/\$USER.\$(date +%s).log or similar) for errors."
    echo ""
    echo "Enjoy your new Hyprland setup!"
}

# --- Main Script Execution ---

show_message "Welcome to the Hyprland Automated Setup Script!"
show_message "This script will help you configure Hyprland, Waybar, and Rofi."
show_message "It will create/overwrite files in ~/.config/hypr, ~/.config/waybar, and ~/.config/rofi."
read -p "Do you want to proceed? (y/n): " proceed_choice

if [[ ! "$proceed_choice" =~ ^[Yy]$ ]]; then
    show_message "Script aborted. No changes were made."
    exit 0
fi

prompt_accent_color
prompt_gap_size
prompt_waybar_position
prompt_monitor_settings
prompt_battery_waybar

create_config_dirs
generate_hyprland_conf
generate_waybar_config
generate_waybar_style
generate_rofi_config

# Attempt to install packages
install_packages

provide_installation_instructions

show_message "Hyprland setup script finished."
