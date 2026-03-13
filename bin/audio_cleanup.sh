#!/usr/bin/env bash
# ==========================================================
# Production Media Panel — Audio Cleanup Module
# ==========================================================

set -euo pipefail
IFS=$'\n\t'

PROJECT_PATH="$1"

FOOTAGE_DIR="$PROJECT_PATH/footage"
AUDIO_DIR="$PROJECT_PATH/audio_clean"

mkdir -p "$AUDIO_DIR"

echo
echo "Audio cleanup started..."
echo

# Поддерживаемые форматы
EXTENSIONS="mp4|mov|mkv|mp3|wav|m4a"

find "$FOOTAGE_DIR" -type f | while read -r file; do

    if [[ "$file" =~ \.($EXTENSIONS)$ ]]; then

        name=$(basename "$file")
        base="${name%.*}"
        output="$AUDIO_DIR/${base}_clean.wav"

        if [[ -f "$output" ]]; then
            echo "Skip (already processed): $name"
            continue
        fi

        echo "Processing: $name"

        ffmpeg -y -i "$file" \
            -vn \
            -af "adeclip,adeclick,acompressor,loudnorm" \
            "$output"

        echo "Saved: $output"
        echo
    fi

done

echo "Audio cleanup finished."