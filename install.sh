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
USER_BIN="$HOME/bin"
APP_DIR="$HOME/.local/share/applications"
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
mkdir -p "$USER_BIN"
mkdir -p "$APP_DIR"
mkdir -p "$SHOTCUT_PROJECT_DIR" "$EXPORT_DIR"
mkdir -p "$PROJECT_DIR" "$ARCHIVE_DIR" "$ARCHIVE_VIDEO_DIR"

# -----------------------------
# Установка скрипта
# -----------------------------
echo " Installing script..."
cp bin/pro-media-panel.sh "$USER_BIN/"
chmod +x "$USER_BIN/pro-media-panel.sh"

# -----------------------------
# Установка .desktop файла
# -----------------------------
echo " Installing desktop entry..."
cp desktop/pro-media-panel.desktop "$APP_DIR/"
# Меняем путь Exec внутри .desktop
sed -i "s|Exec=.*|Exec=$USER_BIN/pro-media-panel.sh|" "$APP_DIR/pro-media-panel.desktop"

echo
echo " Installation complete!"
echo " You can now run PRODUCTION MEDIA PANEL from your menu or with:"
echo "   $ $USER_BIN/pro-media-panel.sh"
echo
echo "   Project folder: $PROJECT_DIR"
echo "   Shotcut project folder: $SHOTCUT_PROJECT_DIR"
echo "   Export YouTube folder: $EXPORT_DIR"
echo "   ARCHIVE folder: $ARCHIVE_DIR"