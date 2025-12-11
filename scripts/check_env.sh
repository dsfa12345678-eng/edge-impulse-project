#!/bin/bash
echo "=== 環境檢查開始 ==="

# 1. 檢查必要軟體
for cmd in python3 curl git node edge-impulse-uploader; do
    if command -v $cmd &> /dev/null; then
        echo "✅ $cmd 已安裝"
    else
        echo "❌ $cmd 未安裝 (請安裝)"
        # 這裡不強制退出，讓它跑完檢查
    fi
done

# 2. 檢查 API Key
if [ -z "$EI_API_KEY" ]; then
    echo "⚠️  警告: 未設定 EI_API_KEY 環境變數 (上傳功能可能無法使用)"
else
    echo "✅ EI_API_KEY 已設定"
fi

echo "=== 環境檢查完成 ==="
