#!/bin/bash
# install.sh
# This script automates the setup and customization of an i3-wm environment
# on Arch Linux or Linux Mint, including Polybar, Kitty, Picom,
# and themes (Catppuccin/Rosé Pine).

# OS Detection
OS_TYPE=""
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "$ID" == "arch" ]] || [[ "$ID_LIKE" == "arch" ]]; then
        OS_TYPE="arch"
    elif [[ "$ID" == "linuxmint" ]] || [[ "$ID_LIKE" == "linuxmint" ]]; then
        OS_TYPE="mint"
    fi
fi

if [ -z "$OS_TYPE" ]; then
    echo "Error: Unsupported operating system." >&2
    echo "This script supports Arch Linux and Linux Mint." >&2
    exit 1
else
    echo "Detected OS: $OS_TYPE"
fi

# Package lists
arch_essential_packages=(git i3-wm polybar kitty picom base-devel)
mint_essential_packages=(git i3 polybar kitty picom build-essential curl unzip)
# Note: papirus-icon-theme and gnome-themes-* are handled separately later

echo "Starting Linux i3 Customization Script for Arch Linux / Linux Mint..."

# Basic error handling: exit immediately if a command exits with a non-zero status.
set -e

echo "---------------------------------------------------------------------"
echo "Linux i3 Customization Script (Arch/Mint) by Jules"
echo "---------------------------------------------------------------------"
echo "This script supports Arch Linux and Linux Mint."
echo "It will:"
echo "1. Update your system and install essential packages (i3, Polybar, Kitty, Picom)."
echo "   (Manages 'yay' for Arch Linux users automatically)."
echo "2. Download Catppuccin and Rosé Pine theme source files."
echo "3. Configure Polybar, Kitty, Picom, and i3 with Catppuccin Mocha defaults."
echo "4. Configure GTK2/3 themes, icons, and cursors to Catppuccin Mocha."
echo "5. Install Fira Code Nerd Font for proper icon display."
echo ""
echo "Default theme: Catppuccin Mocha."
echo "You can manually change to other Catppuccin flavors or Rosé Pine"
echo "by editing the respective configuration copying sections in this script"
echo "or by manually copying files from the ~/.themes-src directory after installation."
echo "---------------------------------------------------------------------"
echo "IMPORTANT: This script will use 'sudo' for package installations."
echo "It is recommended to run this script as your regular user."
echo "You will be prompted for your password when 'sudo' is called."
echo "Ensure you have necessary build tools (base-devel for Arch, build-essential for Mint - which are installed by this script)."
echo "For Arch Linux, 'yay' (AUR helper) will be installed if not present."
echo "For additional AUR packages on Arch, use 'yay'."
echo "For Linux Mint, you may need to find PPAs or .deb packages for software not in standard repositories."
echo "---------------------------------------------------------------------"
# Simple prompt to continue
# read -p "Press Enter to continue, or Ctrl+C to abort."
# For non-interactive execution, we'll comment out the read, but it's good for manual runs.

# Determine home directory of the user executing the script (even if via sudo)
if [ -n "$SUDO_USER" ]; then
    USER_HOME_DIR=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    USER_HOME_DIR="$HOME"
fi
CONFIG_DIR="$USER_HOME_DIR/.config"
THEME_SRC_DIR="$USER_HOME_DIR/.themes-src" # Used for theme sources

echo "User home directory set to: $USER_HOME_DIR"
echo "Config directory set to: $CONFIG_DIR"
echo "Theme source directory set to: $THEME_SRC_DIR"

# Ensure .config directory exists
mkdir -p "$CONFIG_DIR"

# (Further script content will be added in subsequent steps)

if [ "$OS_TYPE" == "arch" ]; then
    echo "Updating Arch Linux system packages..."
    sudo pacman -Syu --noconfirm
    echo "Installing essential packages for Arch Linux: ${arch_essential_packages[*]}..."
    sudo pacman -S --noconfirm --needed "${arch_essential_packages[@]}"
elif [ "$OS_TYPE" == "mint" ]; then
    echo "Updating Linux Mint system packages..."
    sudo apt-get update -y
    echo "Installing essential packages for Linux Mint: ${mint_essential_packages[*]}..."
    sudo apt-get install -y "${mint_essential_packages[@]}"
fi

if [ "$OS_TYPE" == "arch" ]; then
    # Check and install yay (AUR helper)
    echo "Checking for yay AUR helper..."
    if ! command -v yay &> /dev/null
    then
        echo "yay not found. Installing yay..."
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        (cd /tmp/yay && makepkg -si --noconfirm)
        rm -rf /tmp/yay
        echo "yay installed successfully."
    else
        echo "yay is already installed."
    fi
else
    echo "Skipping yay (AUR helper) installation for $OS_TYPE."
fi

echo "Creating directories for theme source files..."
mkdir -p "$THEME_SRC_DIR/catppuccin"
mkdir -p "$THEME_SRC_DIR/rose-pine"

echo "Cloning Catppuccin themes..."
git clone --depth 1 https://github.com/catppuccin/polybar.git "$THEME_SRC_DIR/catppuccin/polybar"
git clone --depth 1 https://github.com/catppuccin/kitty.git "$THEME_SRC_DIR/catppuccin/kitty"
git clone --depth 1 https://github.com/catppuccin/gtk.git "$THEME_SRC_DIR/catppuccin/gtk"
git clone --depth 1 https://github.com/catppuccin/icons.git "$THEME_SRC_DIR/catppuccin/icons"
git clone --depth 1 https://github.com/catppuccin/papirus-folders.git "$THEME_SRC_DIR/catppuccin/papirus-folders"

echo "Cloning Rosé Pine themes..."
git clone --depth 1 https://github.com/rose-pine/polybar.git "$THEME_SRC_DIR/rose-pine/polybar"
git clone --depth 1 https://github.com/rose-pine/kitty.git "$THEME_SRC_DIR/rose-pine/kitty"
git clone --depth 1 https://github.com/rose-pine/gtk-theme.git "$THEME_SRC_DIR/rose-pine/gtk"
git clone --depth 1 https://github.com/rose-pine/icons.git "$THEME_SRC_DIR/rose-pine/icons"

echo "Themes downloaded."

echo "Configuring Polybar..."
POLYBAR_DIR="$CONFIG_DIR/polybar"
mkdir -p "$POLYBAR_DIR"

# Backup existing Polybar config
if [ -f "$POLYBAR_DIR/config.ini" ]; then
    echo "Backing up existing Polybar config to $POLYBAR_DIR/config.ini.backup"
    mv "$POLYBAR_DIR/config.ini" "$POLYBAR_DIR/config.ini.backup.$(date +%Y%m%d-%H%M%S)"
fi
if [ -f "$POLYBAR_DIR/launch.sh" ]; then
    echo "Backing up existing Polybar launch.sh to $POLYBAR_DIR/launch.sh.backup"
    mv "$POLYBAR_DIR/launch.sh" "$POLYBAR_DIR/launch.sh.backup.$(date +%Y%m%d-%H%M%S)"
fi

echo "Copying Catppuccin Mocha Polybar theme..."
# Assuming Catppuccin themes are cloned into $THEME_SRC_DIR/catppuccin/polybar
# The Catppuccin Polybar repo has different .ini files for flavors in its root.
# We'll use 'mocha.ini' and rename it to 'config.ini' for Polybar.
if [ -f "$THEME_SRC_DIR/catppuccin/polybar/mocha.ini" ]; then
    cp "$THEME_SRC_DIR/catppuccin/polybar/mocha.ini" "$POLYBAR_DIR/config.ini"
else
    echo "ERROR: Catppuccin Mocha Polybar theme file not found at $THEME_SRC_DIR/catppuccin/polybar/mocha.ini"
    # Potentially clone it if it's missing, or error out
    echo "Attempting to clone Catppuccin Polybar if missing..."
    git clone --depth 1 https://github.com/catppuccin/polybar.git "$THEME_SRC_DIR/catppuccin/polybar_temp"
    if [ -f "$THEME_SRC_DIR/catppuccin/polybar_temp/mocha.ini" ]; then
        cp "$THEME_SRC_DIR/catppuccin/polybar_temp/mocha.ini" "$POLYBAR_DIR/config.ini"
        rm -rf "$THEME_SRC_DIR/catppuccin/polybar_temp" # Clean up
    else
        echo "CRITICAL ERROR: Could not find or download Catppuccin Polybar theme. Please check paths and internet."
        exit 1
    fi
fi

echo "Creating Polybar launch script..."
cat << EOF > "$POLYBAR_DIR/launch.sh"
#!/bin/bash

# Terminate already running bar instances
killall -q polybar
# If all your bars have ipc enabled, you can also use
# polybar-msg cmd quit

# Wait until the processes have been shut down
while pgrep -u \$UID -x polybar >/dev/null; do sleep 1; done

# Launch Polybar, using default config location ~/.config/polybar/config.ini
polybar example &

echo "Polybar launched..."
EOF
# Make the launch script executable
chmod +x "$POLYBAR_DIR/launch.sh"

# Chown the config files to the user, in case script was run with sudo for pacman commands
echo "Setting ownership of Polybar configs to $SUDO_USER..."
chown -R "$SUDO_USER:$SUDO_USER" "$POLYBAR_DIR" || echo "chown for Polybar failed, possibly no SUDO_USER or already correct."


echo "Polybar configuration complete. You may need to adjust the 'example' bar name in launch.sh and config.ini."

echo "Configuring Kitty terminal..."
KITTY_DIR="$CONFIG_DIR/kitty"
mkdir -p "$KITTY_DIR"

# Backup existing Kitty config
if [ -f "$KITTY_DIR/kitty.conf" ]; then
    echo "Backing up existing Kitty config to $KITTY_DIR/kitty.conf.backup"
    mv "$KITTY_DIR/kitty.conf" "$KITTY_DIR/kitty.conf.backup.$(date +%Y%m%d-%H%M%S)"
fi

echo "Copying Catppuccin Mocha Kitty theme..."
# Catppuccin Kitty themes are usually in $THEME_SRC_DIR/catppuccin/kitty/themes (e.g., Catppuccin-Mocha.conf)
# The main repo $THEME_SRC_DIR/catppuccin/kitty also has .conf files like mocha.conf
# Let's check for mocha.conf in the root of the cloned kitty theme repo first.
CATPPUCCIN_KITTY_THEME_PATH="$THEME_SRC_DIR/catppuccin/kitty/mocha.conf"

if [ -f "$CATPPUCCIN_KITTY_THEME_PATH" ]; then
    cp "$CATPPUCCIN_KITTY_THEME_PATH" "$KITTY_DIR/kitty.conf"
else
    echo "ERROR: Catppuccin Mocha Kitty theme file not found at $CATPPUCCIN_KITTY_THEME_PATH"
    echo "Attempting to clone Catppuccin Kitty if missing..."
    # Fallback: try to clone the repo again if it was missed or path is wrong
    rm -rf "$THEME_SRC_DIR/catppuccin/kitty_temp" # Clean previous temp if any
    git clone --depth 1 https://github.com/catppuccin/kitty.git "$THEME_SRC_DIR/catppuccin/kitty_temp"
    if [ -f "$THEME_SRC_DIR/catppuccin/kitty_temp/mocha.conf" ]; then
        cp "$THEME_SRC_DIR/catppuccin/kitty_temp/mocha.conf" "$KITTY_DIR/kitty.conf"
        rm -rf "$THEME_SRC_DIR/catppuccin/kitty_temp" # Clean up
    else
        echo "CRITICAL ERROR: Could not find or download Catppuccin Kitty theme. Please check paths and internet."
        # Not exiting here, as terminal is critical but base functionality might still be wanted.
        echo "Kitty configuration will be skipped."
    fi
fi

# Ensure correct ownership
if [ -n "$SUDO_USER" ] && [ -d "$KITTY_DIR" ]; then
    echo "Setting ownership of Kitty configs to $SUDO_USER..."
    chown -R "$SUDO_USER:$(id -g $SUDO_USER)" "$KITTY_DIR" || echo "chown for Kitty failed, possibly already correct."
fi

echo "Kitty terminal configuration complete."

echo "Configuring Picom compositor..."
PICOM_DIR="$CONFIG_DIR/picom"
mkdir -p "$PICOM_DIR"

# Backup existing Picom config
if [ -f "$PICOM_DIR/picom.conf" ]; then
    echo "Backing up existing Picom config to $PICOM_DIR/picom.conf.backup"
    mv "$PICOM_DIR/picom.conf" "$PICOM_DIR/picom.conf.backup.$(date +%Y%m%d-%H%M%S)"
fi

echo "Creating a default Picom configuration..."
cat << EOF > "$PICOM_DIR/picom.conf"
# picom.conf
# Basic configuration for Picom

# Opacity
active-opacity = 1.0;
inactive-opacity = 0.9; # Slightly transparent for inactive windows
frame-opacity = 0.8;
inactive-opacity-override = false;
# Opacity for specific window types (optional)
# opacity-rule = [
#   "90:class_g = 'Kitty' && focused",
#   "80:class_g = 'Kitty' && !focused"
# ];

# Fading
fading = true;
fade-delta = 4; # Higher: faster fades
fade-in-step = 0.03;
fade-out-step = 0.03;
# no-fading-openclose = true; # Disable fading for opening/closing windows

# Shadows
shadow = true;
shadow-radius = 7;
shadow-offset-x = -7;
shadow-offset-y = -7;
shadow-opacity = 0.75;
shadow-exclude = [
  "name = 'Notification'",
  "class_g = 'Conky'",
  "class_g ?= 'Notify-osd'",
  "class_g = 'Cairo-clock'",
  "_GTK_FRAME_EXTENTS@:c"
];

# Backend (important: glx, xrender, xr_glx_hybrid)
# glx is generally preferred for performance if drivers support it well.
# xrender is a fallback.
backend = "glx"; 

# Other settings
vsync = true;            # Try true to reduce screen tearing. May increase latency.
mark-wmwin-focused = true;
mark-ovredir-focused = true;
detect-rounded-corners = true;
detect-client-opacity = true;
detect-transient = true;
glx-no-stencil = true;
glx-copy-from-front = false;
# glx-use-copysubbuffermesa = true; # If MESA_GLX_VERSION_MAJOR >= 1 && MESA_GLX_VERSION_MINOR >= 3
# glx-no-rebind-pixmap = true; # Might fix issues on some nvidia drivers

# Window type settings (example for i3 related windows)
wintypes:
{
  tooltip = { fade = true; shadow = true; opacity = 0.85; focus = true; full-shadow = false; };
  dock = { shadow = false; } # Polybar is a dock
  dnd = { shadow = false; }
  popup_menu = { opacity = 0.9; }
  dropdown_menu = { opacity = 0.9; }
};
EOF

# Ensure correct ownership
if [ -n "$SUDO_USER" ] && [ -d "$PICOM_DIR" ]; then
    echo "Setting ownership of Picom configs to $SUDO_USER..."
    chown -R "$SUDO_USER:$(id -g $SUDO_USER)" "$PICOM_DIR" || echo "chown for Picom failed, possibly already correct."
fi

echo "Picom compositor configuration complete."

echo "Configuring i3 Window Manager..."
I3_DIR="$CONFIG_DIR/i3"
mkdir -p "$I3_DIR"
I3_CONFIG_FILE="$I3_DIR/config"

# Backup existing i3 config
if [ -f "$I3_CONFIG_FILE" ]; then
    echo "Backing up existing i3 config to $I3_CONFIG_FILE.backup"
    cp "$I3_CONFIG_FILE" "$I3_CONFIG_FILE.backup.$(date +%Y%m%d-%H%M%S)"
else
    # If no config exists, create a minimal one to append to
    echo "No existing i3 config found. Creating a minimal one."
    touch "$I3_CONFIG_FILE" # Ensure file exists
    # It's better if i3 itself creates its default config first,
    # but for this script, we'll append to an empty or existing one.
    # A truly robust solution would be to copy the system default and modify that.
    # For now, this should work for appending.
fi

echo "Applying Catppuccin Mocha theme settings and startup applications to i3 config..."

# Prepare a temporary file for new i3 config settings
I3_NEW_SETTINGS_TMP="$(mktemp)"

# Catppuccin Mocha color definitions (adjust variable names as preferred)
# Full palette: Rosewater f5e0dc, Flamingo f2cdcd, Pink f5c2e7, Mauve cba6f7, Red f38ba8, Maroon eba0ac, Peach fab387, Yellow f9e2af, Green a6e3a1, Teal 94e2d5, Sky 89dceb, Sapphire 74c7ec, Blue 89b4fa, Lavender b4befe
# Text cdd6f4, Subtext1 bac2de, Subtext0 a6adc8, Overlay2 9399b2, Overlay1 7f849c, Overlay0 6c7086, Surface2 585b70, Surface1 45475a, Surface0 313244, Base 1e1e2e, Mantle 181825, Crust 11111b

cat << EOF > "$I3_NEW_SETTINGS_TMP"
# Catppuccin Mocha i3 Theme Settings
# Font (replace with your preferred Nerd Font if desired)
font pango:FiraCode Nerd Font Mono 10

# Catppuccin Mocha Palette
set \$rosewater #f5e0dc
set \$flamingo  #f2cdcd
set \$pink      #f5c2e7
set \$mauve     #cba6f7
set \$red       #f38ba8
set \$maroon    #eba0ac
set \$peach     #fab387
set \$yellow    #f9e2af
set \$green     #a6e3a1
set \$teal      #94e2d5
set \$sky       #89dceb
set \$sapphire  #74c7ec
set \$blue      #89b4fa
set \$lavender  #b4befe

set \$text      #cdd6f4
set \$subtext1  #bac2de
set \$subtext0  #a6adc8
set \$overlay2  #9399b2
set \$overlay1  #7f849c
set \$overlay0  #6c7086
set \$surface2  #585b70
set \$surface1  #45475a
set \$surface0  #313244
set \$base      #1e1e2e
set \$mantle    #181825
set \$crust     #11111b

# Window Borders (Catppuccin Mocha style)
# class                 border    background text      indicator child_border
client.focused          \$mauve   \$base     \$text    \$pink    \$mauve
client.unfocused        \$surface0 \$base     \$subtext0 \$surface1 \$surface0
client.focused_inactive \$surface0 \$base     \$subtext0 \$surface1 \$surface0
client.urgent           \$red     \$base     \$text    \$red     \$red
client.placeholder      \$surface0 \$base     \$text    \$surface0 \$surface0

# Autostart applications
exec_always --no-startup-id $CONFIG_DIR/polybar/launch.sh
exec_always --no-startup-id picom --config $CONFIG_DIR/picom/picom.conf

# Keybinding to reload i3 config (ensure $mod is defined, usually Mod4 or Mod1)
# This script assumes $mod is already defined in the user's existing i3 config.
# If creating from scratch, 'set $mod Mod4' would be needed.
bindsym \$mod+Shift+r reload
EOF

# Prepend the new settings to the existing i3 config (or new file)
# Create new config by concatenating new settings and old config
cat "$I3_NEW_SETTINGS_TMP" "$I3_CONFIG_FILE" > "$I3_CONFIG_FILE.tmp"
mv "$I3_CONFIG_FILE.tmp" "$I3_CONFIG_FILE"
rm "$I3_NEW_SETTINGS_TMP"

# Ensure crucial lines are not duplicated if they were already there (basic check)
# For example, remove all but the first 'font pango:' line
# This is a bit advanced for a simple script add, user might need to manually merge/clean.
# For now, we'll rely on prepending and user cleanup if they had complex configs.
echo "NOTE: i3 config has been updated. If you had an existing config, review for duplicate 'font' or 'exec' lines."
echo "A common \$mod key is Mod4 (Super/Windows key). Ensure 'set \$mod Mod4' is in your i3 config if it's new."


# Ensure correct ownership
if [ -n "$SUDO_USER" ] && [ -d "$I3_DIR" ]; then
    echo "Setting ownership of i3 configs to $SUDO_USER..."
    chown -R "$SUDO_USER:$(id -g $SUDO_USER)" "$I3_DIR" || echo "chown for i3 failed, possibly already correct."
fi

echo "i3 Window Manager configuration complete."

echo "Installing additional dependencies for GTK themes and Papirus icons..."
if [ "$OS_TYPE" == "arch" ]; then
    sudo pacman -S --noconfirm --needed papirus-icon-theme gnome-themes-extra
elif [ "$OS_TYPE" == "mint" ]; then
    sudo apt-get install -y papirus-icon-theme gnome-themes-standard # gnome-themes-standard provides Adwaita for Mint
fi

if [ ! -d "$THEME_SRC_DIR/catppuccin/cursors" ]; then
    echo "Cloning Catppuccin cursors..."
    git clone --depth 1 https://github.com/catppuccin/cursors.git "$THEME_SRC_DIR/catppuccin/cursors"
fi

echo "Configuring GTK themes, icon themes, and cursor themes..."
USER_THEMES_DIR="$USER_HOME_DIR/.themes"
USER_ICONS_DIR="$USER_HOME_DIR/.icons"
mkdir -p "$USER_THEMES_DIR"
mkdir -p "$USER_ICONS_DIR"

# Install Catppuccin GTK Theme (Mocha)
# The Catppuccin GTK repo structure is complex. Pre-built themes are in the 'themes' directory of the cloned repo.
GTK_THEME_NAME="Catppuccin-Mocha-Standard-Blue-Dark" # Example variant
if [ -d "$THEME_SRC_DIR/catppuccin/gtk/themes/$GTK_THEME_NAME" ]; then
    echo "Installing GTK Theme: $GTK_THEME_NAME"
    cp -r "$THEME_SRC_DIR/catppuccin/gtk/themes/$GTK_THEME_NAME" "$USER_THEMES_DIR/"
else
    echo "WARNING: GTK Theme $GTK_THEME_NAME not found in $THEME_SRC_DIR/catppuccin/gtk/themes/. GTK theme installation skipped."
    echo "You might need to download it from https://github.com/catppuccin/gtk/releases and install manually, or check the cloned directory structure."
fi

# Install Catppuccin Icon Theme (Mocha)
# Source: $THEME_SRC_DIR/catppuccin/icons/dist/Catppuccin-Mocha
ICON_THEME_NAME="Catppuccin-Mocha"
if [ -d "$THEME_SRC_DIR/catppuccin/icons/dist/$ICON_THEME_NAME" ]; then
    echo "Installing Icon Theme: $ICON_THEME_NAME"
    cp -r "$THEME_SRC_DIR/catppuccin/icons/dist/$ICON_THEME_NAME" "$USER_ICONS_DIR/"
else
    echo "WARNING: Icon Theme $ICON_THEME_NAME not found in $THEME_SRC_DIR/catppuccin/icons/dist/. Icon theme installation skipped."
fi

# Install Catppuccin Cursor Theme (Mocha Dark)
CURSOR_THEME_NAME="Catppuccin-Mocha-Dark" 
if [ -d "$THEME_SRC_DIR/catppuccin/cursors/dist/$CURSOR_THEME_NAME" ]; then
    echo "Installing Cursor Theme: $CURSOR_THEME_NAME"
    cp -r "$THEME_SRC_DIR/catppuccin/cursors/dist/$CURSOR_THEME_NAME" "$USER_ICONS_DIR/"
else
    echo "WARNING: Cursor Theme $CURSOR_THEME_NAME not found in $THEME_SRC_DIR/catppuccin/cursors/dist/. Cursor theme installation skipped."
fi

echo "Applying GTK settings..."
# GTK3 Settings using gsettings
if command -v gsettings &> /dev/null; then
    echo "Applying GTK3 settings using gsettings..."
    # Check if SUDO_USER is set, and run gsettings as that user if possible
    # This is crucial because gsettings writes to a user-specific dconf database
    if [ -n "$SUDO_USER" ]; then
        sudo -u "$SUDO_USER" GSETTINGS_BACKEND=dconf gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME_NAME"
        sudo -u "$SUDO_USER" GSETTINGS_BACKEND=dconf gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME_NAME"
        sudo -u "$SUDO_USER" GSETTINGS_BACKEND=dconf gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME_NAME"
        # sudo -u "$SUDO_USER" GSETTINGS_BACKEND=dconf gsettings set org.gnome.desktop.interface font-name 'Fira Sans 10' 
    else
        gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME_NAME"
        gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME_NAME"
        gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME_NAME"
        # gsettings set org.gnome.desktop.interface font-name 'Fira Sans 10' 
    fi
else
    echo "WARNING: gsettings command not found. Cannot apply GTK3 themes automatically."
fi

# GTK2 Settings
echo "Creating/Updating .gtkrc-2.0 for GTK2 applications..."
GTK2_RC_FILE="$USER_HOME_DIR/.gtkrc-2.0"
{
    echo "# GTK2 settings applied by install.sh"
    echo "gtk-theme-name=\"$GTK_THEME_NAME\""
    echo "gtk-icon-theme-name=\"$ICON_THEME_NAME\""
    echo "gtk-cursor-theme-name=\"$CURSOR_THEME_NAME\""
    echo "gtk-font-name=\"Fira Sans 10\"" # Example font
} > "$GTK2_RC_FILE"


# Ensure correct ownership for .themes, .icons, .gtkrc-2.0, and potentially .config/dconf for gsettings
if [ -n "$SUDO_USER" ]; then
    echo "Setting ownership of GTK theme files and configs to $SUDO_USER..."
    chown -R "$SUDO_USER:$(id -g "$SUDO_USER")" "$USER_THEMES_DIR" "$USER_ICONS_DIR" "$GTK2_RC_FILE"
    # For gsettings, dconf dir is usually $USER_HOME_DIR/.config/dconf
    DCONF_DIR="$USER_HOME_DIR/.config/dconf"
    if [ -d "$DCONF_DIR" ]; then
        chown -R "$SUDO_USER:$(id -g "$SUDO_USER")" "$DCONF_DIR"
    fi
    # Also consider ~/.gnome if it exists and is used by older gsettings or apps
     if [ -d "$USER_HOME_DIR/.gnome" ]; then
        chown -R "$SUDO_USER:$(id -g "$SUDO_USER")" "$USER_HOME_DIR/.gnome" 2>/dev/null || true
    fi
fi

echo "GTK configuration complete. You may need to log out and back in for all changes to take effect."

echo "Installing Nerd Fonts..."

# Define the Nerd Font to install
NERD_FONT_PACKAGE_AUR="nerd-fonts-fira-code" # AUR package name for Arch

if [ "$OS_TYPE" == "arch" ]; then
    echo "Attempting to install $NERD_FONT_PACKAGE_AUR using yay for Arch Linux..."
    if command -v yay &> /dev/null; then
        if [ -n "$SUDO_USER" ]; then
            sudo -u "$SUDO_USER" yay -S --noconfirm --needed "$NERD_FONT_PACKAGE_AUR"
        else
            yay -S --noconfirm --needed "$NERD_FONT_PACKAGE_AUR"
        fi
        echo "$NERD_FONT_PACKAGE_AUR installation attempt complete."
    else
        echo "WARNING: yay command not found. Cannot install Nerd Fonts automatically from AUR for Arch Linux."
        echo "Please install $NERD_FONT_PACKAGE_AUR manually using your AUR helper."
    fi
elif [ "$OS_TYPE" == "mint" ]; then
    NERD_FONT_NAME="FiraCode"
    FONT_DOWNLOAD_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/FiraCode.zip"
    USER_FONT_DIR="$USER_HOME_DIR/.local/share/fonts"
    EXTRACT_SUBDIR="$USER_FONT_DIR/${NERD_FONT_NAME}NerdFont" # Changed variable name slightly for clarity
    TMP_ZIP_PATH="/tmp/${NERD_FONT_NAME}.zip"

    echo "Installing Fira Code Nerd Font for Linux Mint..."
    echo "Ensuring curl and unzip are installed (added to mint_essential_packages)..."
    # Assuming they are installed by the earlier essential packages step

    mkdir -p "$USER_FONT_DIR"
    mkdir -p "$EXTRACT_SUBDIR"

    echo "Downloading $NERD_FONT_NAME Nerd Font from $FONT_DOWNLOAD_URL..."
    if curl -L "$FONT_DOWNLOAD_URL" -o "$TMP_ZIP_PATH"; then
        echo "Download successful. Extracting TTF fonts to $EXTRACT_SUBDIR..."
        # Extract only .ttf files into the subdirectory.
        # The -j flag junks paths, -o overwrites, -d specifies output dir.
        if unzip -j -o "$TMP_ZIP_PATH" "*.ttf" -d "$EXTRACT_SUBDIR/"; then
            echo "Fonts extracted successfully."
        else
            echo "ERROR: Failed to extract fonts. Please check unzip command or zip file content."
        fi
        rm "$TMP_ZIP_PATH"
    else
        echo "ERROR: Failed to download $NERD_FONT_NAME Nerd Font."
    fi
    echo "Fira Code Nerd Font installation process for Mint complete."
fi

echo "Updating font cache..."
# fc-cache should be run as the user to update their local cache.
# If run as root, it updates system cache. Both can be useful.
# For user-specific fonts installed to ~/.local/share/fonts or via user-run yay, user fc-cache is key.
if [ -n "$SUDO_USER" ]; then
    sudo -u "$SUDO_USER" fc-cache -fv
else
    fc-cache -fv
fi

echo "Nerd Font installation and font cache update complete."

echo "---------------------------------------------------------------------"
echo "INSTALLATION AND CONFIGURATION COMPLETE!"
echo "---------------------------------------------------------------------"
echo ""
echo "IMPORTANT NEXT STEPS:"
echo "1. LOG OUT and LOG BACK IN to your i3 session for all changes to take effect."
echo "   (e.g., close your X session and start it again)."
echo ""
echo "2. Review your i3 configuration file: $CONFIG_DIR/i3/config"
echo "   - Ensure the 'set \$mod ModX' line (e.g., Mod4 for Super key) is correct for you."
echo "   - Check for any unintentional duplicate lines if you had an existing config."
echo "   - The script prepended new settings; you might want to reorganize it."
echo ""
echo "3. Polybar:"
echo "   - The launch script uses 'polybar example &'. The Catppuccin Mocha config"
echo "     ($CONFIG_DIR/polybar/config.ini) uses '[bar/example]' by default."
echo "     If you change bar names, update $CONFIG_DIR/polybar/launch.sh."
echo ""
echo "4. Customization & Theme Switching:"
echo "   - Theme source files are in: $THEME_SRC_DIR"
echo "     (e.g., $THEME_SRC_DIR/catppuccin/polybar for other Catppuccin Polybar flavors,"
echo "     $THEME_SRC_DIR/rose-pine/ for Rosé Pine themes)."
echo "   - To change themes (e.g., to Rosé Pine or another Catppuccin flavor):"
echo "     a. Identify the theme files in $THEME_SRC_DIR for the component (Polybar, Kitty, etc.)."
echo "     b. Copy the desired theme file to the component's config directory:"
echo "        - Polybar: $CONFIG_DIR/polybar/config.ini"
echo "        - Kitty: $CONFIG_DIR/kitty/kitty.conf"
echo "        - GTK: Copy to $USER_HOME_DIR/.themes/ and update via gsettings/lxappearance."
echo "        - Icons: Copy to $USER_HOME_DIR/.icons/ and update."
echo "     c. For i3 colors, edit $CONFIG_DIR/i3/config with new color values."
echo ""
echo "5. Fonts:"
echo "   - FiraCode Nerd Font has been installed by this script."
echo "   - If you prefer another Nerd Font:"
if [ "$OS_TYPE" == "arch" ]; then
echo "     On Arch Linux, you can search and install via yay (e.g., 'yay -S nerd-fonts-jetbrains-mono')."
elif [ "$OS_TYPE" == "mint" ]; then
echo "     On Linux Mint, download the font from a trusted source (like https://www.nerdfonts.com/font-downloads)."
echo "     Then, create a directory in ~/.local/share/fonts (e.g., ~/.local/share/fonts/JetBrainsMonoNerdFont),"
echo "     extract the font files (TTF or OTF) into it, and run 'fc-cache -fv'."
echo "     Alternatively, some Nerd Fonts might be available via PPAs or eventually in system repositories."
fi
echo "   - After installing a new font, update your i3, Kitty, and Polybar configs accordingly."
echo ""
if [ "$OS_TYPE" == "arch" ]; then
    echo "Enjoy your newly customized Arch Linux i3 environment!"
elif [ "$OS_TYPE" == "mint" ]; then
    echo "Enjoy your newly customized Linux Mint i3 environment!"
else
    echo "Enjoy your newly customized i3 environment!"
fi
echo "---------------------------------------------------------------------"
