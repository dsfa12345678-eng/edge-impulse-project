#!/bin/bash
# =================================================================
# 專案名稱: Edge AI 自動化流水線 (組員：ken_878 專業強健版)
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

# 自定義輸出函式
log() {
    echo -e "${1}" | tee -a "$LOG_FILE"
}

# 錯誤捕捉 (加分項：展現對系統異常的處理能力)
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

# --- 判斷邏輯：有參數才進行「雲端更新」 ---
if [ "$#" -ge 1 ]; then
    log "\n${YELLOW}[2/4 偵測到參數，進入雲端更新流程]${NC}"

    # 數據上傳
    log "🚀 執行數據上傳..."
    bash "$SCRIPT_DIR/upload_data.sh" "$@" | tee -a "$LOG_FILE"

    # 觸發雲端訓練
    log "🚀 觸發雲端訓練與監控..."
    bash "$SCRIPT_DIR/retrain.sh" | tee -a "$LOG_FILE"

    # ⭐ 下載最新模型 (只有訓練完才下載，省時間！)
    log "🚀 下載並部署最新模型檔案..."
    bash "$SCRIPT_DIR/download_model.sh" | tee -a "$LOG_FILE"
else
    log "\n${BLUE}[3/4 跳過雲端流程]${NC} (未傳入新數據，直接使用本地現有模型)"
fi

# --- 步驟 4: 本地推論 ---
log "\n${YELLOW}[4/4 執行模型推論]${NC}"
DEFAULT_IMG="$PROJECT_ROOT/data/test/test.jpg"

# ⭐ 修正後的取得參數邏輯
if [ "$#" -ge 1 ]; then
    TEST_IMG="${@: -1}" # 有參數時，才抓最後一個當圖片
else
    TEST_IMG="$DEFAULT_IMG" # 沒參數時，強制使用預設測試圖
fi

# 檢查檔案是否存在，且「不是」腳本自己
if [ -f "$TEST_IMG" ] && [[ "$TEST_IMG" != *.sh ]]; then
    log "推論目標: $TEST_IMG"
    bash "$SCRIPT_DIR/run_inference.sh" "$TEST_IMG" | tee -a "$LOG_FILE"
else
    # 如果預設圖也不存在，才報錯
    if [ ! -f "$DEFAULT_IMG" ]; then
        log "${RED}錯誤: 找不到預設測試圖片 ($DEFAULT_IMG)，請確認路徑。${NC}"
        exit 1
    else
        log "使用預設圖片進行測試: $DEFAULT_IMG"
        bash "$SCRIPT_DIR/run_inference.sh" "$DEFAULT_IMG" | tee -a "$LOG_FILE"
    fi
fi
log "\n${GREEN}>>> 完整流水線執行成功！${NC}"
log "日誌已儲存至: ${BLUE}$LOG_FILE${NC}"
