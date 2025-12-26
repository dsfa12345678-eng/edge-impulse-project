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
    
    runner = ImpulseRunner(model_path)
    try:
        model_info = runner.init()
        width = model_info['model_parameters']['image_input_width']
        height = model_info['model_parameters']['image_input_height']
        actual_space = runner._input_shm['array'].shape[0]
        
        print(f"模型載入成功！")
        print(f"專案規格: {width}x{height} px, 單通道(Grayscale)")
        print(f"記憶體配置: {actual_space} bytes")

        img = cv2.imread(image_path)
        if img is None:
            print("錯誤: 無法讀取圖片")
            sys.exit(1)

        img_gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        img_resized = cv2.resize(img_gray, (width, height))
        
        features = img_resized.astype('float32') / 255.0
        features = features.flatten()

        result = runner.classify(features)

        if 'classification' in result['result']:
            scores = result['result']['classification']
            max_label = max(scores, key=scores.get)
            
            # 將「分數」改為「信心度」
            print(f"\n[推論結果] 類別: {max_label}, 信心度: {scores[max_label]:.2f}")
            
            h, w = img.shape[:2]
            font_scale = max(w, h) / 1000.0
            thickness = max(2, int(max(w, h) / 500))
            # 圖片上的標籤也維持專業簡潔
            cv2.putText(img, f"{max_label}: {scores[max_label]:.2f}", (int(w*0.05), int(h*0.1)), 
                        cv2.FONT_HERSHEY_SIMPLEX, font_scale, (0, 0, 255), thickness)
            
            os.makedirs("results", exist_ok=True)
            cv2.imwrite("results/result.jpg", img)
            print(f"結果圖片已存至: results/result.jpg")

    finally:
        runner.stop()

if __name__ == "__main__":
    main()
