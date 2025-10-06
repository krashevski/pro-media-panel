#!/bin/bash
# ============================
# media-panel.sh
# Шаблон панели под конкретные медиапрограммы
# ----------------------------
# Ярлык для запуска Шаблона панели медиапрограмм 
# в графическом меню media-panel.desktop
# Директория ярлыка Шаблона медиа-панели ~/.local/share/applications/
# ============================
while true; do
    clear
    echo "=== МЕДИА ПАНЕЛЬ ==="
    echo "1) Shotcut (видеомонтаж)"
    echo "2) OBS Studio (запись/стрим)"
    echo "3) GIMP (графика)"
    echo "4) ffmpeg (терминал)"
    echo "5) Выйти"
    echo
    read -p "Выберите пункт: " choice
    case $choice in
        1) flatpak run org.shotcut.Shotcut ;;
        2) flatpak run com.obsproject.Studio ;;
        3) flatpak run org.gimp.GIMP ;;
        4) gnome-terminal -- bash -c "ffmpeg -h; exec bash" ;;
        5) exit 0 ;;
        *) echo "Неверный выбор"; sleep 1 ;;
    esac
done

