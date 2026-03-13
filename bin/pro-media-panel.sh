#!/usr/bin/env bash
# =============================================================
# pro-media-panel.sh — Панель видеопроизводства PRODUCTION MEDIA PANEL
# -------------------------------------------------------------

set -euo pipefail

IFS=$'\n\t'

# Цвета
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
RESET="\e[0m"
BOLD="\e[1m"

# =============================================================
# Папки для хранения
# =============================================================
BASE_DIR="/mnt/shotcut"
STORAGE_DIR="/mnt/storage"
#
VIDEO_DIR="$STORAGE_DIR/Videos"
AUDIO_DIR="$STORAGE_DIR/Music"
PROJECT_DIR="$VIDEO_DIR/projects"
#
SHOTCUT_PROJECT_DIR="$BASE_DIR/projects"
AUDIO_PROJECT_DIR="$AUDIO_DIR/projects"
# Папка для экспортов (YouTube, архивы)
EXPORT_DIR="$BASE_DIR/exports"
#
ARCHIVE_DIR="/mnt/backups/PMP"  
ARCHIVE_VIDEO_DIR="$ARCHIVE_DIR/Videos" # архивы проектов
mkdir -p "$PROJECT_DIR" "$AUDIO_PROJECT_DIR" "$EXPORT_DIR" "$ARCHIVE_DIR" "$ARCHIVE_VIDEO_DIR"

PHONE_DIR=""

has_flatpak() { flatpak info "$1" &>/dev/null; }

detect_gpu() { GPU=$(lspci | grep -qi nvidia && echo "NVIDIA" || echo "CPU"); }

detect_nvenc() { NVENC=$(ffmpeg -encoders 2>/dev/null | grep -q nvenc && echo "YES" || echo "NO"); }

detect_phone_dir() {

    local gvfs="/run/user/$UID/gvfs"

    # GVFS может отсутствовать
    [[ -d "$gvfs" ]] || return 1

    # перебираем все MTP устройства
    while IFS= read -r -d '' dev; do

        for dir in \
            "Internal shared storage/DCIM/OpenCamera" \
            "Internal shared storage/DCIM/Camera" \
            "Internal shared storage/Movies" \
            "Internal shared storage/DCIM" \
            "Внутренняя память/DCIM/OpenCamera" \
            "Внутренняя память/DCIM/Camera" \
            "Внутренняя память/DCIM"
        do

            path="$dev/$dir"

            if [[ -d "$path" ]]; then
                PHONE_DIR="$path"
                return 0
            fi

        done

    done < <(find "$gvfs" -maxdepth 1 -type d -name "mtp:*" -print0 2>/dev/null)

    return 1
}

phone_status() {

    local gvfs="/run/user/$UID/gvfs"

    echo " Phone:"

    if [[ ! -d "$gvfs" ]]; then
        echo "   GVFS not available"
        return
    fi

    mtp=$(find "$gvfs" -maxdepth 1 -type d -name "mtp:*" 2>/dev/null | head -n1)

    if [[ -z "$mtp" ]]; then
        echo "   Not connected"
        return
    fi

    echo "   Device detected"

    detect_phone_dir

    if [[ -n "$PHONE_DIR" ]]; then
        echo " Video folder:"
        echo "   $PHONE_DIR"
    else
        echo " Video folder not found"
    fi
}

pause() {
    echo
    read -rp " Press Enter to continue..."
}

next_project_number() {

    local max=0

    [[ -d "$PROJECT_DIR" ]] || { printf "%03d" 1; return; }

    while IFS= read -r -d '' dir; do

        name=$(basename "$dir")

        if [[ "$name" =~ ^([0-9]{3})_ ]]; then
            num=${BASH_REMATCH[1]}
            (( num > max )) && max=$num
        fi

    done < <(find "$PROJECT_DIR" -mindepth 1 -maxdepth 1 -type d -print0)

    printf "%03d" $((max + 1))
}

# =================================
# SYSTEM STATUS
# =================================
system_status() {
    clear

    detect_gpu
    detect_nvenc

    echo -e "${BOLD}${CYAN}====================================================${RESET}"
    echo -e "               ${BOLD}${CYAN}SYSTEM STATUS${RESET}"
    echo -e "${BOLD}${CYAN}====================================================${RESET}"
    echo
    echo " GPU:   $GPU"
    echo " NVENC: $NVENC"
    echo

    df -h "$BASE_DIR" "$STORAGE_DIR" 2>/dev/null
    echo

    local projects_count=0

    if [[ -d "$PROJECT_DIR" ]]; then
        projects_count=$(find "$PROJECT_DIR" -mindepth 1 -maxdepth 1 -type d | wc -l)
    fi

    echo " Projects: $projects_count"
    echo
    phone_status

    pause
}

# =================================
# READ PROJECT NAME
# =================================
read_project_name() {
    read -rp " Project name: " project
    project=$(echo "$project" | xargs)
    project=$(printf "%s" "$project" | tr -cd '[:alnum:]_ -')
    [[ -z "$project" ]] && { echo " No project name entered."; return 1; }
    printf " %s" "$project"
}

# =================================
# CREATE PROJECT
# =================================
project_create() {

    echo
    read -r -p " Project name: " name || return

    name=$(printf "%s" "$name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    [[ -z "$name" ]] && {
        echo " Empty project name."
        pause
        return
    }

    number=$(next_project_number)

    project_name="${number}_${name}"

    storage_project="$PROJECT_DIR/$project_name"
    audio_project="$AUDIO_PROJECT_DIR/$project_name"
    shotcut_project="$SHOTCUT_PROJECT_DIR/$project_name"

    echo
    echo " Creating project:"
    echo "   Storage: $storage_project"
    echo "   Audio: $audio_project"
    echo "   Shotcut: $shotcut_project"
    echo

    mkdir -p \
        "$storage_project/footage" \
        "$storage_project/raw" \
        "$storage_project/edit" \
        "$storage_project/export"

    mkdir -p \
        "$shotcut_project/proxy" \
        "$shotcut_project/project"

    echo -e " ${GREEN}✓${RESET} Project created: $project_name"
    echo

    pause
}


# =================================
# CREATE PROJECT
# =================================
project_info() {

    # Выбор проекта
    project_list || return 1
    project_path=$(project_select) || return 1
    project_name=$(basename "$project_path")

    # Папки
    footage_dir="$project_path/footage"
    raw_dir="$project_path/raw"
    shotcut_dir="$SHOTCUT_PROJECT_DIR/$project_name/proxy"

    # Счётчики клипов
    footage_count=0
    proxy_count=0

    [[ -d "$footage_dir" ]] && \
        footage_count=$(find "$footage_dir" -maxdepth 1 -type f \( -iname "*.mp4" -o -iname "*.mov" \) | wc -l)

    [[ -d "$shotcut_dir" ]] && \
        proxy_count=$(find "$shotcut_dir" -maxdepth 1 -type f \( -iname "*.mp4" -o -iname "*.mov" \) | wc -l)

    # Размеры каталогов
    footage_size=$(du -sh "$footage_dir" 2>/dev/null | cut -f1)
    proxy_size=$(du -sh "$shotcut_dir" 2>/dev/null | cut -f1)

    # Общий размер проекта
    total_size=$(du -sh "$project_path" 2>/dev/null | cut -f1)

    # Дата последнего изменения
    last_edit=$(stat -c %y "$project_path" 2>/dev/null | cut -d' ' -f1)

    # Выводим аккуратно
    echo
    echo " === Project Info ==="
    echo
    printf " Project: %s\n" "$project_name"
    printf " Footage: %d clips | %s\n" "$footage_count" "$footage_size"
    printf " Proxy:   %d files | %s\n" "$proxy_count" "$proxy_size"
    printf " Total size: %s\n" "$total_size"
    printf " Last edit: %s\n" "$last_edit"
    pause
}

# =================================
# SELECT PROJECT BY NUMBER
# =================================
# Функция для вывода списка проектов
project_list() {

    [[ -d "$PROJECT_DIR" ]] || {
        echo " Project directory not found: $PROJECT_DIR"
        return 1
    }

    projects=()

    while IFS= read -r -d '' dir; do
        projects+=("$dir")
    done < <(find "$PROJECT_DIR" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

    (( ${#projects[@]} == 0 )) && {
        echo " No projects found."
        return 1
    }

    echo
    echo " === Select project ==="
    echo

    for i in "${!projects[@]}"; do

        name=$(basename "${projects[$i]}")

        # отделяем номер проекта
        if [[ "$name" =~ ^([0-9]{3})_(.*)$ ]]; then
            num="${BASH_REMATCH[1]}"
            title="${BASH_REMATCH[2]}"
        else
            num="---"
            title="$name"
        fi

        printf "%2d) %s  |  %s\n" "$((i+1))" "$num" "$title"

    done

    echo
}

# Функция для выбора проекта
project_select() {

    local num
    read -rp "Select project: " num || return 1

    if [[ ! "$num" =~ ^[0-9]+$ ]] || (( num < 1 || num > ${#projects[@]} )); then
        echo "Invalid selection"
        return 1
    fi

    printf "%s\n" "${projects[$((num-1))]}"
}

# --- простая пауза перед запросом ---
# read -n1 -s -r -p "Press any key to continue to project selection..."

# =================================
# INGEST FOOTAGE FROM PHONE
# =================================
ingest_from_phone() {
   
    detect_phone_dir || {
        echo " Phone not detected."
        return 1
    }

    project_list || return
    project_path=$(project_select) || return 1

    echo
    echo " Importing into: $project_path"
    echo

    mkdir -p "$project_path/raw"

    find "$PHONE_DIR" -type f \( -iname "*.mp4" -o -iname "*.mov" \) -print0 |
    while IFS= read -r -d '' file; do

        base=$(basename "$file")
        target="$project_path/raw/$base"

        if [[ -f "$target" ]]; then
            echo "Skip existing: $base"
            continue
        fi

        echo " Copy: $base"
        rsync -a --ignore-existing "$file" "$target"

    done

    mkdir -p "$project_path/footage"
    cp -u "$project_path/raw/"* "$project_path/footage/"

    echo
    echo " Import complete."
}

# =================================
# GENERATE PROXY
# =================================
generate_proxy() {

    # Выводим список проектов
    project_list || return

    # Выбираем проект
    project_path=$(project_select) || return 1
    project_name=$(basename "$project_path")

    # Папки
    src="$project_path/footage"
    dst="$SHOTCUT_PROJECT_DIR/$project_name/proxy"

    mkdir -p "$dst"
    shopt -s nullglob

    # Собираем все видео
    files=("$src"/*.mp4 "$src"/*.mov)
    if [[ ${#files[@]} -eq 0 ]]; then
        echo " No video files found in $src"
        pause
        return 1
    fi

    total=${#files[@]}
    echo " Starting proxy generation: $total file(s) found."

    count=1
    for f in "${files[@]}"; do
        name=$(basename "$f")
        proxy="$dst/${name%.*}_proxy.mp4"

        # Прогресс
        echo "[$count/$total] Processing: $name → $(basename "$proxy")"

        # Генерация прокси
        ffmpeg -y -i "$f" \
            -vf scale=1280:-2 \
            -c:v libx264 -preset veryfast -crf 28 \
            -c:a aac \
            "$proxy"

        ((count++))
    done

    echo
    echo -e " ${GREEN}✓${RESET} Proxy generation complete."
    echo " Proxy folder: $dst"
    pause
}

# =================================
# Audio cleanup
# =================================
audio_cleanup() {

    project_list || return

    project_path=$(project_select) || return 1
    project_name=$(basename "$project_path")

    src="$project_path/footage"
    dst="$AUDIO_PROJECT_DIR/$project_name"

    mkdir -p "$dst"

    echo
    echo " Audio cleanup started..."
    echo

    # собираем список файлов
    mapfile -d '' files < <(
        find "$src" -type f \( \
            -iname "*.mp4" -o \
            -iname "*.mov" -o \
            -iname "*.mkv" -o \
            -iname "*.wav" -o \
            -iname "*.mp3" -o \
            -iname "*.m4a" \
        \) -print0
    )

    total=${#files[@]}

    if (( total == 0 )); then
        echo " No supported media files found in $src"
        pause
        return
    fi

    echo " Found $total file(s)."
    echo

    count=1

    for file in "${files[@]}"; do

        name=$(basename "$file")
        base="${name%.*}"
        output="$dst/${base}_clean.wav"

        echo " [$count/$total] Processing: $name"

        if [[ -f "$output" ]]; then
            echo " Skip (already processed)"
            ((count++))
            continue
        fi

        ffmpeg -y -i "$file" \
            -vn \
            -af "adeclip,adeclick,acompressor,loudnorm" \
            "$output"

        echo " Saved: $(basename "$output")"
        echo

        ((count++))

    done

    echo " Audio cleanup finished."
    pause
}

# =================================
# Auto Sync Audio
# =================================
auto_sync_audio() {

    project_list || return

    project_path=$(project_select) || return 1
    project_name=$(basename "$project_path")

    video_dir="$project_path/footage"
    audio_dir="$AUDIO_PROJECT_DIR/$project_name"
    output_dir="$project_path/edit"

    mkdir -p "$output_dir"

    echo
    echo " Auto Sync Audio started..."
    echo

    mapfile -d '' videos < <(
        find "$video_dir" -type f \( -iname "*.mp4" -o -iname "*.mov" -o -iname "*.mkv" \) -print0
    )

    total=${#videos[@]}

    if (( total == 0 )); then
        echo " No video files found."
        pause
        return
    fi

    echo " Found $total video file(s)."
    echo

    count=1

    for video in "${videos[@]}"; do

        name=$(basename "$video")
        base="${name%.*}"

        clean_audio="$audio_dir/${base}_clean.wav"
        output="$output_dir/${base}_sync.mp4"

        echo " [$count/$total] Processing: $name"

        if [[ ! -f "$clean_audio" ]]; then
            echo " Clean audio not found: ${base}_clean.wav"
            ((count++))
            continue
        fi

        ffmpeg -y \
            -i "$video" \
            -i "$clean_audio" \
            -map 0:v:0 \
            -map 1:a:0 \
            -c:v copy \
            -c:a aac -b:a 192k \
            "$output"

        echo " Synced video saved: $(basename "$output")"
        echo

        ((count++))

    done

    echo " Auto Sync Audio finished."
    pause
}

# =================================
# Batch Scene Split (Smart)
# =================================
# Batch Scene Split (Smart + Preview)
# =================================
batch_scene_split() {

    project_list || return

    project_path=$(project_select) || return 1
    project_name=$(basename "$project_path")

    src="$project_path/edit"
    dst="$project_path/scenes"

    mkdir -p "$dst"

    echo
    echo " Smart Scene Split started..."
    echo

    mapfile -d '' videos < <(
        find "$src" -type f \( -iname "*.mp4" -o -iname "*.mov" -o -iname "*.mkv" \) -print0
    )

    total=${#videos[@]}

    if (( total == 0 )); then
        echo " No video files found."
        pause
        return
    fi

    echo " Found $total video file(s)."
    echo

    count=1

    for video in "${videos[@]}"; do

        name=$(basename "$video")
        base="${name%.*}"

        outdir="$dst/$base"
        preview="$outdir/preview"

        mkdir -p "$outdir"
        mkdir -p "$preview"

        echo " [$count/$total] Processing: $name"

        # --- 1. Поиск сцен и сохранение кадров ---
        ffmpeg -i "$video" \
            -vf "select='gt(scene,0.25)'" \
            -vsync vfr \
            "$preview/scene_%03d.jpg"

        if ! ls "$preview"/*.jpg >/dev/null 2>&1; then
            echo " No scene changes detected — saving first frame"
            ffmpeg -y -i "$video" -frames:v 1 "$preview/scene_001.jpg"
        fi

        # --- 2. Разрезание видео на сегменты ---
        ffmpeg -i "$video" \
            -c copy \
            -f segment \
            -segment_time 10 \
            -reset_timestamps 1 \
            "$outdir/${base}_scene_%03d.mp4"

        for clip in "$outdir/${base}_scene_"*.mp4; do
            ffmpeg -y -i "$clip" -frames:v 1 "$preview/$(basename "$clip" .mp4).jpg"
        done

        echo " Scenes saved in: $outdir"
        echo " Preview frames: $preview"
        echo

        ((count++))

    done

    echo " Scene split finished."
    pause
}

# =================================
# Launch Sshotcut
# =================================
launch_shotcut() {
    if has_flatpak org.shotcut.Shotcut; then
        flatpak run org.shotcut.Shotcut
    else
        echo " Shotcut not installed."
        pause
    fi
}

# =================================
# EXPORT YOUTUBE
# =================================
export_youtube() {

    # Выбор проекта
    project_list || return 1
    project_path=$(project_select) || return 1
    project_name=$(basename "$project_path")

    # Папка с видео для экспорта
    src="$project_path/export"

    # Список доступных видео
    echo " Available files in $src:"
    find "$src" -maxdepth 1 -type f \( -iname "*.mp4" -o -iname "*.mov" \) -print0 | xargs -0 -n1 echo

    read -rp " Input video file (full name from above): " input_file
    input="$src/$input_file"

    if [[ ! -f "$input" ]]; then
        echo " File not found: $input"
        pause
        return 1
    fi

    # Выходной файл
    out="$EXPORT_DIR/${project_name}_youtube_$(date +%s).mp4"

    echo
    echo " Exporting $input_file → $out"
    echo " This may take a while..."

    # Получаем длительность видео в секундах
    duration=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$input")
    duration=${duration%.*}  # округляем вниз

    # Запуск ffmpeg с прогрессом
    ffmpeg -y -i "$input" \
        -c:v libx264 -preset slow -crf 18 \
        -pix_fmt yuv420p -movflags +faststart \
        -c:a aac -b:a 192k "$out" \
        2>&1 | while read -r line; do
            if [[ "$line" =~ time=([0-9:.]+) ]]; then
                # Преобразуем время в секунды
                t=${BASH_REMATCH[1]}
                IFS=: read -r h m s <<< "$t"
                s=${s%.*}
                elapsed=$((10#$h*3600 + 10#$m*60 + 10#$s))
                percent=0
                if (( duration > 0 )); then
                    percent=$(( elapsed * 100 / duration ))
                fi
                printf " \rProgress: %3d%%" "$percent"
            fi
        done

    echo
    cho -e " ${GREEN}✓${RESET} Export created: $out"
    pause
}

# =================================
# ARCHIVE PROJECT
# =================================
archive_project() {

    # Выбор проекта
    project_list || return 1
    project_path=$(project_select) || return 1
    project_name=$(basename "$project_path")

    # Имя архива
    archive="$ARCHIVE_VIDEO_DIR/${project_name}_archive_$(date +%Y%m%d).tar.gz"

    # Проверка существования каталога проекта
    if [[ ! -d "$project_path" ]]; then
        echo " Project directory not found: $project_path"
        pause
        return 1
    fi

    echo
    echo " Archiving project: $project_name → $archive"

    # Мини-прогресс: используем pv, если установлено
    if command -v pv &>/dev/null; then
        tar -cf - -C "$(dirname "$project_path")" "$project_name" | pv -s $(du -sb "$project_path" | cut -f1) | gzip > "$archive"
    else
        # Если pv нет — обычный tar.gz
        tar -czf "$archive" -C "$(dirname "$project_path")" "$project_name"
    fi

    echo
    echo -e " ${GREEN}✓${RESET} Archive saved: $archive"
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
    echo -e "${BOLD}${CYAN}====================================================${RESET}"
    echo -e "               ${BOLD}${CYAN}PRODUCTION MEDIA PANEL${RESET}"
    echo -e "${BOLD}${CYAN}====================================================${RESET}"
    echo -e "${BOLD} System:${RESET}"
    echo "   1) System status"
    echo -e "${BOLD} Projects:${RESET}"
    echo "   2) Project Info"
    echo "   3) Create project"
    echo "   4) Footage ingest from phone"
    echo -e "${BOLD} Production:${RESET}"
    echo "   5) Generate proxy"
    echo "   6) Audio cleanup"
    echo "   7) Auto sync audio"
    echo "   8) Batch Scene Split (Smart Scene Detection)"
    echo "   9) Launch Shotcut"
    echo -e "${BOLD} Export & archive:${RESET}"
    echo "   10) Export YouTube"
    echo "   11) Archive project"
    echo -e "${BOLD} Tools:${RESET}"
    echo "   12) Video tools"
    echo "   13) Graphics tools"
    echo "   14) Audio tools"
    echo
    echo -e " ${RED}0) Exit${RESET}"
    echo -e "${BOLD}${CYAN}====================================================${RESET}"
    read -rp "Select: " main
    case "$main" in
        1) system_status ;;
        2) project_info ;;
        3) project_create ;;
        4) ingest_from_phone ;;
        5) generate_proxy ;;
        6) audio_cleanup ;;
        7) auto_sync_audio ;;
        8) batch_scene_split ;;
        9) launch_shotcut ;;
        10) export_youtube ;;
        11) archive_project ;;
        12) video_tools_menu ;;
        13) graphics_menu ;;
        14) audio_menu ;;

        0) exit 0 ;;
        *) echo "Invalid option"; pause ;;
    esac
done