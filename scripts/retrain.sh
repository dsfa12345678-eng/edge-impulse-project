#!/bin/bash
# auto_retrain_lite.sh - 僅觸發訓練版 (無監控)

# 1. 檢查必要工具
if ! command -v jq &> /dev/null; then
    echo "錯誤: 未安裝 jq。請執行 sudo apt install -y jq 進行安裝"
    exit 1
fi

# 2. 檢查環境變數 (清理前後空白與換行)
PROJECT_ID=$(echo "$PROJECT_ID" | tr -d '\r' | xargs)
EI_API_KEY=$(echo "$EI_API_KEY" | tr -d '\r' | xargs)

if [ -z "$EI_API_KEY" ] || [ -z "$PROJECT_ID" ]; then
    echo "錯誤: 請先設定 EI_API_KEY 和 PROJECT_ID 環境變數"
    exit 1
fi

echo "=== Edge Impulse 自動化訓練腳本 (Lite) ==="
echo "專案 ID: '$PROJECT_ID'"

# 3. 取得 Impulse ID
echo "正在鎖定學習區塊..."
RAW_RESPONSE=$(curl -s -X GET "https://studio.edgeimpulse.com/v1/api/$PROJECT_ID/impulse" \
  -H "x-api-key: $EI_API_KEY" \
  -H "Content-Type: application/json")

DETECTED_ID=$(echo "$RAW_RESPONSE" | jq -r '.impulse.learnBlocks[0].id' | tr -d '\r')

if [ -z "$DETECTED_ID" ] || [ "$DETECTED_ID" == "null" ]; then
    echo "X 錯誤: 無法抓到 ID。請確認 Impulse 已建立並儲存。"
    exit 1
else
    echo "√ 鎖定學習區塊 ID: $DETECTED_ID"
fi

# 4. 準備訓練參數 (使用 API 規範的 camelCase)
TRAIN_CONFIG=$(cat <<EOF
{
  "numEpochs": 10,
  "learningRate": 0.005,
  "validationSetSize": 0.2,
  "inputAugmentation": {
    "enabled": false
  }
}
EOF
)

# 5. 發送訓練請求
URL="https://studio.edgeimpulse.com/v1/api/$PROJECT_ID/jobs/train/keras/$DETECTED_ID"
echo "正在觸發雲端訓練..."

RESPONSE=$(curl -s -X POST "$URL" \
  -H "x-api-key: $EI_API_KEY" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "$TRAIN_CONFIG")

# 6. 檢查結果並輸出
SUCCESS=$(echo "$RESPONSE" | jq -r '.success' 2>/dev/null)

if [ "$SUCCESS" == "true" ]; then
    # 只保留數字，確保 ID 顯示乾淨
    JOB_ID=$(echo "$RESPONSE" | jq -r '.id' | tr -cd '0-9')
    
    echo "---------------------------------------------------"
    echo "★ 訓練已成功啟動！Job ID: '$JOB_ID'"
    echo "請點擊以下連結查看雲端進度："
    echo "👉 https://studio.edgeimpulse.com/studio/$PROJECT_ID/jobs/$JOB_ID"
    echo "---------------------------------------------------"
    echo "腳本任務完成，即將退出。"
else
    echo "X 訓練啟動失敗"
    echo "伺服器回應: $RESPONSE"
    exit 1
fi
