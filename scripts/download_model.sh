#!/bin/bash
# download_model.sh - 智慧路徑追蹤版

PROJECT_ID=$(echo "$PROJECT_ID" | tr -d '\r' | xargs)
EI_API_KEY=$(echo "$EI_API_KEY" | tr -d '\r' | xargs)
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")
MODEL_DIR="$PROJECT_ROOT/models"

mkdir -p "$MODEL_DIR"
cd "$MODEL_DIR"

echo -e "\033[1;33m🧹 清理舊模型並強制抓取雲端最新版...\033[0m"
rm -f model.eim

# 1. 執行下載 (忽略鏡頭報錯)
edge-impulse-linux-runner --download-model model.eim --api-key "$EI_API_KEY" > /dev/null 2>&1 || true

# 2. 🔥 核心修正：從系統快取中「撈」出最新版
# 因為 runner 剛才日誌說它把檔案存到了 ~/.ei-linux-runner/models/
LATEST_EIM=$(find ~/.ei-linux-runner/models/$PROJECT_ID/ -name "model.eim" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -f2- -d" ")

if [ -n "$LATEST_EIM" ]; then
    cp "$LATEST_EIM" "$MODEL_DIR/model.eim"
    chmod +x "$MODEL_DIR/model.eim"
    echo -e "\033[0;32m✅ 偵測到最新模型路徑: $LATEST_EIM\033[0m"
    echo -e "\033[0;32m✅ 模型已成功同步至專案目錄！\033[0m"
    echo -ne "📌 新模型 MD5: "
    md5sum "$MODEL_DIR/model.eim"
else
    echo -e "\033[0;31m❌ 嚴重錯誤：系統快取中找不到任何 .eim 檔案。\033[0m"
    exit 1
fi
