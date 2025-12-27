#!/bin/bash
echo "=== 環境檢查開始 ==="

# 1. 檢查必要軟體
for cmd in python3 curl git node edge-impulse-uploader; do
    if command -v $cmd &> /dev/null; then
        echo "✅ $cmd 已安裝"
    else
        echo "❌ $cmd 未安裝 (請安裝)"
    fi
done

# 2. 檢查 API Key (敏感資訊檢查)
if [ -z "$EI_API_KEY" ]; then
    echo "⚠️  警告: 未設定 EI_API_KEY 環境變數 (上傳功能可能無法使用)"
else
    echo "✅ EI_API_KEY 已設定"
fi

# 3. 檢查 PROJECT_ID (專案目標檢查)
if [ -z "$PROJECT_ID" ]; then
    echo "⚠️  警告: 未設定 PROJECT_ID 環境變數 (自動化流程將找不到目標專案)"
else
    echo "✅ PROJECT_ID 已設定"
fi

echo "=== 環境檢查完成 ==="
