#!/bin/bash
set -e

# 檢查有沒有給參數 (至少要有一個圖片路徑或目錄)
if [ "$#" -lt 1 ]; then
    echo "❌ 用法錯誤！"
    echo "範例: $0 <圖片路徑1> <圖片路徑2> ..."
    echo "或者使用萬用字元: $0 data/raw_data/*/*.jpg"
    exit 1
fi

# 檢查 API Key
if [ -z "$EI_API_KEY" ]; then
    echo "❌ 錯誤: 找不到 EI_API_KEY，請先設定環境變數！"
    exit 1
fi

echo "🚀 開始自動化批次上傳流程..."

# 遍歷所有傳入的檔案
for FILE in "$@"
do
    if [ -f "$FILE" ]; then
        # ⭐ 自動抓取標籤：取得檔案所在資料夾的名稱
        # 例如: data/coffee/img01.jpg -> 標籤就是 coffee
        AUTO_LABEL=$(basename "$(dirname "$FILE")")
        
        echo "─────────────────────────────────────────"
        echo "檔案: $FILE"
        echo "🏷️  自動偵測標籤: $AUTO_LABEL"

        # 執行上傳
        edge-impulse-uploader \
            --api-key "$EI_API_KEY" \
            --category split \
            --label "$AUTO_LABEL" \
            "$FILE"
    else
        echo "⚠️  警告: $FILE 不是有效的檔案，跳過。"
    fi
done

echo "─────────────────────────────────────────"
echo "✅ 所有圖片已上傳並自動完成分類！"
