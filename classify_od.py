#!/usr/bin/env python3
import sys
import cv2
import numpy as np
import os
from edge_impulse_linux.runner import ImpulseRunner

def main():
    if len(sys.argv) != 3:
        print("使用方式: python3 classify_od.py <model.eim> <圖片路徑>")
        sys.exit(1)

    model_path = sys.argv[1]
    image_path = sys.argv[2]

    # 初始化 Runner
    runner = ImpulseRunner(model_path)
    try:
        model_info = runner.init()
        # 動態從模型中取得要求的長寬
        width = model_info['model_parameters']['image_input_width']
        height = model_info['model_parameters']['image_input_height']
        
        print(f"==================================================")
        print(f"🚀 啟動 Edge AI 本地推論引擎...")
        print(f"專案規格: {width}x{height} px, 單通道(Grayscale)")
        print(f"==================================================")

        # 1. 讀取原始圖片
        img = cv2.imread(image_path)
        if img is None:
            print(f"❌ 錯誤: 無法讀取圖片路徑: {image_path}")
            sys.exit(1)

        # 2. 影像預處理
        # 轉為灰階 (模型要求單通道)
        img_gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        
        # 縮放到模型要求的尺寸 (如 96x96)
        img_resized = cv2.resize(img_gray, (width, height))

        # ⭐ 關鍵修正點：
        # 對於 int8 量化模型，傳入 0-255 的原始像素列表 (int) 即可。
        # 不要執行 / 255.0 的歸一化，SDK 內部會處理。
        features = img_resized.flatten().tolist()

        # 3. 執行推論
        result = runner.classify(features)

        # 4. 處理與顯示結果
        if 'classification' in result['result']:
            scores = result['result']['classification']
            # 取得分數最高的類別
            max_label = max(scores, key=scores.get)
            confidence = scores[max_label]

            print(f"📸 測試圖片: {os.path.basename(image_path)}")
            print(f"🎯 推論結果: {max_label}")
            print(f"📈 信心指數: {confidence:.2f}")
            print(f"--------------------------------------------------")

            # 在原圖上繪製結果 (用於視覺化報告)
            h, w = img.shape[:2]
            label_text = f"{max_label}: {confidence:.2f}"
            cv2.putText(img, label_text, (20, 50), cv2.FONT_HERSHEY_SIMPLEX, 
                        1.2, (0, 0, 255), 3)

            # 存檔
            os.makedirs("results", exist_ok=True)
            output_path = "results/result.jpg"
            cv2.imwrite(output_path, img)
            print(f"✅ 結果圖片已存至: {output_path}")

    except Exception as e:
        print(f"❌ 發生異常: {e}")
    finally:
        if runner:
            runner.stop()

if __name__ == "__main__":
    main()
