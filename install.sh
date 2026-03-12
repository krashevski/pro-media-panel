#!/usr/bin/env bash

set -e

echo "================================="
echo "      PRODUCTION MEDIA PANEL"
echo "================================="

# -----------------------------
# Пути установки
# -----------------------------
USER_BIN="$HOME/bin"
APP_DIR="$HOME/.local/share/applications"
PROJECT_BASE="/mnt/shotcut"
PROJECTS_DIR="$PROJECT_BASE/projects"
EXPORT_DIR="$PROJECT_BASE/exports"

# -----------------------------
# Создаём необходимые папки
# -----------------------------
mkdir -p "$USER_BIN"
mkdir -p "$APP_DIR"
mkdir -p "$PROJECTS_DIR" "$EXPORT_DIR"

# -----------------------------
# Установка скрипта
# -----------------------------
echo "Installing script..."
cp bin/pro-media-panel.sh "$USER_BIN/"
chmod +x "$USER_BIN/pro-media-panel.sh"

# -----------------------------
# Установка .desktop файла
# -----------------------------
echo "Installing desktop entry..."
cp desktop/pro-media-panel.desktop "$APP_DIR/"
# Меняем путь Exec внутри .desktop
sed -i "s|Exec=.*|Exec=$USER_BIN/pro-media-panel.sh|" "$APP_DIR/pro-media-panel.desktop"

echo
echo "Installation complete!"
echo "You can now run PRODUCTION MEDIA PANEL from your menu or with:"
echo "  $ $USER_BIN/pro-media-panel.sh"
echo
echo "Project folder: $PROJECTS_DIR"
echo "Export folder: $EXPORT_DIR"