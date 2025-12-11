#!/bin/bash
set -e

# 檢查有沒有給參數 (圖片路徑)
if [ "$#" -lt 2 ]; then
    echo "❌ 用法錯誤！"
    echo "範例: $0 <標籤名> <圖片路徑>"
    echo "例如: $0 coffee data/train/coffee.jpg"
    exit 1
fi

LABEL=$1
shift # 把第一個參數(標籤)拿掉，剩下的都是圖片

# 再次確認 API Key 都在
if [ -z "$EI_API_KEY" ]; then
    echo "❌ 錯誤: 找不到 EI_API_KEY，請先設定！"
    exit 1
fi

echo "🚀 正在將圖片上傳到 Edge Impulse..."
echo "🏷️  標籤: $LABEL"

# 呼叫官方工具上傳
# --category split 代表自動幫你分 80% 訓練、20% 測試 (報告加分項!)
edge-impulse-uploader --api-key "$EI_API_KEY" --category split --label "$LABEL" "$@"

echo "✅ 上傳作業完成！"
