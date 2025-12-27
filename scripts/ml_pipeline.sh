#!/bin/bash

# =================================================================
# 專案名稱: Edge AI 自動化流水線 (組員：ken_878 專用版)
# =================================================================

set -e

# 1. 自動定位目錄：不管你在哪裡執行此腳本，都能找到同目錄下的其他腳本
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")

# 2. 日誌設定：建議將 logs 放在專案根目錄，這比較符合 Linux 標準
LOG_DIR="$PROJECT_ROOT/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/pipeline_$(date +%Y%m%d_%H%M).log"

# 顏色定義
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 自定義輸出函式：同時顯示並記錄
log() {
    echo -e "${1}" | tee -a "$LOG_FILE"
}

# 錯誤捕捉
trap 'log "${RED}❌ 流程中斷！詳細錯誤請見日誌: $LOG_FILE${NC}";' ERR

log "${BLUE}>>> 啟動 Edge AI 自動化流水線 [$(date)]${NC}"

# --- 步驟 0: 環境變數預檢查 ---
log "\n${YELLOW}[0/4 檢查環境變數]${NC}"
FAILED=0
[ -z "$EI_API_KEY" ] && { log "${RED}錯誤: 缺少 EI_API_KEY${NC}"; FAILED=1; }
[ -z "$PROJECT_ID" ] && { log "${RED}錯誤: 缺少 PROJECT_ID${NC}"; FAILED=1; }

if [ $FAILED -eq 1 ]; then
    log "請執行: export EI_API_KEY='your_key' 及 export PROJECT_ID='your_id'"
    exit 1
fi
log "${GREEN}變數檢查通過：Project ID = $PROJECT_ID${NC}"

# --- 步驟 1: 環境檢查 ---
log "\n${YELLOW}[1/4 執行環境檢查腳本]${NC}"
bash "$SCRIPT_DIR/check_env.sh" | tee -a "$LOG_FILE"

# --- 步驟 2: 數據上傳 (有參數才執行) ---
if [ "$#" -ge 1 ]; then
    log "\n${YELLOW}[2/4 執行數據上傳]${NC}"
    # 如果你有 bulk_upload.sh 也可以換成它
    bash "$SCRIPT_DIR/upload_data.sh" "$@" | tee -a "$LOG_FILE"

    # --- 步驟 3: 觸發雲端訓練 ---
    log "\n${YELLOW}[3/4 觸發雲端訓練]${NC}"
    bash "$SCRIPT_DIR/retrain.sh" | tee -a "$LOG_FILE"
else
    log "\n${BLUE}[跳過步驟 2 & 3]${NC} (未傳入圖片參數，僅執行環境與推論檢查)"
fi

# --- 步驟 4: 本地推論 ---
log "\n${YELLOW}[4/4 執行模型推論]${NC}"
# 優先使用你傳入的最後一個參數作為圖片，否則用預設路徑
DEFAULT_IMG="$PROJECT_ROOT/data/test/test.jpg"
TEST_IMG="${@: -1}" # 取得最後一個參數

if [ ! -f "$TEST_IMG" ]; then
    TEST_IMG="$DEFAULT_IMG"
fi

if [ -f "$TEST_IMG" ]; then
    log "推論目標: $TEST_IMG"
    bash "$SCRIPT_DIR/run_inference.sh" "$TEST_IMG" | tee -a "$LOG_FILE"
else
    log "${RED}警告: 找不到測試圖片，跳過推論。${NC}"
fi

log "\n${GREEN}>>> 完整流水線執行成功！${NC}"
log "日誌已儲存至: ${BLUE}$LOG_FILE${NC}"
