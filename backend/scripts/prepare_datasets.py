#!/usr/bin/env python3
"""
PLANT AI - Dataset Preparation Utility for Cassava & Pepper Models
-----------------------------------------------------------------
Prepares structured local directories for PyTorch training:
  - Cassava Mosaic Disease (CMD)
  - Cassava Brown Streak Disease (CBSD)
  - Cassava Healthy
  - Pepper Anthracnose
  - Pepper Veinal Mottle / Bacterial Spot
  - Pepper Healthy

Also provides instructions & automated fetchers for:
  1. Kaggle / Makerere African Cassava Leaf Disease Dataset (21,397 images)
  2. Hugging Face pufanyi/cassava-leaf-disease-classification
  3. Hugging Face WaruniSHA/chilli-diseases & Project-AgML/Plant_leaf_diseases
"""

import os
import sys
import json
import numpy as np
from PIL import Image, ImageDraw

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATASET_DIR = os.path.join(BASE_DIR, "datasets")

CLASSES = [
    "cassava_cmd",
    "cassava_cbsd",
    "cassava_healthy",
    "pepper_anthracnose",
    "pepper_bacterial_spot",
    "pepper_healthy",
]

def setup_directories():
    print(f"[*] Initializing dataset directories at: {DATASET_DIR}")
    for split in ["train", "val"]:
        for cls in CLASSES:
            path = os.path.join(DATASET_DIR, split, cls)
            os.makedirs(path, exist_ok=True)
    
    # Save classes.json
    models_dir = os.path.join(BASE_DIR, "app", "models")
    os.makedirs(models_dir, exist_ok=True)
    with open(os.path.join(models_dir, "classes.json"), "w") as f:
        json.dump(CLASSES, f, indent=2)
    print(f"[✓] Created class registry: {models_dir}/classes.json")

def generate_reference_samples(samples_per_class: int = 12):
    """
    Generates high-fidelity synthetic benchmark samples for each crop & disease
    class so the training pipeline can be executed and tested locally right away.
    """
    print(f"[*] Generating {samples_per_class} reference leaf images per class...")
    
    for split, count in [("train", samples_per_class), ("val", max(3, samples_per_class // 4))]:
        for cls in CLASSES:
            target_dir = os.path.join(DATASET_DIR, split, cls)
            for i in range(count):
                img = Image.new("RGB", (320, 320), color=(240, 242, 245))
                draw = ImageDraw.Draw(img)
                
                if "cassava" in cls:
                    # Palmate / multi-lobed cassava leaf outline
                    center_x, center_y = 160, 160
                    # Base green color
                    leaf_color = (46, 125, 50) if "healthy" in cls else (80, 140, 40)
                    
                    # 5 palmate lobes
                    for angle in [-60, -30, 0, 30, 60]:
                        rad = np.radians(angle - 90)
                        length = np.random.randint(100, 125)
                        end_x = int(center_x + length * np.cos(rad))
                        end_y = int(center_y + length * np.sin(rad))
                        draw.line([center_x, center_y, end_x, end_y], fill=(30, 80, 30), width=4)
                        # Leaf lobe ellipse
                        draw.ellipse([end_x - 18, end_y - 18, end_x + 18, end_y + 18], fill=leaf_color)
                        draw.polygon([
                            (center_x, center_y),
                            (end_x - 14, end_y + 10),
                            (end_x, end_y - 10),
                            (end_x + 14, end_y + 10)
                        ], fill=leaf_color)

                    # Add pathology markers
                    if "cmd" in cls:
                        # Yellow mosaic chlorosis patches
                        for _ in range(8):
                            px = np.random.randint(100, 220)
                            py = np.random.randint(80, 200)
                            draw.ellipse([px, py, px + 22, py + 18], fill=(220, 205, 50))
                    elif "cbsd" in cls:
                        # Brown necrotic streaks along veins
                        for _ in range(6):
                            px = np.random.randint(110, 210)
                            py = np.random.randint(90, 190)
                            draw.line([px, py, px + 25, py + 12], fill=(100, 50, 20), width=5)

                else:
                    # Pepper: Simple elliptical ovate leaf
                    leaf_color = (34, 139, 34) if "healthy" in cls else (60, 130, 40)
                    draw.ellipse([80, 50, 240, 270], fill=leaf_color)
                    # Central vein
                    draw.line([160, 270, 160, 60], fill=(25, 100, 25), width=4)
                    
                    if "anthracnose" in cls:
                        # Dark brown sunken concentric spots
                        for _ in range(5):
                            cx = np.random.randint(110, 210)
                            cy = np.random.randint(90, 230)
                            draw.ellipse([cx - 14, cy - 14, cx + 14, cy + 14], fill=(70, 40, 20))
                            draw.ellipse([cx - 6, cy - 6, cx + 6, cy + 6], fill=(40, 20, 10))
                    elif "bacterial_spot" in cls:
                        # Small water-soaked brown spots with yellow halo
                        for _ in range(12):
                            cx = np.random.randint(100, 220)
                            cy = np.random.randint(80, 240)
                            draw.ellipse([cx - 9, cy - 9, cx + 9, cy + 9], fill=(210, 190, 40))
                            draw.ellipse([cx - 5, cy - 5, cx + 5, cy + 5], fill=(80, 45, 15))

                img_path = os.path.join(target_dir, f"sample_{i+1:03d}.jpg")
                img.save(img_path, quality=92)

    print(f"[✓] Finished generating benchmark dataset in {DATASET_DIR}")

def print_open_dataset_instructions():
    print("\n" + "=" * 70)
    print("🌍 OFFICIAL OPEN DATASET DOWNLOAD INSTRUCTIONS FOR CASSAVA & PEPPER")
    print("=" * 70)
    print("""
1. Makerere African Cassava Leaf Disease Dataset (Kaggle - 21,397 real farm photos):
   $ kaggle competitions download -c cassava-leaf-disease-classification
   $ unzip cassava-leaf-disease-classification.zip -d datasets/raw_cassava

2. Hugging Face Cassava Dataset (Python one-liner):
   from datasets import load_dataset
   ds = load_dataset('pufanyi/cassava-leaf-disease-classification')

3. Hugging Face Chili & Pepper Disease Datasets:
   ds = load_dataset('WaruniSHA/chilli-diseases')
   ds_agml = load_dataset('Project-AgML/Plant_leaf_diseases_dataset_classification')

4. World Bank Microdata Library (Liberia Smallholder Cassava/Pepper Yields):
   Access Survey ID: LBR_2016_HIES_V01_M via https://microdata.worldbank.org/
    """)
    print("=" * 70)

if __name__ == "__main__":
    setup_directories()
    generate_reference_samples()
    print_open_dataset_instructions()
