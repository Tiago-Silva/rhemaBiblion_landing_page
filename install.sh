#!/bin/sh
# Installer script for RhemaBiblion AppImage with desktop integration
set -e

echo "=== RhemaBiblion Linux Installer ==="

# 1. Detect environment and privilege level
if [ "$EUID" -ne 0 ]; then
    echo "Running as local user. Installing to home directory (~/.local)..."
    INSTALL_DIR="$HOME/.local/share/rhemabiblion"
    BIN_DIR="$HOME/.local/bin"
    ICON_DIR="$HOME/.local/share/icons/hicolor/512x512/apps"
    DESKTOP_DIR="$HOME/.local/share/applications"
else
    echo "Running as root. Installing system-wide (/opt)..."
    INSTALL_DIR="/opt/rhemabiblion"
    BIN_DIR="/usr/local/bin"
    ICON_DIR="/usr/share/icons/hicolor/512x512/apps"
    DESKTOP_DIR="/usr/share/applications"
fi

# 2. Create directory structures
echo "Creating folders..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"
mkdir -p "$ICON_DIR"
mkdir -p "$DESKTOP_DIR"

# 3. Fetch latest release AppImage URL from GitHub API
echo "Resolving latest release package..."
APPIMAGE_URL=$(curl -s https://api.github.com/repos/Tiago-Silva/rhemaBiblion_landing_page/releases/latest | grep "browser_download_url.*AppImage" | cut -d '"' -f 4 || true)

if [ -z "$APPIMAGE_URL" ]; then
    echo "Could not resolve dynamically. Using fallback release link..."
    APPIMAGE_URL="https://github.com/Tiago-Silva/rhemaBiblion_landing_page/releases/latest/download/rhemabiblion_1.1.0_amd64.AppImage"
fi

echo "Downloading AppImage from: $APPIMAGE_URL"
curl -L "$APPIMAGE_URL" -o "$INSTALL_DIR/rhemabiblion.AppImage"
chmod +x "$INSTALL_DIR/rhemabiblion.AppImage"

# 4. Copy uninstall script to install directory for user convenience
if [ -f "uninstall.sh" ]; then
    echo "Copying uninstaller to application folder..."
    cp uninstall.sh "$INSTALL_DIR/uninstall.sh"
    chmod +x "$INSTALL_DIR/uninstall.sh"
fi

# 5. Create launcher command in binary path
echo "Configuring executable path..."
cat << EOF > "$BIN_DIR/rhemabiblion"
#!/bin/sh
# Command wrapper for RhemaBiblion AppImage
exec "$INSTALL_DIR/rhemabiblion.AppImage" "\$@"
EOF
chmod +x "$BIN_DIR/rhemabiblion"

# 5. Fetch High Resolution Icon
echo "Installing application launcher icon..."
curl -L "https://tiago-silva.github.io/rhemaBiblion_landing_page/public/rhemabiblion.png" -o "$INSTALL_DIR/rhemabiblion.png"

# 6. Create Desktop Menu Launcher Entry
echo "Creating desktop shortcut entry..."
cat << EOF > "$DESKTOP_DIR/rhemabiblion.desktop"
[Desktop Entry]
Name=RhemaBiblion
Comment=Leitura, Estudo e Análise Bíblica e Teológica
Exec=$INSTALL_DIR/rhemabiblion.AppImage
Icon=$INSTALL_DIR/rhemabiblion.png
Terminal=false
Type=Application
Categories=Education;Utility;
StartupWMClass=rhemabiblion
EOF
chmod +x "$DESKTOP_DIR/rhemabiblion.desktop"

# 7. Update desktop databases if tools are available
if [ "$EUID" -eq 0 ]; then
    update-desktop-database /usr/share/applications 2>/dev/null || true
    gtk-update-icon-cache /usr/share/icons/hicolor 2>/dev/null || true
else
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    gtk-update-icon-cache "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
fi

echo "=========================================="
echo "RhemaBiblion installed successfully!"
echo "You can now open it from your Application Menu."
echo "Or run 'rhemabiblion' directly in your terminal."
echo "=========================================="
