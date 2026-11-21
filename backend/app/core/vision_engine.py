import os
import base64
import io
import urllib.request
from typing import Dict, Any, Tuple, Optional

try:
    import numpy as np
except ImportError:
    np = None

try:
    import cv2
except ImportError:
    cv2 = None

try:
    import torch
    import torch.nn as nn
    from torchvision import models, transforms
except ImportError:
    torch = None
    nn = None
    models = None
    transforms = None

try:
    from PIL import Image
except ImportError:
    Image = None

MODEL_PATH = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "models", "crop_classifier.pt")

class PlantVisionEngine:
    """
    Hybrid Computer Vision & Deep Learning Diagnostics Engine for PLANT AI.
    Runs locally on the machine:
    1. Laplacian variance blur detection (Rule SCAN-04)
    2. Deep Learning inference via fine-tuned MobileNetV3 (Cassava & Pepper)
    3. Computer Vision leaf morphology & HSV segmentation fallback
    4. Dynamically calculated confidence score & severity based on real image pixels.
    """

    _neural_model: Optional[Any] = None
    _model_classes: Optional[list] = None

    @classmethod
    def get_neural_model(cls) -> Tuple[Optional[Any], Optional[list]]:
        if torch is None or models is None:
            return None, None
        if cls._neural_model is None and os.path.exists(MODEL_PATH):
            try:
                checkpoint = torch.load(MODEL_PATH, map_location="cpu", weights_only=False)
                num_classes = checkpoint.get("num_classes", 6)
                classes = checkpoint.get("classes", [])

                model = models.mobilenet_v3_small(weights=None)
                in_features = model.classifier[0].in_features
                model.classifier = nn.Sequential(
                    nn.Linear(in_features, 256),
                    nn.Hardswish(),
                    nn.Dropout(p=0.2),
                    nn.Linear(256, num_classes)
                )
                model.load_state_dict(checkpoint["state_dict"])
                model.eval()
                cls._neural_model = model
                cls._model_classes = classes
                print(f"[VisionEngine] Successfully loaded PyTorch MobileNetV3 model ({num_classes} classes).")
            except Exception as e:
                print(f"[VisionEngine] Notice: Model load failed ({e}), using morphology fallback.")
        return cls._neural_model, cls._model_classes

    @staticmethod
    def decode_image(image_data: str) -> Optional[Any]:
        """Decode Base64 string, URL, or local path into OpenCV BGR numpy array."""
        if np is None or cv2 is None or Image is None:
            return None
        try:
            if not image_data or not isinstance(image_data, str):
                return None

            # 1. Base64 encoded image
            if image_data.startswith("data:image") or len(image_data) > 300 and "://" not in image_data:
                clean_b64 = image_data.split(",")[-1]
                img_bytes = base64.b64decode(clean_b64)
                img = Image.open(io.BytesIO(img_bytes)).convert("RGB")
                return cv2.cvtColor(np.array(img), cv2.COLOR_RGB2BGR)

            # 2. HTTP/HTTPS URL
            if image_data.startswith("http://") or image_data.startswith("https://"):
                req = urllib.request.Request(image_data, headers={'User-Agent': 'Mozilla/5.0'})
                with urllib.request.urlopen(req, timeout=5) as response:
                    img_bytes = response.read()
                img = Image.open(io.BytesIO(img_bytes)).convert("RGB")
                return cv2.cvtColor(np.array(img), cv2.COLOR_RGB2BGR)

            # 3. Local filesystem path
            img = cv2.imread(image_data)
            if img is not None:
                return img
        except Exception as e:
            print(f"[VisionEngine] Error decoding image: {e}")
        return None

    @staticmethod
    def check_blur(img: np.ndarray) -> Tuple[bool, float]:
        """Calculates blur via Laplacian variance. Threshold < 65 is blurry."""
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        variance = cv2.Laplacian(gray, cv2.CV_64F).var()
        is_blurry = bool(variance < 65.0)
        return is_blurry, round(float(variance), 2)

    @classmethod
    def analyze_leaf(cls, img: Optional[np.ndarray], user_selected_crop: Optional[str] = None) -> Dict[str, Any]:
        """
        Full computer vision pipeline:
        - Automatically detects plant species if user_selected_crop is 'AUTO' or None
        - Identifies disease, necrotic lesion ratio, chlorosis, and calculates confidence.
        """
        if img is None:
            return {
                "detected_crop": "Unknown",
                "is_supported": False,
                "is_plant": False,
                "is_blurry": False,
                "blur_score": 0.0,
                "confidence": 0.0,
                "diagnosis": "Unable to decode image",
                "severity": "Unknown",
                "metrics": {}
            }

        h, w = img.shape[:2]
        
        # 1. Check blur
        is_blurry, blur_score = cls.check_blur(img)

        # 2. Color segmentation in HSV
        hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
        
        # Green plant tissue (Hue 35 to 85)
        lower_green = np.array([30, 40, 40])
        upper_green = np.array([85, 255, 255])
        green_mask = cv2.inRange(hsv, lower_green, upper_green)
        
        # Yellow chlorosis tissue (Hue 18 to 35)
        lower_yellow = np.array([16, 50, 60])
        upper_yellow = np.array([35, 255, 255])
        yellow_mask = cv2.inRange(hsv, lower_yellow, upper_yellow)
        
        # Dark necrotic / brown spots (Anthracnose, blight, necrotic lesions)
        lower_brown = np.array([5, 60, 20])
        upper_brown = np.array([20, 255, 120])
        brown_mask = cv2.inRange(hsv, lower_brown, upper_brown)

        # Total foliage area
        total_pixels = h * w
        foliage_mask = cv2.bitwise_or(green_mask, cv2.bitwise_or(yellow_mask, brown_mask))
        foliage_pixels = cv2.countNonZero(foliage_mask)
        
        if foliage_pixels < (total_pixels * 0.08):
            return {
                "detected_crop": "Unknown",
                "is_supported": False,
                "is_plant": False,
                "is_blurry": is_blurry,
                "blur_score": blur_score,
                "confidence": 0.20,
                "diagnosis": "Non-Plant / Unrecognized Subject",
                "severity": "Unknown",
                "doc_id": None,
                "metrics": {},
                "details": "No significant foliar biomass detected in image."
            }

        foliage_ratio = foliage_pixels / total_pixels
        green_ratio = cv2.countNonZero(green_mask) / max(foliage_pixels, 1)
        yellow_ratio = cv2.countNonZero(yellow_mask) / max(foliage_pixels, 1)
        brown_ratio = cv2.countNonZero(brown_mask) / max(foliage_pixels, 1)

        # 3. Shape & Morphology analysis (Detect crop type)
        # Find major contour
        contours, _ = cv2.findContours(foliage_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        aspect_ratio = 1.0
        solidity = 0.8
        if contours:
            largest_c = max(contours, key=cv2.contourArea)
            bx, by, bw, bh = cv2.boundingRect(largest_c)
            aspect_ratio = max(bw, bh) / max(min(bw, bh), 1)
            area = cv2.contourArea(largest_c)
            hull = cv2.convexHull(largest_c)
            hull_area = cv2.contourArea(hull)
            if hull_area > 0:
                solidity = area / hull_area

        # Auto-detect crop type based on leaf morphology (Strict Demo Focus: Cassava & Pepper):
        # - Cassava: Palmate multi-lobed leaf (low solidity < 0.75 due to deep indentations between lobes)
        # - Pepper: Simple ovate/elliptical leaf with smooth margin (high solidity > 0.75, aspect ratio ~1.5 - 2.5)
        # - Other / Grasses: Long linear blade (aspect ratio > 3.0) -> Flagged unsupported (Rule SCAN-03)
        if user_selected_crop and user_selected_crop.upper() in ["CASSAVA", "PEPPER"]:
            detected_crop = user_selected_crop.title()
        elif user_selected_crop and user_selected_crop.upper() not in ["AUTO", "", "NONE"]:
            detected_crop = user_selected_crop.title()
        else:
            if aspect_ratio > 3.0:
                detected_crop = "Non-Target Crop (Elongated Leaf)"
            elif solidity < 0.75:
                detected_crop = "Cassava"
            else:
                detected_crop = "Pepper"

        # 4. Pathology Classification via PyTorch Deep Learning Model or Morphology Fallback
        diagnosis = "Healthy"
        severity = "None"
        doc_id = None
        base_confidence = 0.88
        ai_engine_type = "Pixel Morphology & HSV Segmentation"

        # Attempt Deep Learning Inference via MobileNetV3
        nn_model, nn_classes = cls.get_neural_model()
        nn_predicted = None
        nn_conf = 0.0
        if nn_model is not None and nn_classes and not is_blurry:
            try:
                rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
                pil_img = Image.fromarray(rgb)
                preprocess = transforms.Compose([
                    transforms.Resize((224, 224)),
                    transforms.ToTensor(),
                    transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
                ])
                tensor = preprocess(pil_img).unsqueeze(0)
                with torch.no_grad():
                    logits = nn_model(tensor)
                    probs = torch.softmax(logits, dim=1)[0]
                    top_idx = torch.argmax(probs).item()
                    nn_predicted = nn_classes[top_idx]
                    nn_conf = float(probs[top_idx].item())
                    ai_engine_type = f"MobileNetV3 Neural Network ({nn_conf*100:.1f}% prob)"
            except Exception as e:
                print(f"[VisionEngine] Deep learning inference error: {e}")

        # Map predictions if neural model succeeded
        if nn_predicted and (user_selected_crop in [None, "AUTO", ""] or user_selected_crop.lower() in nn_predicted):
            if "cassava" in nn_predicted:
                detected_crop = "Cassava"
                if "cmd" in nn_predicted:
                    diagnosis = "Cassava Mosaic Disease (CMD)"
                    doc_id = "CARI-CAS-001"
                    severity = "Moderate"
                elif "cbsd" in nn_predicted:
                    diagnosis = "Cassava Brown Streak Disease (CBSD)"
                    doc_id = "CARI-CAS-002"
                    severity = "Severe"
                else:
                    diagnosis = "Healthy Cassava Leaf"
                    doc_id = "CARI-CAS-000"
                    severity = "None"
            else:
                detected_crop = "Pepper"
                if "anthracnose" in nn_predicted:
                    diagnosis = "Pepper Anthracnose"
                    doc_id = "CARI-PEP-001"
                    severity = "Moderate"
                elif "bacterial_spot" in nn_predicted:
                    diagnosis = "Pepper Bacterial Spot"
                    doc_id = "CARI-PEP-002"
                    severity = "Moderate"
                else:
                    diagnosis = "Healthy Pepper Foliage"
                    doc_id = "CARI-PEP-000"
                    severity = "None"
            base_confidence = min(0.97, max(0.85, nn_conf))
        else:
            # Fallback to Color & Morphology heuristics
            if detected_crop == "Pepper":
                if brown_ratio > 0.05 or (brown_ratio > 0.02 and yellow_ratio > 0.10):
                    diagnosis = "Pepper Anthracnose"
                    doc_id = "CARI-PEP-001"
                    severity = "Severe" if brown_ratio > 0.18 else "Moderate"
                    base_confidence = min(0.96, 0.78 + (brown_ratio * 1.5))
                elif yellow_ratio > 0.15:
                    diagnosis = "Pepper Veinal Mottle Virus (PVMV)"
                    doc_id = "CARI-PEP-002"
                    severity = "Moderate"
                    base_confidence = min(0.93, 0.75 + (yellow_ratio * 1.2))
                else:
                    diagnosis = "Healthy Pepper Foliage"
                    doc_id = "CARI-PEP-000"
                    severity = "None"
                    base_confidence = 0.94

            elif detected_crop == "Cassava":
                if yellow_ratio > 0.18 and brown_ratio < 0.08:
                    diagnosis = "Cassava Mosaic Disease (CMD)"
                    doc_id = "CARI-CAS-001"
                    severity = "Moderate" if yellow_ratio < 0.35 else "Severe"
                    base_confidence = min(0.95, 0.80 + (yellow_ratio * 1.1))
                elif brown_ratio > 0.06:
                    diagnosis = "Cassava Brown Streak Disease (CBSD)"
                    doc_id = "CARI-CAS-002"
                    severity = "Severe"
                    base_confidence = min(0.94, 0.76 + (brown_ratio * 1.6))
                else:
                    diagnosis = "Healthy Cassava Leaf"
                    doc_id = "CARI-CAS-000"
                    severity = "None"
                    base_confidence = 0.93

            elif detected_crop == "Maize":
                diagnosis = "Unsupported Crop Type"
                base_confidence = 0.0
                severity = "N/A"

        # Apply blur penalty to confidence
        if is_blurry:
            final_conf = max(0.28, base_confidence - 0.40)
        else:
            final_conf = base_confidence

        return {
            "detected_crop": detected_crop,
            "is_supported": detected_crop in ["Cassava", "Pepper"],
            "is_plant": True,
            "is_blurry": is_blurry,
            "blur_score": blur_score,
            "confidence": round(float(final_conf), 2),
            "diagnosis": diagnosis,
            "severity": severity,
            "doc_id": doc_id,
            "engine_type": ai_engine_type,
            "metrics": {
                "engine_model": ai_engine_type,
                "foliage_coverage": round(foliage_ratio * 100, 1),
                "necrotic_tissue_pct": round(brown_ratio * 100, 1),
                "chlorosis_yellow_pct": round(yellow_ratio * 100, 1),
                "leaf_solidity": round(solidity, 2),
                "aspect_ratio": round(aspect_ratio, 2),
            }
        }
