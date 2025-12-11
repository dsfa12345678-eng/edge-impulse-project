#!/bin/bash
set -e

if [ -z "$EI_API_KEY" ]; then
    echo "❌ 請先設定 EI_API_KEY"
    exit 1
fi

mkdir -p data/train

echo "=== 📦 火力全開：準備上傳 20 張圖片 ==="

# --- 10 張咖啡圖片 ---
coffee_urls=(
    "https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=400"
    "https://images.unsplash.com/photo-1497935586351-b67a49e012bf?w=400"
    "https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=400"
    "https://images.unsplash.com/photo-1511920170033-f8396924c348?w=400"
    "https://images.unsplash.com/photo-1507133750069-775b0683300d?w=400"
    "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=400"
    "https://images.unsplash.com/photo-1442512595367-f2d30a2919d0?w=400"
    "https://images.unsplash.com/photo-1506372023823-741c83b836fe?w=400"
    "https://images.unsplash.com/photo-1525648199074-cee30ba79a4a?w=400"
    "https://images.unsplash.com/photo-1498804103079-a6351b050096?w=400"
)

echo "☕ 正在處理咖啡..."
count=1
for url in "${coffee_urls[@]}"; do
    filename="data/train/coffee_v2_$count.jpg"
    # -f 參數可以讓 curl 在失敗時不存檔
    curl -f -L -s -o "$filename" "$url" && ./scripts/upload_data.sh coffee "$filename" || echo "⚠️ 下載失敗，跳過一張..."
    ((count++))
done

# --- 10 張檯燈圖片 ---
lamp_urls=(
    "https://images.unsplash.com/photo-1565814329452-e1efa11c5b89?w=400"
    "https://images.unsplash.com/photo-1507473888900-52e1ad146957?w=400"
    "https://images.unsplash.com/photo-1513506003011-3b3215099b83?w=400"
    "https://images.unsplash.com/photo-1540932296774-3ed6d235332c?w=400"
    "https://images.unsplash.com/photo-1517991104123-1d56a6e81ed9?w=400"
    "https://images.unsplash.com/photo-1534135890920-fe25206c9a33?w=400"
    "https://images.unsplash.com/photo-1543512214-318c77a799bf?w=400"
    "https://images.unsplash.com/photo-1510074377623-8cf13fb86c08?w=400"
    "https://images.unsplash.com/photo-1505330622279-bf7d7fc918f4?w=400"
    "https://images.unsplash.com/photo-1567425123977-9a9972332924?w=400"
)

echo "💡 正在處理檯燈..."
count=1
for url in "${lamp_urls[@]}"; do
    filename="data/train/lamp_v2_$count.jpg"
    curl -f -L -s -o "$filename" "$url" && ./scripts/upload_data.sh lamp "$filename" || echo "⚠️ 下載失敗，跳過一張..."
    ((count++))
done

echo "=== 🎉 大功告成！請去網頁確認數量 ==="
