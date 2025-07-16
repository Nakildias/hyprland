#!/bin/bash

################################################################################
#                                                                              #
#                    DESKTOP ENVIRONMENT ANNIHILATOR SCRIPT                      #
#                                                                              #
#   !!!!!!!!!!!!!!!!!!!!!!!!!!  D A N G E R  !!!!!!!!!!!!!!!!!!!!!!!!!!         #
#                                                                              #
#   This script is designed to be EXTREMELY DESTRUCTIVE. It will attempt to    #
#   remove all major desktop environments and their associated configurations  #
#   from your Arch Linux system.                                               #
#                                                                              #
#   >>> RUNNING THIS WILL BREAK YOUR GRAPHICAL USER INTERFACE. <<<             #
#   >>> YOU WILL BE LEFT WITH A COMMAND-LINE ONLY SYSTEM (TTY). <<<            #
#   >>> THERE IS NO UNDO BUTTON. ALL YOUR DE SETTINGS WILL BE GONE. <<<        #
#                                                                              #
#   ** BACK UP YOUR DATA BEFORE PROCEEDING. YOU HAVE BEEN WARNED. ** #
#                                                                              #
################################################################################

# --- Helper Functions ---

# Function to print a separator line
print_separator() {
    echo "======================================================================"
}

# Function to print a header for a section
print_header() {
    print_separator
    echo "    $1"
    print_separator
}

# Function to ask a yes/no question in a loop
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

# --- Initial Sanity Checks ---

if [ "$(id -u)" -eq 0 ]; then
  echo "DO NOT RUN THIS SCRIPT AS ROOT!"
  echo "You will be prompted for your password when necessary for package removal."
  exit 1
fi

print_header "!! FINAL WARNING !!"
echo "This script will permanently remove desktop environments and their configs."
echo "You must be prepared to work from a command-line interface afterwards."
echo "Ensure you have a backup of all important files in your home directory."
if ! ask_yes_no "Are you absolutely sure you want to continue?"; then
    echo "Aborting script. No changes were made."
    exit 0
fi


# --- Define Desktop Environments and their components ---

# Package groups for each DE
declare -A de_packages
de_packages["GNOME"]="gnome gnome-extra"
de_packages["KDE Plasma"]="plasma-meta kde-applications-meta"
de_packages["XFCE"]="xfce4 xfce4-goodies"
de_packages["Cinnamon"]="cinnamon"
de_packages["MATE"]="mate mate-extra"
de_packages["LXQt"]="lxqt"
de_packages["Budgie"]="budgie-desktop"

# Configuration files and directories for each DE
declare -A de_configs
de_configs["GNOME"]="
~/.config/dconf
~/.config/gnome-session
~/.config/gnome-shell
~/.config/nautilus
~/.local/share/gnome-shell
~/.local/share/gnome-background-properties
~/.cache/gnome-software
"
de_configs["KDE Plasma"]="
~/.config/plasma*
~/.config/k*
~/.local/share/plasma
~/.local/share/k*
~/.cache/k*
"
de_configs["XFCE"]="
~/.config/xfce4
~/.cache/xfce4
"
de_configs["Cinnamon"]="
~/.config/cinnamon
~/.cinnamon
"
de_configs["MATE"]="
~/.config/mate
~/.config/mate-session
~/.cache/mate
"
de_configs["LXQt"]="
~/.config/lxqt
~/.config/pcmanfm-qt
"
de_configs["Budgie"]="
~/.config/budgie-desktop
"


# --- Removal Process ---

# Function to check if a package is installed
is_installed() {
    pacman -Q "$1" &> /dev/null
}

# Loop through each defined Desktop Environment
for de in "${!de_packages[@]}"; do
    print_header "Checking for $de"
    
    detected=false
    # Check if any package from the group is installed
    for pkg_group in ${de_packages[$de]}; do
        if is_installed "$pkg_group"; then
            echo "Detected $de package group: $pkg_group"
            detected=true
            break
        fi
    done

    if [ "$detected" = true ]; then
        # --- Package Removal ---
        if ask_yes_no "Do you want to remove all $de packages?"; then
            echo "Preparing to remove $de packages. You will be prompted for your password."
            # The -c flag cascades the removal to dependencies. -s is for recursive. -n saves .pacnew files.
            sudo pacman -Rscn ${de_packages[$de]} --noconfirm
            echo "$de packages have been removed."
        else
            echo "Skipping package removal for $de."
        fi

        # --- Configuration Removal ---
        if ask_yes_no "Do you want to DELETE all $de user configuration files?"; then
            echo "Deleting configuration files for $de..."
            for config_path in ${de_configs[$de]}; do
                # Expand the tilde to the user's home directory
                expanded_path=$(eval echo "$config_path")
                if [ -e "$expanded_path" ]; then
                    echo "Removing $expanded_path"
                    rm -rf "$expanded_path"
                else
                    echo "Path not found, skipping: $expanded_path"
                fi
            done
            echo "$de configuration files have been deleted."
        else
            echo "Skipping configuration removal for $de."
        fi
    else
        echo "$de not detected on this system."
    fi
done

print_header "Annihilation Complete"
echo "The script has finished."
echo "It is highly recommended to REBOOT your system now."
echo "After rebooting, you will likely be in a command-line only (TTY) environment."
echo "From there, you can install a new desktop environment or window manager."

