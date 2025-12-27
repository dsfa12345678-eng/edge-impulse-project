#!/bin/bash
# =================================================================
# 腳本名稱: run_inference.sh
# 描述: 自動化執行 Edge Impulse 本地物件偵測推論
# 適用環境: WSL / Linux
# =================================================================

# 1. 自動定位目錄 (確保腳本在任何地方執行都能找到正確路徑)
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")

# 2. 定義模型與程式路徑 (根據你的目錄結構)
MODEL_PATH="$PROJECT_ROOT/models/model.eim"
PYTHON_SCRIPT="$PROJECT_ROOT/classify_od.py"

# 顏色定義 (讓展示時的終端機輸出更美觀，加分項)
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 3. 處理圖片路徑 (邏輯：如果有參數就用參數，沒有就用預設值)
if [ -n "$1" ]; then
    # 使用 realpath 確保轉成絕對路徑，避免 WSL 讀取錯誤
    IMAGE_PATH=$(realpath "$1")
else
    # 你可以修改這個路徑作為預設的測試圖
    IMAGE_PATH="$PROJECT_ROOT/data/test/test.jpg"
fi

echo -e "${BLUE}==================================================${NC}"
echo -e "${YELLOW}🚀 啟動 Edge AI 本地推論引擎...${NC}"
echo -e "${BLUE}==================================================${NC}"

# 4. 系統檢查 (Linux 管理重點：執行前的環境驗證)

# 檢查模型檔案是否存在
if [ ! -f "$MODEL_PATH" ]; then
    echo -e "${RED}❌ 錯誤: 找不到模型檔案！${NC}"
    echo -e "預期位置: $MODEL_PATH"
    echo -e "提示: 請確保執行過 ml_pipeline.sh 或手動下載模型到 models/ 資料夾。"
    exit 1
fi

# 檢查 Python 腳本是否存在
if [ ! -f "$PYTHON_SCRIPT" ]; then
    echo -e "${RED}❌ 錯誤: 找不到推論腳本 $PYTHON_SCRIPT${NC}"
    exit 1
fi

# 檢查測試圖片是否存在
if [ ! -f "$IMAGE_PATH" ]; then
    echo -e "${RED}❌ 錯誤: 找不到目標圖片 $IMAGE_PATH${NC}"
    exit 1
fi

# 5. 確保模型具備執行權限 (WSL 下下載的檔案常需此步驟)
chmod +x "$MODEL_PATH"

# 6. 執行推論
echo -e "📅 執行時間: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "🤖 使用模型: ${GREEN}$MODEL_PATH${NC}"
echo -e "📸 測試圖片: ${GREEN}$IMAGE_PATH${NC}"
echo -e "${YELLOW}--------------------------------------------------${NC}"

# 呼叫 Python 程式 (採用你的程式所支援的 Positional Arguments 格式)
# 格式: python3 <腳本> <模型路徑> <圖片路徑>
python3 "$PYTHON_SCRIPT" "$MODEL_PATH" "$IMAGE_PATH"

# 取得 Python 執行的結果狀態 (0 代表成功)
RESULT=$?

echo -e "${YELLOW}--------------------------------------------------${NC}"

if [ $RESULT -eq 0 ]; then
    echo -e "${GREEN}✅ 推論執行成功！${NC}"
    echo -e "💡 提示: 請查看專案根目錄下的結果圖片 (例如 result.jpg)。"
else
    echo -e "${RED}❌ 推論執行過程中發生錯誤。${NC}"
    exit 1
fi

echo -e "${BLUE}==================================================${NC}"
