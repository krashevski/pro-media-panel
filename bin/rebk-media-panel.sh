#!/usr/bin/env bash
# =============================================================
# rebk-media-panel.sh — рабочая версия REBK MEDIA PANEL
# -------------------------------------------------------------

set -euo pipefail

BASE_DIR="/mnt/shotcut"
STORAGE_DIR="/mnt/storage"
PROJECT_DIR="$BASE_DIR/projects"
VIDEO_DIR="$STORAGE_DIR/Videos"
EXPORT_DIR="$BASE_DIR/exports"

pause() { read -rp "Press Enter..."; }

has_flatpak() { flatpak info "$1" &>/dev/null; }

detect_gpu() { GPU=$(lspci | grep -qi nvidia && echo "NVIDIA" || echo "CPU"); }

detect_nvenc() { NVENC=$(ffmpeg -encoders 2>/dev/null | grep -q nvenc && echo "YES" || echo "NO"); }

# =================================
# SYSTEM STATUS
# =================================
system_status() {
    clear
    detect_gpu
    detect_nvenc
    echo "=== SYSTEM STATUS ==="
    echo
    echo "GPU: $GPU"
    echo "NVENC: $NVENC"
    echo
    df -h "$BASE_DIR" "$STORAGE_DIR"
    echo
    local projects_count
    projects_count=$(find "$PROJECT_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
    echo "Projects: $projects_count"
    pause
}

# =================================
# READ PROJECT NAME
# =================================
read_project_name() {
    read -rp "Project name: " project
    project=$(echo "$project" | xargs)
    project=$(printf "%s" "$project" | tr -cd '[:alnum:]_ -')
    [[ -z "$project" ]] && { echo "No project name entered."; return 1; }
    printf "%s" "$project"
}

# =================================
# CREATE PROJECT
# =================================
project_create() {
    local project="$1"
    echo "Creating project: $project"
    mkdir -p "$VIDEO_DIR/$project/footage"
    mkdir -p "$PROJECT_DIR/$project/proxy" \
             "$PROJECT_DIR/$project/edit" \
             "$PROJECT_DIR/$project/export"
    echo "Project directories created:"
    echo "  HDD footage: $VIDEO_DIR/$project/footage"
    echo "  SSD proxy: $PROJECT_DIR/$project/proxy"
    echo "  SSD edit: $PROJECT_DIR/$project/edit"
    echo "  SSD export: $PROJECT_DIR/$project/export"
}

# =================================
# SELECT PROJECT BY NUMBER
# =================================
project_select() {
    echo
    echo "=== Select project ==="
    echo
    if ! [ -d "$PROJECT_DIR" ]; then
        echo "Project directory not found."
        return 1
    fi
    # читаем только директории, корректно с UTF-8
    readarray -t projects < <(find "$PROJECT_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
    if [[ ${#projects[@]} -eq 0 ]]; then
        echo "No projects found."
        return 1
    fi
    for i in "${!projects[@]}"; do
        printf "%d) %s\n" $((i+1)) "${projects[$i]}"
    done
    echo
    read -rp "Select: " num
    if ! [[ "$num" =~ ^[0-9]+$ ]] || (( num < 1 || num > ${#projects[@]} )); then
        echo "Invalid selection."
        return 1
    fi
    printf "%s\n" "${projects[$((num-1))]}"
}

# =================================
# INGEST FOOTAGE FROM PHONE
# =================================
ingest_from_phone() {
    project=$(project_select) || return
    dest="$VIDEO_DIR/$project/footage"
    proxy="$PROJECT_DIR/$project/proxy"
    mkdir -p "$dest" "$proxy"

    state="$PROJECT_DIR/$project/imported.list"
    touch "$state"

    echo
    echo "Searching phone..."
    PHONE=$(find /run/user/$UID/gvfs -maxdepth 3 -type d -name DCIM 2>/dev/null | head -n1)
    if [[ -z "$PHONE" ]]; then
        echo "Phone not detected automatically."
        read -rp "Enter GVFS/MTP path to DCIM (e.g. mtp://…): " PHONE
        [[ -z "$PHONE" ]] && { echo "No path provided. Aborting."; pause; return; }
    fi
    echo "Using DCIM path: $PHONE"
    echo

    count=0
    shopt -s nullglob

    # --- MTP через gio ---
    if [[ "$PHONE" == mtp://* ]]; then
        echo "Copying videos via MTP..."
        set +e
        gio copy -v -r "$PHONE/" "$dest/"
        set -e
        echo "All files copied to $dest"

        for f in "$dest"/*.{MP4,mp4,MOV,mov}; do
            [[ -e "$f" ]] || continue
            name=$(basename "$f")
            if grep -Fxq -- "$name" "$state"; then
                echo "Skipping already imported: $name"
                continue
            fi
            proxyfile="$proxy/${name%.*}_proxy.mp4"
            echo "Creating proxy for $name ..."
            ffmpeg -y -i "$f" -vf scale=1280:-2 -c:v libx264 -preset veryfast -crf 28 -c:a aac "$proxyfile"
            printf '%s\n' "$name" >> "$state"
            ((count++))
        done

    # --- обычная директория ---
    elif [[ -d "$PHONE" ]]; then
        for f in "$PHONE"/*/*.{MP4,mp4,MOV,mov}; do
            [[ -e "$f" ]] || continue
            name=$(basename "$f")
            if grep -Fxq -- "$name" "$state"; then
                echo "Skipping already imported: $name"
                continue
            fi
            date=$(date -r "$f" +"%Y%m%d_%H%M%S")
            new="$dest/clip_$date.mp4"
            echo "Copying $name → $new"
            cp "$f" "$new"
            printf '%s\n' "$name" >> "$state"
            proxyfile="$proxy/clip_${date}_proxy.mp4"
            echo "Creating proxy..."
            ffmpeg -y -i "$new" -vf scale=1280:-2 -c:v libx264 -preset veryfast -crf 28 -c:a aac "$proxyfile"
            ((count++))
        done
    else
        echo "Path $PHONE is invalid."
        pause
        return
    fi

    echo
    echo "Imported clips: $count"
    pause
}

# =================================
# GENERATE PROXY
# =================================
generate_proxy() {
    project=$(project_select) || return
    src="$PROJECT_DIR/$project/footage"
    dst="$PROJECT_DIR/$project/proxy"
    mkdir -p "$dst"
    shopt -s nullglob
    for f in "$src"/*.mp4; do
        [[ -e "$f" ]] || continue
        name=$(basename "$f")
        proxy="$dst/${name%.*}_proxy.mp4"
        echo "Processing $name"
        ffmpeg -y -i "$f" -vf scale=1280:-2 -c:v libx264 -preset veryfast -crf 28 -c:a aac "$proxy"
    done
    echo
    echo "Proxy generation complete."
    pause
}

# =================================
# Launch Shotcut
# =================================
launch_shotcut() {
    if has_flatpak org.shotcut.Shotcut; then
        flatpak run org.shotcut.Shotcut
    else
        echo "Shotcut not installed."
        pause
    fi
}

# =================================
# EXPORT YOUTUBE
# =================================
export_youtube() {
    project=$(project_select) || return
    src="$PROJECT_DIR/$project/export"
    read -rp "Input video file: " input
    out="$EXPORT_DIR/${project}_youtube_$(date +%s).mp4"
    ffmpeg -y -i "$input" -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p -movflags +faststart -c:a aac -b:a 192k "$out"
    echo
    echo "Export created: $out"
    pause
}

# =================================
# ARCHIVE PROJECT
# =================================
archive_project() {
    project=$(project_select) || return
    dir="$PROJECT_DIR/$project"
    archive="$EXPORT_DIR/${project}_archive_$(date +%Y%m%d).tar.gz"
    tar -czf "$archive" "$dir"
    echo
    echo "Archive saved: $archive"
    pause
}

# =================================
# VIDEO / GRAPHICS / AUDIO TOOLS
# =================================
video_tools_menu() {
    i=1
    declare -A appmap
    clear
    echo "=== VIDEO TOOLS ==="
    [[ $(has_flatpak org.shotcut.Shotcut) ]] && { echo "$i) Shotcut"; appmap[$i]="flatpak run org.shotcut.Shotcut"; ((i++)); }
    [[ $(has_flatpak com.obsproject.Studio) ]] && { echo "$i) OBS Studio"; appmap[$i]="flatpak run com.obsproject.Studio"; ((i++)); }
    echo "$i) ffmpeg terminal"; appmap[$i]='gnome-terminal -- bash -c "ffmpeg -h; exec bash"'; ((i++))
    echo "$i) Back"; read -rp "Select: " choice
    [[ -n "${appmap[$choice]:-}" ]] && eval "${appmap[$choice]}"
}

graphics_menu() {
    i=1
    declare -A appmap
    clear
    echo "=== GRAPHICS TOOLS ==="
    [[ $(has_flatpak org.gimp.GIMP) ]] && { echo "$i) GIMP"; appmap[$i]="flatpak run org.gimp.GIMP"; ((i++)); }
    [[ $(has_flatpak org.kde.krita) ]] && { echo "$i) Krita"; appmap[$i]="flatpak run org.kde.krita"; ((i++)); }
    echo "$i) Back"; read -rp "Select: " choice
    [[ -n "${appmap[$choice]:-}" ]] && eval "${appmap[$choice]}"
}

audio_menu() {
    i=1
    declare -A appmap
    clear
    echo "=== AUDIO TOOLS ==="
    [[ $(has_flatpak org.audacityteam.Audacity) ]] && { echo "$i) Audacity"; appmap[$i]="flatpak run org.audacityteam.Audacity"; ((i++)); }
    echo "$i) Back"; read -rp "Select: " choice
    [[ -n "${appmap[$choice]:-}" ]] && eval "${appmap[$choice]}"
}

# =================================
# MAIN MENU LOOP
# =================================
while true; do
    clear
    echo "================================="
    echo "        REBK MEDIA PANEL"
    echo "================================="
    echo
    echo "1) System status"
    echo "2) Create project"
    echo "3) Footage ingest from phone"
    echo "4) Generate proxy"
    echo "5) Launch Shotcut"
    echo "6) Export YouTube"
    echo "7) Archive project"
    echo
    echo "8) Video tools"
    echo "9) Graphics tools"
    echo "10) Audio tools"
    echo
    echo "0) Exit"
    echo
    read -rp "Select: " main
    case "$main" in
        1) system_status ;;
        2) project=$(read_project_name) || continue; project_create "$project" ;;
        3) ingest_from_phone ;;
        4) generate_proxy ;;
        5) launch_shotcut ;;
        6) export_youtube ;;
        7) archive_project ;;
        8) video_tools_menu ;;
        9) graphics_menu ;;
        10) audio_menu ;;
        0) exit 0 ;;
        *) echo "Invalid option"; pause ;;
    esac
done