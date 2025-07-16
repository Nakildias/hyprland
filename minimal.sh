#!/bin/bash
#
# minimal_test.sh (v2 - with seatd)
# A script to test the most basic Hyprland autostart functionality using seatd.
# This script will:
# 1. Install Hyprland, Kitty, and seatd.
# 2. Add the user to the 'seat' and 'video' groups.
# 3. Enable the seatd service.
# 4. Create a minimal hyprland.conf.
# 5. Set up a single systemd service to autostart Hyprland.

# Abort on any error
set -e

echo "--- Hyprland Minimal Autostart Test (with seatd) ---"
echo
echo "Previous tests failed, indicating a driver/permission issue with systemd-logind."
echo "This final test will install and configure 'seatd' to manage device permissions."
read -p "Do you want to proceed with this final attempt? (y/N): " final_confirm
if [[ "$final_confirm" != [yY] ]]; then
    echo "Installation aborted."
    exit 0
fi

# --- 1. Package Installation ---
echo "Installing Hyprland, Kitty, and seatd..."
sudo pacman -Syu --needed --noconfirm hyprland kitty seatd

# --- 2. User Group and Service Setup ---
CURRENT_USER=$(whoami)
echo "Adding user '$CURRENT_USER' to the 'seat' and 'video' groups..."
sudo usermod -aG seat "$CURRENT_USER"
sudo usermod -aG video "$CURRENT_USER"

echo "Enabling the seatd service..."
sudo systemctl enable seatd.service

# --- 3. Minimal Configuration ---
echo "Creating minimal Hyprland configuration..."
mkdir -p ~/.config/hypr
cat <<EOF > ~/.config/hypr/hyprland.conf
# --- Minimal Hyprland Config for Debugging ---
# It only binds Super + Enter to open the kitty terminal.

\$mainMod = SUPER
bind = \$mainMod, RETURN, exec, kitty
EOF
echo "Minimal hyprland.conf created."

# --- 4. Autostart Service Setup ---
echo "Setting up the final, direct systemd autostart service..."
AUTOLOGIN_SERVICE_FILE="/etc/systemd/system/hyprland-autologin@.service"

# Create the single, all-in-one systemd service for autostart
cat <<EOF | sudo tee $AUTOLOGIN_SERVICE_FILE > /dev/null
[Unit]
Description=Directly starts Hyprland for user %i
After=systemd-user-sessions.service seatd.service

[Service]
User=%i
WorkingDirectory=/home/%i
# This directive creates a full login session.
PAMName=login
# Explicitly pass the config file to Hyprland to remove any ambiguity.
ExecStart=/usr/bin/Hyprland --config /home/%i/.config/hypr/hyprland.conf
Restart=always
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Enable the new service and disable conflicting ones
echo "Disabling conflicting services and enabling the new direct autostart service..."
sudo systemctl disable getty@tty1.service
sudo systemctl enable "hyprland-autologin@$CURRENT_USER.service"

echo
echo "------------------------------------------------------"
echo " Final Test Setup Complete!"
echo "------------------------------------------------------"
echo "The system has been configured to use 'seatd' for device management."
echo "A FULL REBOOT IS REQUIRED for the group changes to take effect."
echo
echo "Please run 'sudo reboot' now."
echo
echo "If this fails, the issue is a deep hardware/driver incompatibility."
echo
