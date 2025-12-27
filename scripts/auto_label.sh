#!/bin/bash
# auto_label.sh - 支援增量追蹤版

PROJECT_ROOT=$(cd "$(dirname "$0")/.." && pwd)
TRAIN_DIR="$PROJECT_ROOT/data/train"
NEW_DATA_DIR="$PROJECT_ROOT/data/new_data"
# ⭐ 用來記錄這次搬了哪些檔案
LOG_DIR="$PROJECT_ROOT/logs"
mkdir -p "$LOG_DIR"
TMP_LIST="$LOG_DIR/last_moved.txt"
> "$TMP_LIST" # 每次執行前先清空

TARGET_LABEL=$1

process_label() {
    local label=$1
    local src="$NEW_DATA_DIR/$label"
    local dst="$TRAIN_DIR/$label"

    [ ! -d "$src" ] && return
    
    shopt -s nocaseglob
    local new_files=("$src"/*.jpg "$src"/*.jpeg)
    [ ! -e "${new_files[0]}" ] && { shopt -u nocaseglob; return; }

    mkdir -p "$dst"
    local last_idx=$(ls "$dst/${label}_"*.jpg 2>/dev/null | sed "s/.*${label}_\([0-9]*\)\.jpg/\1/" | sort -n | tail -1)
    [ -z "$last_idx" ] && last_idx=-1
    local next_idx=$((last_idx + 1))

    for file in "${new_files[@]}"; do
        if [ -f "$file" ]; then
            local target_path="$dst/${label}_${next_idx}.jpg"
            mv "$file" "$target_path"
            # ⭐ 關鍵：紀錄新位置
            echo "$target_path" >> "$TMP_LIST"
            echo "✅ 入庫: ${label}_${next_idx}.jpg"
            next_idx=$((next_idx + 1))
        fi
    done
    shopt -u nocaseglob
}

# 判斷 all 或單一類別
if [ "$TARGET_LABEL" == "all" ]; then
    for d in "$NEW_DATA_DIR"/*/; do process_label "$(basename "$d")"; done
else
    process_label "$TARGET_LABEL"
fi
