#!/usr/bin/env bash

set -e

# Цвета
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
RESET="\e[0m"
BOLD="\e[1m"

echo -e "${BOLD}${CYAN}====================================================${RESET}"
echo -e "               ${BOLD}${CYAN}PRODUCTION MEDIA PANEL${RESET}"
echo -e "${BOLD}${CYAN}====================================================${RESET}"

# -----------------------------
# Пути установки
# -----------------------------
# Каталог для скриптов в системе
SYSTEM_BIN="/usr/local/bin"
# Каталог для .desktop файлов
SYSTEM_DESKTOP="/usr/share/applications"
# Каталог для иконок
ICON_DIR="/usr/share/icons/hicolor"

BASE_DIR="/mnt/shotcut"
STORAGE_DIR="/mnt/storage"
VIDEO_DIR="$STORAGE_DIR/Videos"
PROJECT_DIR="$VIDEO_DIR/projects"
SHOTCUT_PROJECT_DIR="$BASE_DIR/projects"
EXPORT_DIR="$BASE_DIR/exports"
ARCHIVE_DIR="/mnt/backups/PMP"
ARCHIVE_VIDEO_DIR="$ARCHIVE_DIR/Videos"

# -----------------------------
# Создаём необходимые папки
# -----------------------------
mkdir -p "$SHOTCUT_PROJECT_DIR" "$EXPORT_DIR"
mkdir -p "$PROJECT_DIR" "$ARCHIVE_DIR" "$ARCHIVE_VIDEO_DIR"


# -----------------------------
# 1. Установка скрипта
# -----------------------------
echo "Installing script..."
sudo cp bin/pro-media-panel.sh "$SYSTEM_BIN/"
sudo chmod +x "$SYSTEM_BIN/pro-media-panel.sh"

# -----------------------------
# 2. Установка .desktop файла
# -----------------------------
echo "Installing .desktop file..."
sudo cp desktop/pro-media-panel.desktop "$SYSTEM_DESKTOP/"

# -----------------------------
# 3. Установка иконок
# -----------------------------
echo "Installing icons..."
# Создаем каталоги, если их нет
sudo mkdir -p "$ICON_DIR/48x48/apps"
sudo mkdir -p "$ICON_DIR/128x128/apps"
sudo mkdir -p "$ICON_DIR/256x256/apps"

# Копируем иконки
sudo cp images/48x48/pro-media-panel.png "$ICON_DIR/48x48/apps/pro-media-panel.png"
sudo cp images/64x64/pro-media-panel.png "$ICON_DIR/64x64/apps/pro-media-panel.png"
sudo cp images/128x128/pro-media-panel.png "$ICON_DIR/128x128/apps/pro-media-panel.png"
sudo cp images/256x256/pro-media-panel.png "$ICON_DIR/256x256/apps/pro-media-panel.png"

# -----------------------------
# 4. Обновляем кэш
# -----------------------------
echo "Updating icon and desktop cache..."
sudo gtk-update-icon-cache "$ICON_DIR"
sudo update-desktop-database "$SYSTEM_DESKTOP"

echo
echo "Installation complete! You can now launch Pro media panel from the menu."
echo
echo "You can now run PRODUCTION MEDIA PANEL from your menu or with:"
echo "   $ $SYSTEM_BIN/pro-media-panel.sh"
echo
echo "   Project folder: $PROJECT_DIR"
echo "   Shotcut project folder: $SHOTCUT_PROJECT_DIR"
echo "   Export YouTube folder: $EXPORT_DIR"
echo "   ARCHIVE folder: $ARCHIVE_DIR"