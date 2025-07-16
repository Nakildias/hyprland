#!/bin/bash
#
# minimal_test.sh
# A script to test the most basic Hyprland autostart functionality.
# This script will:
# 1. Install only Hyprland and the Kitty terminal.
# 2. Create a minimal, one-line hyprland.conf.
# 3. Set up a single systemd service to autostart Hyprland.

# Abort on any error
set -e

echo "--- Hyprland Minimal Autostart Test ---"
echo
echo "This script will install a minimal Hyprland setup to test the autostart service."
read -p "Do you want to proceed? (y/N): " final_confirm
if [[ "$final_confirm" != [yY] ]]; then
    echo "Installation aborted."
    exit 0
fi

# --- 1. Package Installation ---
echo "Installing Hyprland and Kitty..."
sudo pacman -Syu --needed --noconfirm hyprland kitty

# --- 2. Minimal Configuration ---
echo "Creating minimal Hyprland configuration..."
mkdir -p ~/.config/hypr
cat <<EOF > ~/.config/hypr/hyprland.conf
# --- Minimal Hyprland Config for Debugging ---
# This file contains the absolute bare minimum to test if Hyprland can start.
# It only binds Super + Enter to open the kitty terminal.

\$mainMod = SUPER
bind = \$mainMod, RETURN, exec, kitty
EOF
echo "Minimal hyprland.conf created."

# --- 3. Autostart Service Setup ---
echo "Setting up the final, direct systemd autostart service..."
CURRENT_USER=$(whoami)
AUTOLOGIN_SERVICE_FILE="/etc/systemd/system/hyprland-autologin@.service"

# Create the single, all-in-one systemd service for autostart
cat <<EOF | sudo tee $AUTOLOGIN_SERVICE_FILE > /dev/null
[Unit]
Description=Directly starts Hyprland for user %i
After=systemd-user-sessions.service

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

# Enable the new service and remove all traces of the old methods
echo "Disabling conflicting services and enabling the new direct autostart service..."

# Disable the standard TTY login to prevent conflicts
sudo systemctl disable getty@tty1.service

# Enable the new, single service
sudo systemctl enable "hyprland-autologin@$CURRENT_USER.service"

# Remove any old, problematic commands from .bash_profile, just in case.
sed -i "/graphical-session.target/d" "$HOME/.bash_profile" 2>/dev/null || true

echo
echo "------------------------------------------------------"
echo " Minimal Test Setup Complete!"
echo "------------------------------------------------------"
echo "Please reboot your system now."
echo
echo "After rebooting, look for one of two outcomes:"
echo "  - SUCCESS: You see a black screen with a mouse cursor. Press Super+Enter. If a terminal appears, the test worked!"
echo "  - FAILURE: You are returned to the login prompt. If so, the issue is likely a driver or hardware incompatibility."
echo
