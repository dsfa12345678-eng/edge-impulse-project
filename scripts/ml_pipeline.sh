#!/bin/bash
# =================================================================
# 專案名稱: Edge AI 自動化流水線 (修正版)
# =================================================================

set -e

# 1. 自動定位目錄
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")

# 2. 日誌設定
LOG_DIR="$PROJECT_ROOT/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/pipeline_$(date +%Y%m%d_%H%M).log"

# 顏色定義
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${1}" | tee -a "$LOG_FILE"
}

# 錯誤捕捉
trap 'log "${RED}❌ 流程中斷！詳細錯誤請見日誌: $LOG_FILE${NC}";' ERR

log "${BLUE}>>> 啟動 Edge AI 自動化流水線 [$(date)]${NC}"

# --- 步驟 0: 環境變數檢查 ---
log "\n${YELLOW}[0/5 檢查環境變數]${NC}"
[ -z "$EI_API_KEY" ] || [ -z "$PROJECT_ID" ] && { log "${RED}錯誤: 變數未設定${NC}"; exit 1; }
log "${GREEN}變數檢查通過：Project ID = $PROJECT_ID${NC}"

# --- 步驟 1: 環境檢查 ---
log "\n${YELLOW}[1/5 執行環境檢查腳本]${NC}"
bash "$SCRIPT_DIR/check_env.sh" | tee -a "$LOG_FILE"

# --- 步驟 2: 互動式入庫選單 ---
if [ "$#" -eq 0 ]; then
    log "\n${BLUE}[2/5 進入資料入庫選單]${NC}"
    NEW_DATA_PATH="$PROJECT_ROOT/data/new_data"
    options=($(ls -d "$NEW_DATA_PATH"/*/ 2>/dev/null | xargs -n 1 basename))

    if [ ${#options[@]} -eq 0 ]; then
        log "${YELLOW}提示: 無待處理資料。${NC}"
        choice="q"
    else
        echo -e "${YELLOW}請選擇操作：${NC}"
        for i in "${!options[@]}"; do echo -e "$((i+1))) 🆕 入庫並訓練: ${options[$i]}"; done
        echo -e "$(( ${#options[@]} + 1 ))) 🚀 全部入庫 (All)"
        echo -e "q) ⚡ 直接執行推論"
        read -p "請輸入選項: " choice
    fi
    # ... (前面選單部分) ...
    case $choice in
        q) log "${GREEN}進入快速推論模式${NC}" ;;
        [0-9]*)
            if [ "$choice" -le "${#options[@]}" ]; then
                selected="${options[$((choice-1))]}"
                bash "$SCRIPT_DIR/auto_label.sh" "$selected"
                # ⭐ 關鍵修正：從檔案讀取「剛剛搬移的清單」並設為參數
                if [ -f "$LOG_DIR/last_moved.txt" ]; then
                    set -- $(cat "$LOG_DIR/last_moved.txt")
                fi
            elif [ "$choice" -eq "$(( ${#options[@]} + 1 ))" ]; then
                bash "$SCRIPT_DIR/auto_label.sh" "all"
                if [ -f "$LOG_DIR/last_moved.txt" ]; then
                    set -- $(cat "$LOG_DIR/last_moved.txt")
                fi
            fi
            ;;
        *) exit 1 ;;
    esac
else
    log "\n${BLUE}[2/5 模式：手動推論模式]${NC}"
fi

# --- 步驟 3: 雲端更新 ---
# 只有當參數包含 data/train (代表是剛入庫的資料) 時才觸發上傳訓練
if [ "$#" -ge 1 ] && [[ "$1" == *"/data/train/"* ]]; then
    log "\n${YELLOW}[3/5 啟動雲端同步]${NC}"
    
    # 執行上傳 (現在 $@ 是檔案列表了)
    bash "$SCRIPT_DIR/upload_data.sh" "$@" | tee -a "$LOG_FILE"

    bash "$SCRIPT_DIR/retrain.sh" | tee -a "$LOG_FILE"

    log "📦 要求雲端打包模型..."
    curl -s -X GET -H "x-api-key: $EI_API_KEY" \
        "https://studio.edgeimpulse.com/v1/api/$PROJECT_ID/deployment/download?type=linux-x86_64" > /dev/null

    log "⏳ 等待打包完成 (45s)..."
    sleep 45

    bash "$SCRIPT_DIR/download_model.sh" | tee -a "$LOG_FILE"
fi

# --- 步驟 4: 模型推論 ---
log "\n${YELLOW}[4/5 執行模型推論]${NC}"
DEFAULT_IMG="$PROJECT_ROOT/data/test/test.jpg"

if [ "$#" -ge 1 ]; then
    # 如果是多個檔案，取最後一個 (剛入庫的那張)
    TEST_IMG="${@: -1}"
    # 如果最後一個是目錄，就進去找最新的一張
    if [ -d "$TEST_IMG" ]; then
        TEST_IMG=$(find "$TEST_IMG" -name "*.jpg" | sort -r | head -n 1)
    fi
else
    TEST_IMG="$DEFAULT_IMG"
fi

log "推論目標: $TEST_IMG"
bash "$SCRIPT_DIR/run_inference.sh" "$TEST_IMG" | tee -a "$LOG_FILE"

log "\n${GREEN}>>> 完整流水線執行成功！${NC}"
