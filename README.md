# 🚀 Edge Impulse MLOps 自動化系統 (Linux 系統管理期末專案)

## 👥 小組成員與分工
* **組員 A [蕭翔遠]**：技術開發負責人。
    * 負責所有 Shell Script 腳本編寫與自動化流程設計。
    * 負責 Edge Impulse RESTful API 整合與即時監控 (Polling) 邏輯。
    * 負責 Git 版本控制與 GitHub 專案管理。
* **組員 B [張庭崧]**：專案管理與文檔負責人。
    * 負責期末專案投影片 (PPT) 製作與系統簡報。

---

## 🎯 專案簡介
本專案實作了一套基於 Linux 環境的 **MLOps (Machine Learning Operations)** 自動化流水線。
我們透過自定義的 Shell 腳本，將 Edge Impulse 雲端 AI 平台與本地端 Linux 推論引擎完美結合，解決了傳統人工操作頻繁、模型訓練狀態難以監控的痛點。

## 🛠️ 核心自動化功能
1.  **環境自動校驗 (`check_env.sh`)**：自動偵測並確保系統具備 `jq`、`node`、`python3` 等必要運作環境。
2.  **雲端訓練監控 (`retrain.sh`)**：
    * 透過 RESTful API 遠端觸發模型訓練。
    * **技術亮點**：實作「動態計時監控機制」，克服了雲端 API 與本地端狀態同步的延遲問題，並具備即時視覺化反饋。
3.  **一鍵流水線 (`ml_pipeline.sh`)**：實現從「數據上傳 -> 雲端訓練 -> 模型部署 -> 本地推論」的全自動化流程。
4.  **本地推論引擎 (`run_inference.sh`)**：自動加載最新訓練之 `.eim` 模型，於本地端進行物件偵測測試。
