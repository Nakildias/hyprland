#!/bin/bash

# Hyprland Automated Setup Script for Arch Linux
# This script automates the installation and configuration of Hyprland
# with a personalized setup, including themes, keybindings, and more.

# --- Helper Functions for User Interaction ---

# Function to print a separator line
print_separator() {
    echo "------------------------------------------------------------------"
}

# Function to print a header for a section
print_header() {
    print_separator
    echo "    $1"
    print_separator
}

# Function to ask a yes/no question
ask_yes_no() {
    while true; do
        read -p "$1 (y/n): " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes (y) or no (n).";;
        esac
    done
}

# --- Initial Check ---
if [ "$(id -u)" -eq 0 ]; then
  echo "DO NOT RUN THIS SCRIPT AS ROOT!"
  echo "You will be prompted for your password when necessary."
  exit 1
fi

# --- 0. Package Installation ---
print_header "Starting Hyprland Setup"
echo "This script will install and configure Hyprland on your Arch Linux system."

if ask_yes_no "Do you want to proceed with the installation?"; then
    print_header "Installing Required Packages"
    echo "Updating system and installing packages. This may take a while..."

    # --- Enable Multilib for Steam ---
    echo "Enabling Multilib repository for 32-bit support (required for Steam)..."
    sudo sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
    echo "Multilib enabled."

    # Update package database after enabling multilib
    echo "Synchronizing package databases..."
    sudo pacman -Syu --noconfirm

    # Essential packages for Hyprland
    packages=(
        hyprland waybar rofi kitty thunar btop grim slurp
        qt5-wayland qt6-wayland polkit-kde-agent pipewire wireplumber
        xdg-desktop-portal-hyprland ttf-jetbrains-mono-nerd noto-fonts-emoji
        pavucontrol brightnessctl playerctl gvfs tumbler ffmpegthumbnailer
        imagemagick gnome-calculator steam discord kvantum
    )

    for pkg in "${packages[@]}"; do
        if ! sudo pacman -S --noconfirm --needed "$pkg"; then
            echo "Error: Failed to install $pkg. Aborting."
            exit 1
        fi
    done

    # Install AUR helper (yay) if not present
    if ! command -v yay &> /dev/null; then
        echo "AUR helper 'yay' not found. Installing..."
        git clone https://aur.archlinux.org/yay.git
        (cd yay && makepkg -si --noconfirm)
        rm -rf yay
    fi

    # Install AUR packages
    echo "Installing AUR packages..."
    yay -S --noconfirm full-dracula-theme-git swww

    echo "Package installation complete."
else
    echo "Installation aborted by user."
    exit 0
fi

# --- Configuration Directories ---
echo "Creating configuration directories..."
mkdir -p ~/.config/{hypr,waybar,rofi,kitty,gtk-3.0,qt5ct,qt6ct,Kvantum,environment.d}

# --- 1. Accent Color Selection ---
print_header "1. Choose Your Accent Color"
echo "Select an accent color for borders, Waybar, and other UI elements."
colors=(
    "255,179,186" # Pastel Red
    "255,223,186" # Pastel Orange
    "255,255,186" # Pastel Yellow
    "186,255,201" # Pastel Green
    "186,225,255" # Pastel Blue
    "201,186,255" # Pastel Purple
    "255,186,225" # Pastel Pink
    "173,216,230" # Light Blue
    "144,238,144" # Light Green
    "240,128,128" # Light Coral
)
color_names=("Pastel Red" "Pastel Orange" "Pastel Yellow" "Pastel Green" "Pastel Blue" "Pastel Purple" "Pastel Pink" "Light Blue" "Light Green" "Light Coral")

PS3="Enter the number for your choice: "
select color_name in "${color_names[@]}" "Custom"; do
    if [[ "$REPLY" -ge 1 && "$REPLY" -le ${#colors[@]} ]]; then
        ACCENT_COLOR_RGB=${colors[$REPLY-1]}
        break
    elif [ "$REPLY" == "$((${#colors[@]} + 1))" ]; then
        read -p "Enter custom RGB color (e.g., 255,100,150): " ACCENT_COLOR_RGB
        break
    else
        echo "Invalid selection. Please try again."
    fi
done
ACCENT_COLOR_HEX=$(printf '#%02x%02x%02x' $(echo $ACCENT_COLOR_RGB | tr ',' ' '))
echo "Accent color set to: $ACCENT_COLOR_RGB ($ACCENT_COLOR_HEX)"


# --- 1.5 Gap Size Selection ---
print_header "1.5. Choose Window Gap Size"
PS3="Enter your choice for gap size: "
select gap_choice in "Small (5px)" "Medium (10px)" "Large (15px)" "Custom"; do
    case $gap_choice in
        "Small (5px)") GAP_SIZE=5; break;;
        "Medium (10px)") GAP_SIZE=10; break;;
        "Large (15px)") GAP_SIZE=15; break;;
        "Custom") read -p "Enter custom gap size in pixels: " GAP_SIZE; break;;
        *) echo "Invalid option. Please try again.";;
    esac
done
echo "Window gap size set to: ${GAP_SIZE}px"

# --- 2. Waybar Position ---
print_header "2. Choose Waybar Position"
PS3="Select Waybar position: "
select waybar_pos in "Top" "Bottom"; do
    WAYBAR_POSITION=${waybar_pos,,}
    break
done
echo "Waybar will be positioned at the $WAYBAR_POSITION."

# --- 3. Monitor Configuration ---
print_header "3. Monitor Configuration"
MONITOR_CONFIG=""
if ! command -v hyprctl &> /dev/null || ! command -v jq &> /dev/null; then
    echo "Warning: hyprctl or jq not found. Using preferred monitor settings."
    num_monitors=0
else
    # Check if Hyprland is running
    if pgrep -x Hyprland > /dev/null; then
        num_monitors=$(hyprctl monitors -j | jq 'length')
    else
        echo "Hyprland is not running. Cannot detect monitors. Using preferred settings."
        num_monitors=0
    fi
fi

if [ "$num_monitors" -eq 1 ]; then
    echo "Single monitor detected."
    if ask_yes_no "Do you want to manually set resolution and refresh rate?"; then
        read -p "Enter resolution (e.g., 1920x1080): " resolution
        read -p "Enter refresh rate (e.g., 144): " refresh_rate
        MONITOR_CONFIG="monitor=,${resolution}@${refresh_rate},auto,1"
        echo "Monitor configured to: $MONITOR_CONFIG"
    else
        MONITOR_CONFIG="monitor=,preferred,auto,1"
        echo "Using preferred monitor settings."
    fi
else
    echo "Multiple monitors detected or monitor info not available. Using preferred settings."
    MONITOR_CONFIG="monitor=,preferred,auto,1"
fi

# --- 12. Laptop Check ---
print_header "12. Laptop Features"
IS_LAPTOP=false
if ask_yes_no "Is this a laptop?"; then
    IS_LAPTOP=true
    echo "Enabling battery module in Waybar."
else
    echo "Skipping laptop-specific features."
fi

# --- Configuration File Generation ---
print_header "Generating Configuration Files"

# --- Systemd Environment File for Theming (Most Reliable Method) ---
echo "Creating systemd environment file for robust theming..."
cat > ~/.config/environment.d/01-theme.conf <<EOF
# This file sets environment variables for theming GTK and Qt apps
# It is the most reliable way to ensure themes are applied correctly
GDK_THEME=Dracula
QT_QPA_PLATFORMTHEME=qt5ct
QT_STYLE_OVERRIDE=kvantum
EOF


# --- Hyprland Config (~/.config/hypr/hyprland.conf) ---
echo "Generating hyprland.conf..."
cat > ~/.config/hypr/hyprland.conf <<EOF
# Hyprland Configuration File
# Generated by automated setup script

########################################################################################
# AUTOGENERATED HYPRLAND CONFIG
########################################################################################

# See https://wiki.hyprland.org/Configuring/Monitors/
$MONITOR_CONFIG

# Source a file (multi-file configs)
# source = ~/.config/hypr/myColors.conf

# Execute your favorite apps at launch
exec-once = waybar &
exec-once = swww init & swww img ~/Pictures/wall.jpg # Set your wallpaper
exec-once = /usr/lib/polkit-kde-authentication-agent-1
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

# For all categories, see https://wiki.hyprland.org/Configuring/Variables/
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

    sensitivity = 0 # -1.0 - 1.0, 0 means no modification.
}

general {
    # See https://wiki.hyprland.org/Configuring/Variables/ for more
    gaps_in = $GAP_SIZE
    gaps_out = $(($GAP_SIZE * 2))
    border_size = 2
    col.active_border = rgba(${ACCENT_COLOR_RGB}ff)
    col.inactive_border = rgba(595959aa)

    layout = dwindle
}

decoration {
    # See https://wiki.hyprland.org/Configuring/Variables/ for more
    rounding = 10
    
    blur {
        enabled = true
        size = 5
        passes = 2
        new_optimizations = true
    }

    drop_shadow = yes
    shadow_range = 4
    shadow_render_power = 3
    col.shadow = rgba(1a1a1aee)
}

animations {
    enabled = yes

    # Some default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05

    animation = windows, 1, 7, myBezier
    animation = windowsOut, 1, 7, default, popin 80%
    animation = border, 1, 10, default
    animation = borderangle, 1, 8, default
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, default
}

dwindle {
    # See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
    pseudotile = yes # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
    preserve_split = yes # you probably want this
}

master {
    # See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
    new_is_master = true
}

gestures {
    # See https://wiki.hyprland.org/Configuring/Variables/ for more
    workspace_swipe = off
}

misc {
    force_default_wallpaper = 0 # Set to 0 to disable the anime girl wallpaper
}

# Example windowrule v1
# windowrule = float, ^(kitty)$
# Example windowrule v2
# windowrulev2 = float,class:^(kitty)$,title:^(kitty)$
# See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
windowrulev2 = float, class:^(gnome-calculator)$
windowrulev2 = float, class:^(pavucontrol)$
windowrulev2 = float, class:^(blueman-manager)$
windowrulev2 = float, class:^(nm-connection-editor)$
windowrulev2 = float, class:^(org.kde.polkit-kde-authentication-agent-1)$

########################################################################################
# KEYBINDINGS
########################################################################################

# See https://wiki.hyprland.org/Configuring/Binds/ for more
\$mainMod = SUPER

# --- Applications ---
bind = \$mainMod, RETURN, exec, kitty
bind = \$mainMod, B, exec, firefox # or your preferred browser
bind = \$mainMod, E, exec, thunar
bind = \$mainMod, D, exec, rofi -show drun
bind = \$mainMod, C, exec, gnome-calculator
bind = \$mainMod, G, exec, steam
bind = \$mainMod, V, exec, discord
bind = \$mainMod, P, exec, firefox --new-window https://music.youtube.com # Music Streaming App

# --- Window Management ---
bind = \$mainMod, Q, killactive,
bind = \$mainMod, M, exit,
bind = \$mainMod, F, fullscreen,
bind = \$mainMod, SPACE, togglefloating,

# --- Waybar ---
bind = \$mainMod, W, exec, pkill -SIGUSR1 waybar # Toggle Waybar

# --- Move focus with mainMod + arrow keys ---
bind = \$mainMod, left, movefocus, l
bind = \$mainMod, right, movefocus, r
bind = \$mainMod, up, movefocus, u
bind = \$mainMod, down, movefocus, d

# --- Switch workspaces with mainMod + [0-9] ---
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

# --- Move active window to a workspace with mainMod + SHIFT + [0-9] ---
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

# --- Scroll through existing workspaces with mainMod + scroll ---
bind = \$mainMod, mouse_down, workspace, e+1
bind = \$mainMod, mouse_up, workspace, e-1

# --- Move/resize windows with mainMod + LMB/RMB and dragging ---
bindm = \$mainMod, mouse:272, movewindow
bindm = \$mainMod, mouse:273, resizewindow

# --- Screenshotting ---
bind = , Print, exec, grim -g "\$(slurp)" - | wl-copy # Select area and copy
bind = SHIFT, Print, exec, grim -g "\$(slurp)" ~/Pictures/Screenshots/\$(date +'%Y-%m-%d_%H-%M-%S.png') # Select area and save

# --- Brightness and Volume ---
# You might need to adjust the device name for brightnessctl
binde=, XF86MonBrightnessUp, exec, brightnessctl set 5%+
binde=, XF86MonBrightnessDown, exec, brightnessctl set 5%-
binde=, XF86AudioRaiseVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ +5%
binde=, XF86AudioLowerVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ -5%
bind=, XF86AudioMute, exec, pactl set-sink-mute @DEFAULT_SINK@ toggle
bind=, XF86AudioPlay, exec, playerctl play-pause
bind=, XF86AudioNext, exec, playerctl next
bind=, XF86AudioPrev, exec, playerctl previous
EOF

# --- Waybar Config (~/.config/waybar/config) ---
echo "Generating Waybar config..."
WAYBAR_MODULES_RIGHT='"cpu", "memory"'
if $IS_LAPTOP; then
    WAYBAR_MODULES_RIGHT+='"battery", '
fi
WAYBAR_MODULES_RIGHT+='"pulseaudio", "backlight", "tray"'

cat > ~/.config/waybar/config <<EOF
{
    "layer": "top",
    "position": "$WAYBAR_POSITION",
    "height": 35,
    "modules-left": ["hyprland/workspaces"],
    "modules-center": ["clock"],
    "modules-right": [$WAYBAR_MODULES_RIGHT],

    "hyprland/workspaces": {
        "format": "{icon}",
        "on-click": "activate",
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
            "urgent": "",
            "focused": "",
            "default": ""
        }
    },
    "clock": {
        "format": "{:%H:%M}",
        "tooltip-format": "<big>{:%Y %B}</big>\\n<tt><small>{calendar}</small></tt>"
    },
    "cpu": {
        "format": " {usage}%",
        "tooltip": true,
        "on-click": "kitty btop"
    },
    "memory": {
        "format": " {used:0.1f}G",
        "on-click": "kitty btop"
    },
    "battery": {
        "states": {
            "good": 95,
            "warning": 30,
            "critical": 15
        },
        "format": "{icon} {capacity}%",
        "format-charging": " {capacity}%",
        "format-plugged": " {capacity}%",
        "format-icons": ["", "", "", "", ""]
    },
    "pulseaudio": {
        "format": "{icon} {volume}%",
        "format-muted": " Muted",
        "on-click": "pavucontrol",
        "format-icons": {
            "headphone": "",
            "hands-free": "",
            "headset": "",
            "phone": "",
            "portable": "",
            "car": "",
            "default": ["", "", ""]
        }
    },
    "backlight": {
        "device": "intel_backlight",
        "format": "{icon} {percent}%",
        "format-icons": ["", "", "", "", "", "", "", "", ""]
    },
    "tray": {
        "icon-size": 18,
        "spacing": 10
    }
}
EOF

# --- Waybar Style (~/.config/waybar/style.css) ---
echo "Generating Waybar style..."
cat > ~/.config/waybar/style.css <<EOF
* {
    border: none;
    border-radius: 0;
    font-family: 'JetBrains Mono Nerd Font', sans-serif;
    font-size: 14px;
    min-height: 0;
}

window#waybar {
    background: #282a36; /* Dracula BG */
    color: #f8f8f2; /* Dracula FG */
    border-bottom: 3px solid $ACCENT_COLOR_HEX;
}

#workspaces button {
    padding: 0 10px;
    color: #bd93f9; /* Dracula Purple */
}

#workspaces button.focused {
    color: $ACCENT_COLOR_HEX;
}

#workspaces button:hover {
    background: #44475a; /* Dracula Comment */
    box-shadow: inherit;
    text-shadow: inherit;
}

#workspaces button.urgent {
    color: #ff5555; /* Dracula Red */
}

#clock,
#battery,
#cpu,
#memory,
#pulseaudio,
#backlight,
#tray {
    padding: 0 10px;
    margin: 0 4px;
}
EOF

# --- Rofi Config (~/.config/rofi/config.rasi) ---
echo "Generating Rofi config..."
cat > ~/.config/rofi/config.rasi <<EOF
/* Rofi config with embedded Dracula theme to avoid parsing errors */
configuration {
    modi: "drun,run";
    show-icons: true;
    font: "JetBrains Mono Nerd Font 12";
    drun-display-format: "{name}";
}

* {
    background-color: #282a36;
    border-color:     #bd93f9;
    text-color:       #f8f8f2;
    font:             "JetBrains Mono Nerd Font 12";
}

window {
    width: 30%;
    padding: 20px;
    border: 2px;
    border-radius: 10px;
    border-color: @border-color;
    background-color: @background-color;
}

mainbox {
    children: [ inputbar, listview ];
    spacing: 15px;
    padding: 10px;
}

inputbar {
    children: [ prompt, entry ];
    padding: 8px;
    border-radius: 8px;
    background-color: #44475a;
    text-color: #f8f8f2;
}

prompt {
    enabled: true;
    padding: 0 10px 0 5px;
    background-color: inherit;
    text-color: #50fa7b; /* Green */
}

entry {
    background-color: inherit;
    placeholder: "Search...";
    placeholder-color: #6272a4; /* Comment */
}

listview {
    lines: 8;
    columns: 1;
    cycle: true;
    dynamic: true;
    layout: vertical;
}

element {
    padding: 8px;
    border-radius: 8px;
    orientation: horizontal;
}

element-icon {
    size: 24px;
    padding: 0 15px 0 0;
}

element-text {
    vertical-align: 0.5;
}

element.normal.normal {
    background-color: @background-color;
    text-color: @text-color;
}

element.normal.urgent {
    background-color: #ff5555; /* Red */
    text-color: @text-color;
}

element.normal.active {
    background-color: #ff79c6; /* Pink */
    text-color: @text-color;
}

element.selected.normal {
    background-color: #44475a; /* Comment */
    text-color: @border-color; /* Purple */
}

element.selected.urgent {
    background-color: #ff5555; /* Red */
    text-color: @text-color;
}

element.selected.active {
    background-color: $ACCENT_COLOR_HEX; /* User's Accent Color */
    text-color: #282a36; /* BG Color */
}
EOF

# --- Kitty Config (~/.config/kitty/kitty.conf) ---
echo "Generating Kitty config..."
cat > ~/.config/kitty/kitty.conf <<EOF
# Dracula theme for Kitty
include current-theme.conf

# Fonts
font_family      JetBrains Mono Nerd Font
bold_font        auto
italic_font      auto
bold_italic_font auto
font_size 11.0

# Window
background_opacity 0.85
EOF
# Download Dracula theme for Kitty
curl -s -o ~/.config/kitty/current-theme.conf https://raw.githubusercontent.com/dexpota/kitty-themes/master/themes/Dracula.conf


# --- GTK & Qt Theming ---
echo "Configuring GTK and Qt themes..."
# GTK3
cat > ~/.config/gtk-3.0/settings.ini <<EOF
[Settings]
gtk-theme-name=Dracula
gtk-icon-theme-name=Dracula
gtk-font-name=JetBrains Mono Nerd Font 11
gtk-cursor-theme-name=Dracula
EOF
# Symlink for GTK2
ln -sf ~/.config/gtk-3.0/settings.ini ~/.gtkrc-2.0

# Qt5/6
cat > ~/.config/qt5ct/qt5ct.conf <<EOF
[Appearance]
icon_theme=Dracula
style=kvantum

[General]
theme=Dracula
EOF
ln -sf ~/.config/qt5ct/qt5ct.conf ~/.config/qt6ct/qt6ct.conf

# Kvantum
cat > ~/.config/Kvantum/kvantum.kvconfig <<EOF
[General]
theme=Dracula
EOF


# --- Seatd Configuration ---
print_header "6. Configuring seatd for Autostart"
if ask_yes_no "Do you want to enable 'seatd' service for autostarting Hyprland?"; then
    echo "Adding user to 'seat' group..."
    sudo usermod -aG seat "$USER"
    echo "Enabling seatd service..."
    sudo systemctl enable seatd.service
    echo "'seatd' has been configured. A REBOOT is required for this to take effect."
else
    echo "Skipping seatd configuration. You will need to start Hyprland manually."
fi


# --- Final Steps ---
print_header "Setup Complete!"
echo "The Hyprland configuration is complete."
echo "Here are some important next steps:"
echo "1. A wallpaper has been linked, but you should place your desired wallpaper at '~/Pictures/wall.jpg' or edit the path in '~/.config/hypr/hyprland.conf'."
echo "2. A FULL REBOOT is absolutely required for the new theming environment variables to be loaded by the system."
echo "3. After rebooting, you should be able to select Hyprland from your login manager, or if you don't have one, it might start automatically from a TTY if seatd is configured."
echo "Enjoy your new, and hopefully correctly themed, Hyprland setup!"

