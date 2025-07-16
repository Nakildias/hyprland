#!/bin/bash

# Abort on any error
set -e

# --- Helper Functions for Menus ---
function print_menu() {
    local title="$1"
    local -n options_ref="$2" # Use a name reference for the array
    echo "--------------------------------------"
    echo " $title"
    echo "--------------------------------------"
    for i in "${!options_ref[@]}"; do
        echo " $((i+1))) ${options_ref[$i]##*/}" # Show only the filename
    done
    echo "--------------------------------------"
}

function get_choice() {
    local choice
    read -p "Enter your choice [1-$(($#))]: " choice
    # Validate that choice is a number and within range
    while ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt $(($#)) ]; do
        read -p "Invalid choice. Please enter a number between 1 and $(($#)): " choice
    done
    echo $choice
}

# --- Introduction ---
echo "------------------------------------------------------"
echo " Hyprland Arch Linux Installation Script by Gemini"
echo "------------------------------------------------------"
echo
echo "This script will guide you through installing and configuring a personalized Hyprland desktop."
echo

# --- User Choices ---

# 1. Gap Profile
gaps_in=5
gaps_out=10
gap_options=("Small (gaps_in: 3, gaps_out: 8)" "Medium (gaps_in: 5, gaps_out: 10) (Default)" "Large (gaps_in: 8, gaps_out: 15)")
print_menu "Select a Gap Profile" gap_options
gap_choice=$(get_choice "${gap_options[@]}")
case $gap_choice in
    1) gaps_in=3; gaps_out=8 ;;
    2) gaps_in=5; gaps_out=10 ;;
    3) gaps_in=8; gaps_out=15 ;;
esac

# 2. Waybar Position
waybar_position="top"
waybar_pos_options=("Top (Default)" "Bottom")
print_menu "Select Waybar Position" waybar_pos_options
# FIX: Store the choice in a variable for the summary screen.
waybar_pos_choice=$(get_choice "${waybar_pos_options[@]}")
if [ "$waybar_pos_choice" -eq 2 ]; then
    waybar_position="bottom"
    # FIX: The 'layer' must always be 'top' for Waybar to draw *over* windows.
    # Setting it to 'bottom' hides it behind application windows. 'position' controls
    # whether it's at the top or bottom of the screen.
    # The 'waybar_layer="bottom"' line has been removed.
fi

# 3. Waybar Clock Format
# FIX: Removed single quotes from format strings. They would be written into the
# JSON file, making it invalid. Use double quotes for the assignment.
clock_format=" {:%H:%M  %d/%m}"
clock_options=("Time and Date (Default)" "Time Only")
print_menu "Select Waybar Clock Format" clock_options
# FIX: Store the choice in a variable for the summary screen.
clock_choice=$(get_choice "${clock_options[@]}")
if [ "$clock_choice" -eq 2 ]; then
    clock_format=" {:%H:%M}"
fi

# 4. Waybar Battery Module
waybar_battery_module=""
waybar_battery_config=""
read -p "Are you using a laptop? Would you like to enable the battery module in Waybar? (y/N): " battery_confirm
if [[ "$battery_confirm" == [yY] ]]; then
    waybar_battery_module='"battery",'
    waybar_battery_config=$(cat <<'EBC'
    "battery": {
        "states": {
            "warning": 30,
            "critical": 15
        },
        "format": "{icon} {capacity}%",
        "format-charging": " {capacity}%",
        "format-plugged": " {capacity}%",
        "format-alt": "{time} {icon}",
        "format-icons": ["", "", "", "", ""]
    },
EBC
)
fi

# 5. Default Applications
pacman_packages=(
    hyprland waybar rofi-wayland swaync qt5-wayland qt6-wayland qt5ct qt6ct kvantum swaylock swww archlinux-wallpaper
    grim slurp swappy wl-clipboard noto-fonts noto-fonts-emoji ttf-font-awesome
    xdg-desktop-portal-hyprland polkit-kde-agent nwg-look jq
)
aur_packages=(wlogout)

# Terminal
terminal_options=("Konsole" "Alacritty" "Kitty")
print_menu "Choose your default Terminal" terminal_options
terminal_choice=$(get_choice "${terminal_options[@]}")
case $terminal_choice in
    1) TERM_CMD="konsole"; pacman_packages+=("konsole") ;;
    2) TERM_CMD="alacritty"; pacman_packages+=("alacritty") ;;
    3) TERM_CMD="kitty"; pacman_packages+=("kitty") ;;
esac

# IDE
ide_options=("Kate (Default)" "Visual Studio Code" "Neovim")
print_menu "Choose your default IDE/Text Editor" ide_options
ide_choice=$(get_choice "${ide_options[@]}")
case $ide_choice in
    1) IDE_CMD="kate"; pacman_packages+=("kate") ;;
    2) IDE_CMD="code"; aur_packages+=("visual-studio-code-bin") ;;
    3) IDE_CMD="nvim"; pacman_packages+=("neovim") ;;
esac

# File Manager
fm_options=("Dolphin (Default)" "Nautilus" "Thunar")
print_menu "Choose your default File Manager" fm_options
fm_choice=$(get_choice "${fm_options[@]}")
case $fm_choice in
    1) FM_CMD="dolphin"; pacman_packages+=("dolphin") ;;
    2) FM_CMD="nautilus"; pacman_packages+=("nautilus") ;;
    3) FM_CMD="thunar"; pacman_packages+=("thunar") ;;
esac

# 6. Accent Color
accent_options=("Blue (Default Arch)" "Red" "Orange" "Purple" "Yellow" "Green" "Black" "White" "Custom")
color_map=(
    ["1"]="#1188aa" # Blue
    ["2"]="#e06c75" # Red
    ["3"]="#d19a66" # Orange
    ["4"]="#c678dd" # Purple
    ["5"]="#e5c07b" # Yellow
    ["6"]="#98c379" # Green
    ["7"]="#282a36" # Black
    ["8"]="#f8f8f2" # White
)
print_menu "Choose an Accent Color" accent_options
color_choice=$(get_choice "${accent_options[@]}")

if [ "$color_choice" -eq 9 ]; then
    read -p "Enter custom hex color (e.g., #1a2b3c): " ACCENT_COLOR
    while ! [[ "$ACCENT_COLOR" =~ ^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$ ]]; do
        read -p "Invalid format. Please enter a valid hex color: " ACCENT_COLOR
    done
else
    ACCENT_COLOR=${color_map[$color_choice]}
fi
HYPR_ACCENT_COLOR=${ACCENT_COLOR#\#}

# 7. Wallpaper Selection
# FIX: The WALLPAPER_EXEC variable has been removed for a more direct implementation.
WALLPAPER_PATH=""
wallpaper_dir_user="$HOME/Pictures/wallpapers"
wallpaper_dir_system="/usr/share/backgrounds"
wallpaper_options=()

# Create user wallpaper directory if it doesn't exist
mkdir -p "$wallpaper_dir_user"

# Find wallpapers in user and system directories
if [ -d "$wallpaper_dir_user" ]; then
    while IFS= read -r -d $'\0' file; do
        wallpaper_options+=("$file")
    done < <(find "$wallpaper_dir_user" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) -print0)
fi
if [ -d "$wallpaper_dir_system" ]; then
     while IFS= read -r -d $'\0' file; do
        wallpaper_options+=("$file")
    done < <(find "$wallpaper_dir_system" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) -print0)
fi

if [ ${#wallpaper_options[@]} -gt 0 ]; then
    wallpaper_options+=("None")
    print_menu "Select a Wallpaper" wallpaper_options
    wallpaper_choice=$(get_choice "${wallpaper_options[@]}")
    if [ "$wallpaper_choice" -le "${#wallpaper_options[@]}" ] && [[ "${wallpaper_options[$((wallpaper_choice-1))]}" != "None" ]]; then
        WALLPAPER_PATH="${wallpaper_options[$((wallpaper_choice-1))]}"
    fi
else
    echo "No wallpapers found in $wallpaper_dir_user or $wallpaper_dir_system. You can add some later."
fi

# --- Final Confirmation ---
echo
echo "------------------------------------------------------"
echo " Installation Summary"
echo "------------------------------------------------------"
echo " Gaps: ${gap_options[$((gap_choice-1))]}"
echo " Waybar Position: ${waybar_pos_options[$((waybar_pos_choice-1))]}"
echo " Clock: ${clock_options[$((clock_choice-1))]}"
echo " Battery Meter: ${battery_confirm:-N}"
echo " Terminal: ${terminal_options[$((terminal_choice-1))]}"
echo " IDE: ${ide_options[$((ide_choice-1))]}"
echo " File Manager: ${fm_options[$((fm_choice-1))]}"
echo " Accent Color: $ACCENT_COLOR"
echo " Wallpaper: ${WALLPAPER_PATH:-None}"
echo "------------------------------------------------------"
echo
read -p "Do you want to proceed with the installation? (y/N): " final_confirm
if [[ "$final_confirm" != [yY] ]]; then
    echo "Installation aborted."
    exit 0
fi

# --- User Input for Monitor Configuration ---
MONITOR_CONFIG=""
read -p "Do you have a single monitor? (y/N): " single_monitor
if [[ "$single_monitor" == [yY] ]]; then
    echo "Please provide your monitor's resolution and refresh rate."
    read -p "Resolution (e.g., 1920x1080): " resolution
    read -p "Refresh Rate (e.g., 144): " refresh_rate
    if [[ -n "$resolution" && -n "$refresh_rate" ]]; then
        MONITOR_CONFIG="monitor=,${resolution}@${refresh_rate},auto,1"
    else
        echo "Invalid input. Using default monitor settings."
    fi
else
    echo "Multi-monitor setup detected. You will need to configure monitors manually in ~/.config/hypr/hyprland.conf"
    echo "A placeholder configuration will be created."
fi

# --- AUR Helper (yay) Installation ---
if ! command -v yay &> /dev/null; then
    echo "AUR helper 'yay' not found. Installing..."
    sudo pacman -S --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/yay.git
    (cd yay && makepkg -si --noconfirm)
    rm -rf yay
    echo "'yay' installed successfully."
else
    echo "'yay' is already installed."
fi


# --- Package Installation ---
echo "Updating system and installing necessary packages..."
# Install official packages
sudo pacman -Syu --needed --noconfirm "${pacman_packages[@]}"
# Install AUR packages
yay -S --needed --noconfirm "${aur_packages[@]}"


# --- Configuration Directory Creation ---
echo "Creating configuration directories..."
mkdir -p ~/.config/hypr
mkdir -p ~/.config/waybar
mkdir -p ~/.config/rofi
mkdir -p ~/.config/swaync
mkdir -p ~/.config/Kvantum
mkdir -p ~/.config/wlogout
mkdir -p ~/.config/qt5ct    # <-- Add this line
mkdir -p ~/.config/qt6ct    # <-- Add this line
mkdir -p ~/.config/gtk-3.0  # <-- Also adding this from later in the script for consistency
# systemd directory creation is handled in its own section now

# --- Hyprland Configuration ---
echo "Creating hyprland.conf..."
cat <<EOF > ~/.config/hypr/hyprland.conf
# -----------------------------------------------------
# Hyprland Config by Gemini
# -----------------------------------------------------

# --- Monitor Configuration ---
${MONITOR_CONFIG:-monitor=,preferred,auto,1}

# --- Autostart Programs (Optimized for Speed) ---
exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = /usr/lib/polkit-kde-authentication-agent-1
exec-once = waybar
exec-once = swaync
exec-once = swww init
# FIX: Wallpaper command is now generated directly here.
# This uses shell parameter expansion: if WALLPAPER_PATH is set and not empty,
# it generates the exec-once line. The quoting is more robust.
${WALLPAPER_PATH:+exec-once = sleep 1 && swww img "${WALLPAPER_PATH}" --transition-type any}
# --- Environment Variables ---
env = XCURSOR_SIZE,24
env = QT_QPA_PLATFORMTHEME,qt5ct

# --- Input Devices ---
input {
    kb_layout = us
    follow_mouse = 1
    touchpad { natural_scroll = no }
    sensitivity = 0
}

# --- General Settings ---
general {
    gaps_in = $gaps_in
    gaps_out = $gaps_out
    border_size = 2
    col.active_border = rgba(${HYPR_ACCENT_COLOR}ee) rgba(0055a4ee) 45deg
    col.inactive_border = rgba(595959aa)
    layout = dwindle
}

# --- Decoration ---
decoration {
    rounding = 10
    blur {
        enabled = true
        size = 5
        passes = 2
        new_optimizations = on
    }
    drop_shadow = yes
    shadow_range = 4
    shadow_render_power = 3
    col.shadow = rgba(1a1a1aee)
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

# --- Layouts ---
dwindle {
    pseudotile = yes
    preserve_split = yes
}
master { new_is_master = true }

# --- Window Rules ---
windowrulev2 = float, class:^(kcalc|${FM_CMD}|qt5ct|qt6ct|nwg-look|wlogout)$
windowrulev2 = float, title:^(Copying|Moving|Deleting|File Operation Progress)$
windowrulev2 = noblur, class:^(wlogout)$

# --- Keybindings ---
\$mainMod = SUPER

# Application Launchers
bind = \$mainMod, RETURN, exec, $TERM_CMD
bind = \$mainMod, E, exec, $FM_CMD
bind = \$mainMod, D, exec, rofi -show drun
bind = \$mainMod, T, exec, $IDE_CMD
bind = \$mainMod, C, exec, kcalc

# Window Management
bind = \$mainMod, Q, killactive,
bind = \$mainMod, M, exec, wlogout
bind = \$mainMod, F, fullscreen,
bind = \$mainMod, SPACE, togglefloating,
bind = \$mainMod, P, pseudo,

# Waybar Toggle
bind = \$mainMod, W, exec, pkill -SIGUSR1 waybar || waybar

# Focus
bind = \$mainMod, left, movefocus, l
bind = \$mainMod, right, movefocus, r
bind = \$mainMod, up, movefocus, u
bind = \$mainMod, down, movefocus, d

# Workspaces
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

# Move window to workspace
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

# Scroll through existing workspaces
bind = \$mainMod, mouse_down, workspace, e+1
bind = \$mainMod, mouse_up, workspace, e-1

# Move/resize windows with mouse
bindm = \$mainMod, mouse:272, movewindow
bindm = \$mainMod, mouse:273, resizewindow

# Screenshots
bind = , Print, exec, grim -g "\$(slurp)" - | swappy -f -
bind = \$mainMod, Print, exec, grim -g "\$(hyprctl activewindow -j | jq -r '"\\(.at[0]),\\(.at[1]) \\(.size[0])x\\(.size[1])"') " - | swappy -f -
EOF

# --- Waybar Configuration ---
echo "Creating Waybar config and style..."
cat <<EOF > ~/.config/waybar/config.jsonc
{
    "layer": "top",
    "position": "$waybar_position",
    "height": 40,
    "modules-left": ["hyprland/workspaces", "hyprland/window"],
    "modules-center": ["clock"],
    "modules-right": [${waybar_battery_module}"tray", "pulseaudio", "network", "cpu", "memory"],

    "hyprland/workspaces": {
        "format": "{icon}",
        "on-click": "activate",
        "format-icons": {
            "default": "",
            "active": "",
            "urgent": ""
        }
    },
    "clock": {
        "format": "$clock_format",
        "tooltip-format": "<big>{:%Y %B}</big>\\n<tt><small>{calendar}</small></tt>"
    },
    ${waybar_battery_config}
    "cpu": {
        "format": " {usage}%",
        "tooltip": true
    },
    "memory": {
        "format": " {}%"
    },
    "network": {
        "format-wifi": "  {essid}",
        "format-ethernet": "󰈀 {ifname}",
        "format-disconnected": "⚠ Disconnected",
        "tooltip-format": "{ifname} via {gwaddr} ",
        "on-click": "nm-connection-editor"
    },
    "pulseaudio": {
        "format": "{icon} {volume}%",
        "format-muted": " Muted",
        "format-icons": {
            "default": ["", ""]
        },
        "on-click": "pavucontrol"
    },
    "tray": {
        "icon-size": 18,
        "spacing": 10
    }
}
EOF

cat <<EOF > ~/.config/waybar/style.css
* {
    border: none;
    border-radius: 10px;
    font-family: Noto Sans, FontAwesome;
    font-size: 14px;
    min-height: 0;
}

window#waybar {
    background-color: rgba(40, 42, 54, 0.8);
    color: #f8f8f2;
    border: 2px solid $ACCENT_COLOR;
    border-radius: 15px;
}

#workspaces button.active {
    background: $ACCENT_COLOR;
    color: #282a36;
}

#workspaces button {
    padding: 0 10px;
    background: transparent;
    color: #f8f8f2;
    border-radius: 10px;
}

#workspaces button:hover {
    background: #44475a;
}

#window, #clock, #cpu, #memory, #pulseaudio, #network, #tray, #battery {
    padding: 0 10px;
    margin: 5px;
    background-color: #44475a;
    border-radius: 10px;
}
EOF

# --- Rofi Configuration ---
echo "Creating Rofi config..."
cat <<EOF > ~/.config/rofi/config.rasi
configuration {
    modi: "drun,run,window";
    show-icons: true;
    font: "Noto Sans 12";
}

@theme "/dev/null"

* {
    bg: #282a36;
    bg-alt: #44475a;
    fg: #f8f8f2;
    accent: $ACCENT_COLOR;

    background-color: transparent;
    text-color: @fg;
}

window {
    background-color: rgba(40, 42, 54, 0.9);
    border: 2px;
    border-color: @accent;
    border-radius: 15px;
    width: 50%;
    padding: 20px;
}

mainbox {
    children: [inputbar, listview];
    spacing: 15px;
}

inputbar {
    children: [prompt, entry];
    background-color: @bg-alt;
    border-radius: 10px;
    padding: 10px;
}

prompt { text-color: @accent; }
entry { placeholder: "Search..."; }

listview {
    lines: 8;
    cycle: true;
    dynamic: true;
    layout: vertical;
}

element {
    padding: 10px;
    border-radius: 10px;
}

element-icon {
    size: 24px;
    padding: 0 10px 0 0;
}

element.selected.normal {
    background-color: @accent;
    text-color: @bg;
}
EOF

# --- wlogout Configuration ---
echo "Creating wlogout config..."
mkdir -p ~/.config/wlogout
cat <<EOF > ~/.config/wlogout/layout.json
{
    "buttons": [
        { "label": "Shutdown", "action": "systemctl poweroff", "keybind": "s" },
        { "label": "Reboot", "action": "systemctl reboot", "keybind": "r" },
        { "label": "Logout", "action": "hyprctl dispatch exit", "keybind": "l" },
        { "label": "Lock", "action": "swaylock", "keybind": "k" }
    ]
}
EOF

cat <<EOF > ~/.config/wlogout/style.css
window {
    background-color: rgba(40, 42, 54, 0.9);
    font-family: Noto Sans;
    font-size: 16pt;
    color: #f8f8f2;
}

button {
    background-color: #44475a;
    color: #f8f8f2;
    border: 2px solid #282a36;
    border-radius: 15px;
    background-repeat: no-repeat;
    background-position: center;
    background-size: 25%;
}

button:focus, button:active, button:hover {
    background-color: $ACCENT_COLOR;
    color: #282a36;
    border: 2px solid $ACCENT_COLOR;
    outline-style: none;
}

#lock { background-image: image(url("/usr/share/wlogout/icons/lock.png")); }
#logout { background-image: image(url("/usr/share/wlogout/icons/logout.png")); }
#reboot { background-image: image(url("/usr/share/wlogout/icons/reboot.png")); }
#shutdown { background-image: image(url("/usr/share/wlogout/icons/shutdown.png")); }
EOF


# --- Theming Setup ---
echo "Applying GTK and QT themes..."
# Create necessary directories for settings
mkdir -p ~/.config/gtk-3.0
cat <<EOF > ~/.config/gtk-3.0/settings.ini
[Settings]
gtk-theme-name=Adwaita-dark
gtk-icon-theme-name=breeze-dark
gtk-cursor-theme-name=breeze_cursors
gtk-font-name=Noto Sans 11
EOF

# Set GSettings for applications that use it
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
gsettings set org.gnome.desktop.interface icon-theme 'breeze-dark'
gsettings set org.gnome.desktop.interface cursor-theme 'breeze_cursors'
gsettings set org.gnome.desktop.interface font-name 'Noto Sans 11'

cat <<EOF > ~/.config/qt5ct/qt5ct.conf
[Appearance]
icon_theme=breeze-dark
style=kvantum
[Fonts]
general=@Noto Sans,11,-1,5,50,0,0,0,0,0
EOF
ln -sf ~/.config/qt5ct/qt5ct.conf ~/.config/qt6ct/qt6ct.conf
cat <<EOF > ~/.config/Kvantum/kvantum.kvconfig
[General]
theme=KvAdaptaDark
EOF

# --- Systemd Autostart Configuration ---
read -p "Do you want to enable automatic login and startup of Hyprland (bypassing a login manager)? (y/N): " autostart_confirm
if [[ "$autostart_confirm" == [yY] ]]; then
    CURRENT_USER=$(whoami)

    # 1. Create a systemd user service for Hyprland.
    echo "Creating systemd user service for Hyprland..."
    mkdir -p ~/.config/systemd/user

    cat <<EOF > ~/.config/systemd/user/hyprland.service
[Unit]
Description=Hyprland Wayland Compositor
Documentation=https://wiki.hyprland.org/
PartOf=graphical-session.target
After=graphical-session-pre.target

[Service]
ExecStart=/bin/bash -c "sleep 1 && dbus-update-activation-environment --systemd --all && exec Hyprland"
Restart=always
RestartSec=1

[Install]
WantedBy=graphical-session.target
EOF

    systemctl --user daemon-reload
    systemctl --user enable hyprland.service

    # 2. Configure systemd for TTY autologin.
    echo "Configuring systemd for automatic login on TTY1..."
    echo "This requires sudo privileges to write a system file."
    SERVICE_DIR="/etc/systemd/system/getty@tty1.service.d"
    sudo mkdir -p "$SERVICE_DIR"
    cat <<EOF | sudo tee "$SERVICE_DIR/override.conf" > /dev/null
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $CURRENT_USER --noclear %I \$TERM
EOF
    echo "Systemd autologin configured."

    # 3. Configure shell profile to trigger the systemd graphical session.
    echo "Configuring shell profile to launch the graphical session..."
    PROFILE_FILE="$HOME/.bash_profile"
    LAUNCH_CMD="
# Start the graphical session on TTY1
if [ -z \"\$DISPLAY\" ] && [ -z \"\$WAYLAND_DISPLAY\" ] && [ \"\$(tty)\" = \"/dev/tty1\" ]; then
  exec systemctl --user --wait start graphical-session.target
fi"

    # Add the command to .bash_profile if it's not already there
    if ! grep -q "graphical-session.target" "$PROFILE_FILE" 2>/dev/null; then
        echo -e "$LAUNCH_CMD" >> "$PROFILE_FILE"
        echo "Graphical session launch command added to $PROFILE_FILE."
    else
        echo "Graphical session launch command already exists in $PROFILE_FILE."
    fi
fi


# --- Final Instructions ---
echo
echo "------------------------------------------------------"
echo " Installation Complete! 🎉"
echo "------------------------------------------------------"
echo " All configurations have been generated based on your choices."
echo
echo "What's next?"
echo "1. Reboot your system with 'sudo reboot'."
echo "2. If you enabled autostart, Hyprland should launch automatically."
echo "   If not, select 'Hyprland' at your login screen."
echo "3. Enjoy your new personalized desktop!"
echo
echo "NOTE: If you have a multi-monitor setup, please edit ~/.config/hypr/hyprland.conf to match your display configuration."
