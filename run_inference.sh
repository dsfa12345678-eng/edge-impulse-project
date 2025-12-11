#!/bin/bash
# run_inference.sh - 自動化推論腳本

# 1. 設定變數 (這裡設定您的預設檔案)
MODEL_PATH="./model.eim"
SCRIPT_PATH="classify_od.py"

# 如果使用者有提供圖片路徑就用使用者的，否則使用預設的
if [ "$1" != "" ]; then
    IMAGE_PATH="$1"
else
    IMAGE_PATH="data/train/coffee_v2_1.jpg"
fi

# 2. 檢查必要檔案是否存在
if [ ! -f "$MODEL_PATH" ]; then
    echo "錯誤: 找不到模型檔案 $MODEL_PATH"
    exit 1
fi

if [ ! -f "$SCRIPT_PATH" ]; then
    echo "錯誤: 找不到 Python 腳本 $SCRIPT_PATH"
    exit 1
fi

# 3. 確保模型有執行權限 (很重要!)
chmod +x "$MODEL_PATH"

# 4. 執行推論
echo "=================================="
echo "正在對 $IMAGE_PATH 進行推論..."
echo "=================================="

python3 "$SCRIPT_PATH" "$MODEL_PATH" "$IMAGE_PATH"

echo "=================================="
echo "完成！請檢查 result.jpg"
