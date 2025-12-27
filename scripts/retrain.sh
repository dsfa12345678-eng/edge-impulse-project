#!/bin/bash
# =================================================================
# 腳本名稱: retrain.sh (任務完成即認定成功版)
# 功能: 鎖定 ID -> 觸發訓練 -> 偵測到結束標記即完成
# =================================================================

# 1. 基礎設定與顏色定義
set -e
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== Edge Impulse 自動化訓練監控系統 ===${NC}"

# 2. 環境變數清理
PROJECT_ID=$(echo "$PROJECT_ID" | tr -d '\r' | xargs)
EI_API_KEY=$(echo "$EI_API_KEY" | tr -d '\r' | xargs)

if [ -z "$EI_API_KEY" ] || [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}❌ 錯誤: 找不到關鍵環境變數，請確認執行過 export 設定。${NC}"
    exit 1
fi

# 3. 取得 Impulse ID
echo -e "${YELLOW}🔍 正在偵測專案 Impulse ID...${NC}"
RAW_IMPULSE=$(curl -s --max-time 10 -X GET "https://studio.edgeimpulse.com/v1/api/$PROJECT_ID/impulse" \
  -H "x-api-key: $EI_API_KEY" \
  -H "Content-Type: application/json")

DETECTED_ID=$(echo "$RAW_IMPULSE" | jq -r '.impulse.learnBlocks[0].id // empty' | tr -d '\r')

if [ -z "$DETECTED_ID" ]; then
    echo -e "${RED}❌ 錯誤: 無法抓取 ID。${NC}"
    exit 1
fi
echo -e "${GREEN}√ 已鎖定學習區塊 ID: $DETECTED_ID${NC}"

# 4. 觸發雲端訓練
TRAIN_CONFIG='{"numEpochs": 10, "learningRate": 0.005}'
URL="https://studio.edgeimpulse.com/v1/api/$PROJECT_ID/jobs/train/keras/$DETECTED_ID"

echo -e "${YELLOW}🚀 正在啟動雲端訓練任務...${NC}"
RESPONSE=$(curl -s --max-time 15 -X POST "$URL" \
  -H "x-api-key: $EI_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$TRAIN_CONFIG")

JOB_ID=$(echo "$RESPONSE" | jq -r '.id // empty')

if [ -z "$JOB_ID" ] || [ "$JOB_ID" == "null" ]; then
    echo -e "${RED}❌ 啟動失敗！API 回應: $RESPONSE${NC}"
    exit 1
fi

echo -e "${GREEN}✅ 任務成功啟動！Job ID: $JOB_ID${NC}"
echo -e "${BLUE}---------------------------------------------------${NC}"

# 5. ⭐ 核心監控迴圈 (簡化判斷邏輯) ⭐
SECONDS=0 

while true; do
    # 獲取狀態
    JOB_STATUS_RAW=$(curl -s --max-time 10 -X GET "https://studio.edgeimpulse.com/v1/api/$PROJECT_ID/jobs/$JOB_ID/status" \
      -H "x-api-key: $EI_API_KEY" -H "Accept: application/json") || {
        sleep 5
        continue
    }

    # 解析狀態
    STATUS=$(echo "$JOB_STATUS_RAW" | jq -r '.job.status // "running"')
    FINISHED=$(echo "$JOB_STATUS_RAW" | jq -r '.job.finished // empty')
    
    # ⭐ 簡化後的判斷邏輯：
    # 只要偵測到「結束時間 (FINISHED)」有值，或是「狀態 (STATUS)」顯示已完成，就直接算成功。
    if [ -n "$FINISHED" ] || [[ "$STATUS" == "finished" ]]; then
        echo -e "\n${GREEN}🎊 雲端訓練已偵測到完成信號！ (耗時: ${SECONDS}s)${NC}"
        break
    elif [[ "$STATUS" == "failed" ]]; then
        echo -e "\n${RED}❌ 雲端任務明確回報失敗。${NC}"
        exit 1
    else
        # 顯示動態計時進度條
        printf "\r${YELLOW}⏳ 訓練進行中... [已耗時: ${SECONDS}s] ${BLUE}▓${NC}"
        sleep 5
    fi
done

echo -e "${BLUE}---------------------------------------------------${NC}"
# 6. 輸出最終資訊
echo -e "🔗 雲端 Job 連結: https://studio.edgeimpulse.com/studio/${PROJECT_ID}/jobs/${JOB_ID}"
echo -e "${GREEN}✅ retrain.sh 任務圓滿結束。${NC}"
