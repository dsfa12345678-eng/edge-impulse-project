#!/usr/bin/env python3
import sys
import cv2
import numpy as np
from edge_impulse_linux.runner import ImpulseRunner

def main():
    if len(sys.argv) != 3:
        print("使用方式: python3 classify_od.py <model.eim> <圖片路徑>")
        sys.exit(1)

    model_path = sys.argv[1]
    image_path = sys.argv[2]

    runner = ImpulseRunner(model_path)
    try:
        model_info = runner.init()
        # --- 修正：正確讀取 model_type 的位置 ---
        model_params = model_info['model_parameters']
        print(f"模型類型: {model_params.get('model_type', 'unknown')}")
        
        width = model_params['image_input_width']
        height = model_params['image_input_height']

        img = cv2.imread(image_path)
        if img is None:
            print("錯誤: 無法讀取圖片")
            sys.exit(1)

        # 1. 轉灰階 (根據之前的錯誤訊息，這是必須的)
        img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        img_gray = cv2.cvtColor(img_rgb, cv2.COLOR_RGB2GRAY)
        
        # 2. 縮放
        img_resized = cv2.resize(img_gray, (width, height))
        
        # 3. 正規化 (分類模型通常需要)
        img_float = img_resized.astype('float32') / 255.0
        
        # 4. 展平
        img_processed = img_float.flatten()

        # 5. 推論
        result = runner.classify(img_processed)

        # 6. 顯示分類結果
        if 'classification' in result['result']:
            print("\n=== 分類結果 ===")
            max_label = ""
            max_score = 0
            
            # 列出所有標籤的分數
            for label, score in result['result']['classification'].items():
                print(f"{label}: {score:.2f}")
                if score > max_score:
                    max_score = score
                    max_label = label
            
            # 將最高分的結果寫在圖片上 (為了看得清楚，字體加大)
            label_text = f"{max_label}: {max_score:.2f}"
            
            # 使用紅色文字 (0, 0, 255) 以便在灰階/彩色圖上對比
            cv2.putText(img, label_text, (10, 50), 
                        cv2.FONT_HERSHEY_SIMPLEX, 1.2, (0, 0, 255), 2)
            
            output_file = 'result.jpg'
            cv2.imwrite(output_file, img)
            print(f"\n[成功] 預測為 [{max_label}]，結果圖片已存至 {output_file}")

        elif 'bounding_boxes' in result['result']:
            print("注意：這是一個物件偵測結果，但您的模型似乎是分類模型。")

    finally:
        runner.stop()

if __name__ == "__main__":
    main()
