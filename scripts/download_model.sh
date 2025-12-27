#!/bin/bash
# download_model.sh - 修正版 (忽略鏡頭報錯)

# 1. 環境變數處理
PROJECT_ID=$(echo "$PROJECT_ID" | tr -d '\r' | xargs)
EI_API_KEY=$(echo "$EI_API_KEY" | tr -d '\r' | xargs)

# 2. 定義路徑
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")
MODEL_DIR="$PROJECT_ROOT/models"
MODEL_PATH="$MODEL_DIR/model.eim"

# 顏色定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}📥 正在從雲端部署最新模型...${NC}"

# 3. 確保 models 資料夾存在
mkdir -p "$MODEL_DIR"

# 4. 執行下載
cd "$MODEL_DIR"
echo -e "🚀 開始下載專案 ID ${PROJECT_ID} 的最新模型..."

# ⭐ 關鍵修正：加上 || true 忽略後續找不到鏡頭的報錯
edge-impulse-linux-runner --download-model model.eim --api-key "$EI_API_KEY" || true

# 5. 檢查檔案是否真的存在 (而不看 exit code)
if [ -f "model.eim" ]; then
    chmod +x model.eim
    echo -e "${GREEN}✅ 模型部署成功！路徑: $MODEL_PATH${NC}"
else
    # 如果沒在當前目錄，嘗試從 Edge Impulse 的快取目錄強制抓取 (WSL 穩定備案)
    CACHE_FILE=$(find ~/.ei-linux-runner/models/$PROJECT_ID/ -name "model.eim" | head -n 1)
    if [ -n "$CACHE_FILE" ]; then
        cp "$CACHE_FILE" "$MODEL_DIR/model.eim"
        chmod +x "$MODEL_DIR/model.eim"
        echo -e "${GREEN}✅ 已從快取成功恢復模型！${NC}"
    else
        echo -e "${RED}❌ 錯誤: 找不到模型檔案。${NC}"
        exit 1
    fi
fi
