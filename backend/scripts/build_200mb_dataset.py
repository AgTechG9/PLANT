#!/usr/bin/env python3
"""
PLANT AI - High-Performance Multi-Core Dataset Scaler (Cassava & Pepper)
=======================================================================
Targets ~700 MB of high-fidelity leaf imagery with multicore parallel generation:
  - 6 Classes: cassava_cmd, cassava_cbsd, cassava_healthy,
               pepper_anthracnose, pepper_bacterial_spot, pepper_healthy
  - Realistic morphologic variance, HSV variation, lesions & blur
  - Optimized for Apple Silicon / multi-core CPUs via concurrent.futures
"""

import os
import sys
import json
import shutil
import random
import math
import time
import argparse
from pathlib import Path
from concurrent.futures import ProcessPoolExecutor, as_completed

try:
    import numpy as np
    from PIL import Image, ImageDraw, ImageFilter, ImageEnhance, ImageOps
except ImportError as e:
    print(f"[!] Missing dependencies: {e}")
    sys.exit(1)

BASE_DIR = Path(__file__).resolve().parent.parent
DATASET_DIR = BASE_DIR / "datasets"
MODELS_DIR = BASE_DIR / "app" / "models"
CLASSES = [
    "cassava_cmd",
    "cassava_cbsd",
    "cassava_healthy",
    "pepper_anthracnose",
    "pepper_bacterial_spot",
    "pepper_healthy",
]

SPLITS = {"train": 0.80, "val": 0.20}
IMAGE_SIZE = (384, 384)
JPEG_QUALITY = 95

def _rand(lo, hi):
    return random.uniform(lo, hi)

def _randi(lo, hi):
    return random.randint(lo, hi)

def _jitter_color(base, spread=20):
    return tuple(max(0, min(255, int(c + _rand(-spread, spread)))) for c in base)

def draw_cassava(draw, cx, cy, size, color, disease):
    num_lobes = _randi(5, 7)
    spread = _rand(110, 155)
    start_angle = -90 - spread / 2 + _rand(-10, 10)
    stem_len = int(size * _rand(0.3, 0.42))

    draw.line(
        [cx, cy + stem_len, cx + _randi(-10, 10), cy - stem_len // 3],
        fill=_jitter_color((65, 95, 30), 15),
        width=_randi(4, 7)
    )

    for i in range(num_lobes):
        angle_deg = start_angle + (spread / max(num_lobes - 1, 1)) * i
        angle_rad = math.radians(angle_deg)
        lobe_len = size * _rand(0.42, 0.55)
        lx = cx + lobe_len * math.cos(angle_rad)
        ly = cy + lobe_len * math.sin(angle_rad)

        draw.line([cx, cy, int(lx), int(ly)], fill=_jitter_color((45, 100, 35), 15), width=_randi(3, 5))

        w = size * _rand(0.12, 0.18)
        angle_perp = angle_rad + math.pi / 2
        pts = [
            (lx - w * math.cos(angle_perp), ly - w * math.sin(angle_perp)),
            (lx + lobe_len * 0.35 * math.cos(angle_rad), ly + lobe_len * 0.35 * math.sin(angle_rad)),
            (lx + w * math.cos(angle_perp), ly + w * math.sin(angle_perp)),
            (lx - lobe_len * 0.25 * math.cos(angle_rad), ly - lobe_len * 0.25 * math.sin(angle_rad)),
        ]
        draw.polygon([(int(x), int(y)) for x, y in pts], fill=_jitter_color(color, 22))

        draw.line(
            [(int(lx - lobe_len * 0.2 * math.cos(angle_rad)), int(ly - lobe_len * 0.2 * math.sin(angle_rad))),
             (int(lx + lobe_len * 0.3 * math.cos(angle_rad)), int(ly + lobe_len * 0.3 * math.sin(angle_rad)))],
            fill=(40, 90, 30), width=2
        )

    if disease == "cmd":
        for _ in range(_randi(16, 30)):
            px = _randi(cx - int(size * 0.42), cx + int(size * 0.42))
            py = _randi(cy - int(size * 0.42), cy + int(size * 0.42))
            rw = _randi(14, 38)
            rh = _randi(10, 28)
            draw.ellipse([px, py, px + rw, py + rh], fill=_jitter_color((215, 200, 45), 25))
    elif disease == "cbsd":
        for _ in range(_randi(8, 16)):
            sx = _randi(cx - int(size * 0.38), cx + int(size * 0.38))
            sy = _randi(cy - int(size * 0.38), cy + int(size * 0.38))
            ex = sx + _randi(-55, 55)
            ey = sy + _randi(-30, 30)
            draw.line([sx, sy, ex, ey], fill=_jitter_color((95, 45, 15), 18), width=_randi(4, 9))
            draw.ellipse([ex - 9, ey - 9, ex + 9, ey + 9], fill=(180, 150, 30))

def draw_pepper(draw, cx, cy, size, color, disease):
    angle_tilt = math.radians(_rand(-25, 25))
    rx = int(size * _rand(0.24, 0.32))
    ry = int(size * _rand(0.40, 0.50))

    pts = []
    for deg in range(0, 360, 8):
        rad = math.radians(deg)
        x = rx * math.cos(rad)
        y = ry * math.sin(rad)
        xr = x * math.cos(angle_tilt) - y * math.sin(angle_tilt)
        yr = x * math.sin(angle_tilt) + y * math.cos(angle_tilt)
        pts.append((int(cx + xr), int(cy + yr)))
    draw.polygon(pts, fill=_jitter_color(color, 20))

    vein_end_x = cx + int(ry * 0.88 * math.sin(angle_tilt))
    vein_end_y = cy - int(ry * 0.88 * math.cos(angle_tilt))
    vein_start_x = cx - int(ry * 0.88 * math.sin(angle_tilt))
    vein_start_y = cy + int(ry * 0.88 * math.cos(angle_tilt))
    draw.line([vein_start_x, vein_start_y, vein_end_x, vein_end_y], fill=(30, 95, 25), width=_randi(3, 5))

    num_lateral = _randi(5, 8)
    for i in range(1, num_lateral + 1):
        t = i / (num_lateral + 1)
        mx = int(vein_start_x + t * (vein_end_x - vein_start_x))
        my = int(vein_start_y + t * (vein_end_y - vein_start_y))
        lat_len = int(rx * _rand(0.65, 0.95))
        perp_x = int(lat_len * math.cos(angle_tilt + math.pi / 2))
        perp_y = int(lat_len * math.sin(angle_tilt + math.pi / 2))
        draw.line([mx, my, mx + perp_x, my + perp_y], fill=(42, 110, 32), width=2)
        draw.line([mx, my, mx - perp_x, my - perp_y], fill=(42, 110, 32), width=2)

    if disease == "anthracnose":
        for _ in range(_randi(6, 14)):
            spot_cx = _randi(cx - int(rx * 0.72), cx + int(rx * 0.72))
            spot_cy = _randi(cy - int(ry * 0.72), cy + int(ry * 0.72))
            r_outer = _randi(14, 28)
            draw.ellipse([spot_cx - r_outer, spot_cy - r_outer, spot_cx + r_outer, spot_cy + r_outer],
                         fill=_jitter_color((70, 35, 15), 18))
            r_inner = max(4, r_outer - 9)
            draw.ellipse([spot_cx - r_inner, spot_cy - r_inner, spot_cx + r_inner, spot_cy + r_inner],
                         fill=_jitter_color((40, 15, 8), 12))
    elif disease == "bacterial_spot":
        for _ in range(_randi(15, 32)):
            spot_cx = _randi(cx - int(rx * 0.78), cx + int(rx * 0.78))
            spot_cy = _randi(cy - int(ry * 0.78), cy + int(ry * 0.78))
            rh = _randi(6, 14)
            draw.ellipse([spot_cx - rh - 5, spot_cy - rh - 5, spot_cx + rh + 5, spot_cy + rh + 5],
                         fill=_jitter_color((210, 190, 42), 22))
            draw.ellipse([spot_cx - rh, spot_cy - rh, spot_cx + rh, spot_cy + rh],
                         fill=_jitter_color((78, 42, 16), 15))

LEAF_PALETTES = {
    "cassava_cmd":          ((52, 130, 48), "cmd"),
    "cassava_cbsd":         ((48, 118, 44), "cbsd"),
    "cassava_healthy":      ((34, 139, 34), "healthy"),
    "pepper_anthracnose":   ((40, 145, 40), "anthracnose"),
    "pepper_bacterial_spot":((38, 138, 38), "bacterial_spot"),
    "pepper_healthy":       ((28, 148, 28), "healthy"),
}

BG_COLORS = [
    (245, 245, 238),
    (218, 232, 212),
    (198, 218, 198),
    (228, 218, 202),
    (242, 238, 226),
    (208, 222, 228),
]

def generate_leaf_image(cls_name: str) -> Image.Image:
    W, H = IMAGE_SIZE
    bg = random.choice(BG_COLORS)
    bg_jitter = _jitter_color(bg, 16)
    img = Image.new("RGB", (W, H), bg_jitter)

    noise_arr = np.random.randint(0, 22, (H, W, 3), dtype=np.uint8)
    noise_img = Image.fromarray(noise_arr)
    img = Image.blend(img, noise_img, alpha=0.08)
    draw = ImageDraw.Draw(img)

    color, disease = LEAF_PALETTES[cls_name]
    cx = W // 2 + _randi(-22, 22)
    cy = H // 2 + _randi(-22, 22)
    size = min(W, H) * _rand(0.70, 0.90)

    if "cassava" in cls_name:
        draw_cassava(draw, cx, cy, size, color, disease)
    else:
        draw_pepper(draw, cx, cy, size, color, disease)

    if random.random() < 0.35:
        img = img.filter(ImageFilter.GaussianBlur(radius=_rand(0.4, 1.2)))
    
    img = ImageEnhance.Brightness(img).enhance(_rand(0.82, 1.22))
    img = ImageEnhance.Contrast(img).enhance(_rand(0.85, 1.20))
    img = ImageEnhance.Color(img).enhance(_rand(0.80, 1.30))

    if random.random() < 0.5:
        img = ImageOps.mirror(img)
    if random.random() < 0.25:
        img = ImageOps.flip(img)
    if random.random() < 0.70:
        img = img.rotate(_rand(-25, 25), fillcolor=bg_jitter, expand=False)
    if random.random() < 0.40:
        img = img.filter(ImageFilter.SHARPEN)

    return img

def _worker_batch(task):
    cls_name, split, indices, out_dir = task
    out_path = Path(out_dir)
    count = 0
    for idx in indices:
        img = generate_leaf_image(cls_name)
        fpath = out_path / f"{cls_name}_{idx:06d}.jpg"
        img.save(str(fpath), quality=JPEG_QUALITY, optimize=True)
        count += 1
    return cls_name, split, count

def build_dataset(target_mb: float = 700.0, per_class: int = 5000):
    print("=" * 70)
    print(f"🌿 Building Multi-Core Scaled Pepper & Cassava Dataset (Target: ~{target_mb} MB)")
    print(f"📊 Target Volume: {per_class:,} images/class × {len(CLASSES)} classes = {per_class * len(CLASSES):,} images")
    print("=" * 70)

    if DATASET_DIR.exists():
        print("[*] Clearing previous dataset...")
        shutil.rmtree(DATASET_DIR)

    for split in SPLITS:
        for cls in CLASSES:
            (DATASET_DIR / split / cls).mkdir(parents=True, exist_ok=True)

    MODELS_DIR.mkdir(parents=True, exist_ok=True)
    with open(MODELS_DIR / "classes.json", "w") as f:
        json.dump(CLASSES, f, indent=2)

    train_count = int(per_class * SPLITS["train"])
    val_count = per_class - train_count

    tasks = []
    batch_chunk = 250
    for cls in CLASSES:
        # Train chunks
        for i in range(0, train_count, batch_chunk):
            idx_range = list(range(i + 1, min(i + batch_chunk + 1, train_count + 1)))
            tasks.append((cls, "train", idx_range, str(DATASET_DIR / "train" / cls)))
        # Val chunks
        for i in range(0, val_count, batch_chunk):
            idx_range = list(range(i + 1, min(i + batch_chunk + 1, val_count + 1)))
            tasks.append((cls, "val", idx_range, str(DATASET_DIR / "val" / cls)))

    print(f"[*] Dispatching {len(tasks)} parallel worker chunks across CPU cores...")
    t0 = time.time()
    total_generated = 0

    max_workers = min(os.cpu_count() or 4, 8)
    with ProcessPoolExecutor(max_workers=max_workers) as executor:
        futures = {executor.submit(_worker_batch, t): t for t in tasks}
        completed = 0
        for f in as_completed(futures):
            c_name, s_name, n = f.result()
            total_generated += n
            completed += 1
            if completed % 10 == 0 or completed == len(tasks):
                print(f"    [{completed}/{len(tasks)}] Chunks complete. Total images: {total_generated:,}")

    elapsed = time.time() - t0
    total_bytes = sum(f.stat().st_size for f in DATASET_DIR.rglob("*.jpg"))
    actual_mb = total_bytes / (1024 * 1024)

    summary = {
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "total_images": total_generated,
        "total_mb": round(actual_mb, 2),
        "classes": CLASSES,
        "target_crops": ["Cassava", "Pepper"],
        "resolution": list(IMAGE_SIZE),
        "split": {"train": train_count * len(CLASSES), "val": val_count * len(CLASSES)}
    }
    with open(DATASET_DIR / "summary.json", "w") as f:
        json.dump(summary, f, indent=2)

    print("-" * 70)
    print(f"✅ Large Dataset Successfully Created!")
    print(f"📁 Location: {DATASET_DIR}")
    print(f"📊 Total Images: {total_generated:,}")
    print(f"💾 Total Size: {actual_mb:.2f} MB")
    print(f"⏱️ Generation Time: {elapsed:.1f}s")
    print("-" * 70)
    return actual_mb

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--count", type=int, default=5000, help="Images per class (default 5000 for ~700MB)")
    args = parser.parse_args()
    build_dataset(target_mb=700.0, per_class=args.count)
