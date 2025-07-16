#!/bin/bash
#
# Complete Hyprland Installation Script
# This version incorporates the Dracula theming system and lightweight utilities.

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
echo " Hyprland Arch Linux Installation Script"
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
waybar_pos_choice=$(get_choice "${waybar_pos_options[@]}")
if [ "$waybar_pos_choice" -eq 2 ]; then
    waybar_position="bottom"
fi

# 3. Waybar Clock Format
clock_format=" {:%H:%M  %d/%m}"
clock_options=("Time and Date (Default)" "Time Only")
print_menu "Select Waybar Clock Format" clock_options
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

# 5. Default Applications & Dependencies
pacman_packages=(
    hyprland waybar rofi-wayland swaync qt5-wayland qt6-wayland qt5ct qt6ct kvantum swaylock swww archlinux-wallpaper
    git grim slurp swappy wl-clipboard noto-fonts noto-fonts-emoji ttf-font-awesome
    xdg-desktop-portal-hyprland polkit-kde-agent nwg-look jq seatd
    # Core dependencies for new features (lightweight alternatives)
    btop networkmanager network-manager-applet pavucontrol kio # kio is a Dolphin dependency
)
# Use the all-in-one theme package provided by the user
aur_packages=(
    wlogout
    full-dracula-theme-git
)

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

# --- Theme Configuration (Dracula) ---
echo
echo "🎨 Applying the Dracula theme for a flat, modern aesthetic."
ACCENT_COLOR="#bd93f9" # Dracula Purple
HYPR_ACCENT_COLOR="bd93f9"
HYPR_GRADIENT_COLOR="8be9fd" # Dracula Cyan

# 7. Wallpaper Selection
WALLPAPER_PATH=""
wallpaper_dir_user="$HOME/Pictures/wallpapers"
wallpaper_dir_system="/usr/share/backgrounds"
wallpaper_options=()

mkdir -p "$wallpaper_dir_user"

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
echo " Theme: Dracula"
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
sudo pacman -Syu --needed --noconfirm "${pacman_packages[@]}"
yay -S --needed --noconfirm "${aur_packages[@]}"

# --- Seatd User Group and Service Setup ---
CURRENT_USER=$(whoami)
echo "Adding user '$CURRENT_USER' to the 'seat' and 'video' groups for seatd..."
sudo usermod -aG seat "$CURRENT_USER"
sudo usermod -aG video "$CURRENT_USER"

echo "Enabling the seatd service..."
sudo systemctl enable seatd.service

# --- Configuration Directory Creation ---
echo "Creating configuration directories..."
mkdir -p ~/.config/hypr
mkdir -p ~/.config/waybar
mkdir -p ~/.config/rofi
mkdir -p ~/.config/swaync
mkdir -p ~/.config/Kvantum
mkdir -p ~/.config/wlogout
mkdir -p ~/.config/qt5ct
mkdir -p ~/.config/qt6ct
mkdir -p ~/.config/gtk-3.0
mkdir -p ~/.config/gtk-4.0

# --- Hyprland Configuration ---
echo "Creating hyprland.conf..."
cat <<EOF > ~/.config/hypr/hyprland.conf
# -----------------------------------------------------
# Hyprland Config (Dracula Theme)
# -----------------------------------------------------

# --- Monitor Configuration ---
${MONITOR_CONFIG:-monitor=,preferred,auto,1}

# --- Autostart Programs ---
exec-once = ~/.config/hypr/autostart.sh

# --- Environment Variables ---
env = XCURSOR_SIZE,24
env = GTK_THEME,Dracula
env = QT_QPA_PLATFORMTHEME,qt5ct
env = QT_STYLE_OVERRIDE,kvantum
env = XDG_CURRENT_DESKTOP,KDE

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
    col.active_border = rgba(${HYPR_ACCENT_COLOR}ee) rgba(${HYPR_GRADIENT_COLOR}ee) 45deg
    col.inactive_border = rgba(44475aaa)
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
        xray = true
        noise = 0.0117
        contrast = 0.8916
        brightness = 0.8172
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
windowrulev2 = float, class:^(kcalc|${FM_CMD}|qt5ct|qt6ct|nwg-look|wlogout|pavucontrol|nm-connection-editor)$
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

# --- Autostart Script Creation ---
echo "Creating autostart.sh..."
cat <<EOF > ~/.config/hypr/autostart.sh
#!/bin/bash

# A small delay to ensure services are ready
sleep 1

# Start key daemons in the background
/usr/lib/polkit-kde-authentication-agent-1 &
waybar &
swaync &
swww init &

# Set wallpaper after a short delay
(sleep 2 && ${WALLPAPER_PATH:+swww img "${WALLPAPER_PATH}" --transition-type any}) &
EOF

# Make the script executable
chmod +x ~/.config/hypr/autostart.sh

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
        "tooltip": true,
        "on-click": "$TERM_CMD -e btop"
    },
    "memory": {
        "format": " {}%",
        "on-click": "$TERM_CMD -e btop"
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
    background-color: rgba(40, 42, 54, 0.85); /* Dracula BG with transparency */
    color: #f8f8f2; /* Dracula FG */
    border: 2px solid $ACCENT_COLOR;
    border-radius: 15px;
}

#workspaces button.active {
    background: $ACCENT_COLOR;
    color: #282a36; /* Dracula BG for contrast */
}

#workspaces button {
    padding: 0 10px;
    background: transparent;
    color: #f8f8f2;
    border-radius: 10px;
}

#workspaces button:hover {
    background: #44475a; /* Dracula Selection */
}

#window, #clock, #cpu, #memory, #pulseaudio, #network, #tray, #battery {
    padding: 0 10px;
    margin: 5px;
    background-color: #44475a; /* Dracula Selection */
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
    /* Dracula */
    bg: #282a36;
    bg-alt: #44475a;
    fg: #f8f8f2;
    accent: $ACCENT_COLOR;

    background-color: transparent;
    text-color: @fg;
}

window {
    background-color: rgba(40, 42, 54, 0.9); /* bg with transparency */
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
    background-color: rgba(40, 42, 54, 0.9); /* Dracula BG with transparency */
    font-family: Noto Sans;
    font-size: 16pt;
    color: #f8f8f2; /* Dracula FG */
}

button {
    background-color: #44475a; /* Dracula Selection */
    color: #f8f8f2;
    border: 2px solid #282a36; /* Dracula BG */
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
GTK_THEME="Dracula"
KVANTUM_THEME="Dracula" # This name should be provided by the new package
ICON_THEME="Dracula"    # This name should be provided by the new package
CURSOR_THEME="Dracula"  # This name should be provided by the new package
FONT="Noto Sans 11"

# GTK3 settings
cat <<EOF > ~/.config/gtk-3.0/settings.ini
[Settings]
gtk-theme-name=$GTK_THEME
gtk-icon-theme-name=$ICON_THEME
gtk-cursor-theme-name=$CURSOR_THEME
gtk-font-name=$FONT
EOF

# Create symlink for GTK4 to use GTK3 settings
ln -sf ~/.config/gtk-3.0/settings.ini ~/.config/gtk-4.0/settings.ini

# QT5/6 settings
cat <<EOF > ~/.config/qt5ct/qt5ct.conf
[Appearance]
icon_theme=$ICON_THEME
style=kvantum

[Fonts]
general=@Noto Sans,11,-1,5,50,0,0,0,0,0
EOF
ln -sf ~/.config/qt5ct/qt5ct.conf ~/.config/qt6ct/qt6ct.conf

# Kvantum settings
cat <<EOF > ~/.config/Kvantum/kvantum.kvconfig
[General]
theme=$KVANTUM_THEME
EOF

# --- KDE/Qt Application-Specific Theming ---
echo "Applying Dracula theme to Konsole and Kate for a cohesive look..."

# Create directories for custom themes and profiles
mkdir -p ~/.local/share/konsole/
mkdir -p ~/.local/share/org.kde.syntax-highlighting/themes/

# 1. Konsole Theming (Terminal Area)
# Create the Dracula color scheme file
cat <<'EOF' > ~/.local/share/konsole/Dracula.colorscheme
[Color]
Name=Dracula
[General]
Description=Dracula Theme
[Background]
Color=40,42,54
[Foreground]
Color=248,248,242
[Color0]
Color=0,0,0
[Color0Intense]
Color=98,114,164
[Color1]
Color=255,85,85
[Color1Intense]
Color=255,102,102
[Color2]
Color=80,250,123
[Color2Intense]
Color=97,255,139
[Color3]
Color=241,250,140
[Color3Intense]
Color=244,255,157
[Color4]
Color=189,147,249
[Color4Intense]
Color=198,160,255
[Color5]
Color=255,121,198
[Color5Intense]
Color=255,138,206
[Color6]
Color=139,233,253
[Color6Intense]
Color=155,239,255
[Color7]
Color=191,191,191
[Color7Intense]
Color=255,255,255
EOF

# Create a Konsole profile that uses the Dracula color scheme
cat <<'EOF' > ~/.local/share/konsole/Dracula.profile
[Appearance]
ColorScheme=Dracula
[General]
Name=Dracula
Parent=FALLBACK/
EOF

# Set Dracula as the default profile in a minimal konsolerc
cat <<EOF > ~/.config/konsolerc
[Desktop Entry]
DefaultProfile=Dracula.profile
EOF

# 2. Kate Theming (Editor Area)
# Create the Dracula syntax highlighting theme file (minified JSON)
cat <<'EOF' > ~/.local/share/org.kde.syntax-highlighting/themes/Dracula.theme
{"metadata":{"name":"Dracula","revision":1},"text-styles":{"Normal":{"text-color":"#f8f8f2"},"Keyword":{"text-color":"#ff79c6","bold":true},"Function":{"text-color":"#50fa7b"},"Variable":{"text-color":"#8be9fd","italic":true},"ControlFlow":{"text-color":"#ff79c6","bold":true},"Operator":{"text-color":"#ff79c6"},"BuiltIn":{"text-color":"#8be9fd","italic":true},"Extension":{},"Preprocessor":{"text-color":"#50fa7b"},"Attribute":{"text-color":"#50fa7b"},"Char":{"text-color":"#f1fa8c"},"SpecialChar":{"text-color":"#f1fa8c"},"String":{"text-color":"#f1fa8c"},"VerbatimString":{"text-color":"#f1fa8c"},"SpecialString":{"text-color":"#f1fa8c"},"Import":{},"DataType":{"text-color":"#8be9fd","italic":true},"Decimal":{"text-color":"#bd93f9"},"BaseN":{"text-color":"#bd93f9"},"Float":{"text-color":"#bd93f9"},"Constant":{"text-color":"#8be9fd","italic":true},"Comment":{"text-color":"#6272a4"},"Documentation":{"text-color":"#6272a4"},"Annotation":{"text-color":"#f1fa8c"},"CommentVar":{"text-color":"#8be9fd","italic":true},"RegionMarker":{"text-color":"#f1fa8c"},"Information":{"text-color":"#6272a4"},"Warning":{"text-color":"#f1fa8c"},"Alert":{"text-color":"#ffb86c","background-color":"#6272a4","bold":true},"Error":{"text-color":"#ff5555","underline":true},"Others":{}},"editor-colors":{"BackgroundColor":"#282a36","CodeFolding":"#6272a4","BracketMatching":"#6272a4","CurrentLine":"#44475a","IconBorder":"#44475a","IndentationLine":"#44475a","LineNumbers":"#6272a4","MarkBookmark":"#ff79c6","MarkError":"#ff5555","MarkWarning":"#f1fa8c","ModifiedLines":"#ffb86c","ReplaceHighlight":"#ffb86c","SavedLines":"#50fa7b","SearchHighlight":"#ffb86c","Separator":"#44475a","SpellChecking":"#ff5555","TabMarker":"#44475a","TemplateBackground":"#44475a","TemplatePlaceholder":"#bd93f9","TemplateFocusedPlaceholder":"#ff79c6","WordWrapMarker":"#44475a"}}
EOF

# Set Dracula as the default scheme in a minimal katerc
cat <<EOF > ~/.config/katerc
[General]
Color Theme=Dracula
EOF


# --- Autostart Configuration ---
read -p "Do you want to enable automatic login and startup of Hyprland (bypassing a login manager)? (y/N): " autostart_confirm
if [[ "$autostart_confirm" == [yY] ]]; then

    ### Create the single, all-in-one systemd service for autostart ###
    echo "Creating final systemd service for direct autostart..."
    AUTOLOGIN_SERVICE_FILE="/etc/systemd/system/hyprland-autologin@.service"

    cat <<EOF | sudo tee $AUTOLOGIN_SERVICE_FILE > /dev/null
[Unit]
Description=Directly starts Hyprland for user %i
After=systemd-user-sessions.service seatd.service

[Service]
User=%i
WorkingDirectory=/home/%i
# This directive creates a full login session, providing Hyprland
# with graphics, input, and basic environment variables.
PAMName=login
# Explicitly pass the config file to Hyprland to remove any ambiguity.
ExecStart=/usr/bin/Hyprland --config /home/%i/.config/hypr/hyprland.conf
Restart=always
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    ### Enable the new service and remove all traces of the old methods ###
    echo "Disabling conflicting services and enabling the new direct autostart service..."

    # Disable the standard TTY login to prevent conflicts
    sudo systemctl disable getty@tty1.service

    # Enable the new, single service
    sudo systemctl enable "hyprland-autologin@$CURRENT_USER.service"

    # Remove any old, problematic commands from .bash_profile, just in case.
    sed -i "/graphical-session.target/d" "$HOME/.bash_profile" 2>/dev/null || true

    echo
    echo "Autostart configured with the final, direct PAM-based systemd method."
fi


# --- Final Instructions ---
echo
echo "------------------------------------------------------"
echo " ✅ Installation Complete!"
echo "------------------------------------------------------"
echo "All configurations have been generated based on your choices."
echo
echo "The system has been configured to use 'seatd' for device management."
echo "A FULL REBOOT IS REQUIRED for all changes to take effect."
echo
echo "Please run 'sudo reboot' now."
