#!/bin/bash
# =================================
# Uninstall Pro media panel
# =================================

SYSTEM_BIN="/usr/local/bin"
SYSTEM_DESKTOP="/usr/share/applications"
ICON_DIR="/usr/share/icons/hicolor"
ICON_SIZES=(48 128 256)

SCRIPT_NAME="pro-media-panel.sh"
DESKTOP_FILE="pro-media-panel.desktop"
ICON_NAME="pro-media-panel.png"

echo "Uninstalling Pro media panel..."

# -----------------------------
# 1. Удаляем скрипт
# -----------------------------
if [ -f "$SYSTEM_BIN/$SCRIPT_NAME" ]; then
    echo "Backing up and removing script..."
    sudo cp "$SYSTEM_BIN/$SCRIPT_NAME" "$SYSTEM_BIN/${SCRIPT_NAME}.bak_$(date +%F-%H%M%S)"
    sudo rm "$SYSTEM_BIN/$SCRIPT_NAME"
else
    echo "Script not found, skipping."
fi

# -----------------------------
# 2. Удаляем .desktop
# -----------------------------
if [ -f "$SYSTEM_DESKTOP/$DESKTOP_FILE" ]; then
    echo "Backing up and removing .desktop..."
    sudo cp "$SYSTEM_DESKTOP/$DESKTOP_FILE" "$SYSTEM_DESKTOP/${DESKTOP_FILE}.bak_$(date +%F-%H%M%S)"
    sudo rm "$SYSTEM_DESKTOP/$DESKTOP_FILE"
else
    echo ".desktop file not found, skipping."
fi

# -----------------------------
# 3. Удаляем иконки
# -----------------------------
echo "Removing icons..."
for SIZE in "${ICON_SIZES[@]}"; do
    ICON_PATH="$ICON_DIR/${SIZE}x${SIZE}/apps/$ICON_NAME"
    if [ -f "$ICON_PATH" ]; then
        echo "Backing up and removing $SIZE x $SIZE icon..."
        sudo cp "$ICON_PATH" "${ICON_PATH}.bak_$(date +%F-%H%M%S)"
        sudo rm "$ICON_PATH"
    else
        echo "Icon $SIZE x $SIZE not found, skipping."
    fi
done

# -----------------------------
# 4. Обновляем кэш
# -----------------------------
echo "Updating icon and desktop cache..."
sudo gtk-update-icon-cache "$ICON_DIR"
sudo update-desktop-database "$SYSTEM_DESKTOP"

echo "Pro media panel has been uninstalled."