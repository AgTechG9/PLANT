#!/usr/bin/env python3
"""
PLANT AI - PyTorch Transfer Learning Trainer for Cassava & Pepper Leaf Diagnostics
---------------------------------------------------------------------------------
Architecture: MobileNetV3-Small (lightweight, runs fast on mobile & low-resource hardware)
Target Crops: Cassava (CMD, CBSD, Healthy) & Pepper (Anthracnose, Bacterial Spot, Healthy)
Outputs:
  - app/models/crop_classifier.pt (PyTorch state dict)
  - app/models/crop_classifier.onnx (ONNX export for edge devices)
"""

import os
import sys
import json
import time
import torch
import torch.nn as nn
import torch.optim as optim
from torchvision import datasets, transforms, models

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATASET_DIR = os.path.join(BASE_DIR, "datasets")
MODELS_DIR = os.path.join(BASE_DIR, "app", "models")
os.makedirs(MODELS_DIR, exist_ok=True)

def get_device():
    if torch.backends.mps.is_available():
        return torch.device("mps")
    elif torch.cuda.is_available():
        return torch.device("cuda")
    return torch.device("cpu")

def build_data_loaders(batch_size: int = 8):
    train_transforms = transforms.Compose([
        transforms.Resize((224, 224)),
        transforms.RandomHorizontalFlip(),
        transforms.RandomRotation(15),
        transforms.ColorJitter(brightness=0.15, contrast=0.15),
        transforms.ToTensor(),
        transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
    ])

    val_transforms = transforms.Compose([
        transforms.Resize((224, 224)),
        transforms.ToTensor(),
        transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
    ])

    train_dir = os.path.join(DATASET_DIR, "train")
    val_dir = os.path.join(DATASET_DIR, "val")

    if not os.path.exists(train_dir) or not os.path.exists(val_dir):
        print("[!] Dataset directories not found. Run python scripts/prepare_datasets.py first.")
        sys.exit(1)

    train_data = datasets.ImageFolder(train_dir, transform=train_transforms)
    val_data = datasets.ImageFolder(val_dir, transform=val_transforms)

    train_loader = torch.utils.data.DataLoader(train_data, batch_size=batch_size, shuffle=True)
    val_loader = torch.utils.data.DataLoader(val_data, batch_size=batch_size, shuffle=False)

    return train_loader, val_loader, train_data.classes

def create_model(num_classes: int):
    # Use MobileNetV3-Small for ultra-lightweight mobile footprint
    weights = models.MobileNet_V3_Small_Weights.DEFAULT
    model = models.mobilenet_v3_small(weights=weights)

    # Freeze base feature extractor for transfer learning
    for param in model.features.parameters():
        param.requires_grad = False

    # Replace classifier head
    in_features = model.classifier[0].in_features
    model.classifier = nn.Sequential(
        nn.Linear(in_features, 256),
        nn.Hardswish(),
        nn.Dropout(p=0.2),
        nn.Linear(256, num_classes)
    )
    return model

def train(epochs: int = 5, batch_size: int = 8, lr: float = 0.001):
    device = get_device()
    print(f"[*] Training on compute device: {device.type.upper()}")

    train_loader, val_loader, class_names = build_data_loaders(batch_size=batch_size)
    num_classes = len(class_names)
    print(f"[*] Loaded {num_classes} classes: {class_names}")

    model = create_model(num_classes).to(device)
    criterion = nn.CrossEntropyLoss()
    optimizer = optim.Adam(model.classifier.parameters(), lr=lr)

    start_time = time.time()
    best_acc = 0.0

    for epoch in range(1, epochs + 1):
        model.train()
        running_loss = 0.0
        correct = 0
        total = 0

        for inputs, labels in train_loader:
            inputs, labels = inputs.to(device), labels.to(device)
            optimizer.zero_grad()
            outputs = model(inputs)
            loss = criterion(outputs, labels)
            loss.backward()
            optimizer.step()

            running_loss += loss.item() * inputs.size(0)
            _, preds = torch.max(outputs, 1)
            correct += torch.sum(preds == labels.data).item()
            total += labels.size(0)

        train_loss = running_loss / max(total, 1)
        train_acc = (correct / max(total, 1)) * 100

        # Validation
        model.eval()
        val_correct = 0
        val_total = 0
        with torch.no_grad():
            for inputs, labels in val_loader:
                inputs, labels = inputs.to(device), labels.to(device)
                outputs = model(inputs)
                _, preds = torch.max(outputs, 1)
                val_correct += torch.sum(preds == labels.data).item()
                val_total += labels.size(0)

        val_acc = (val_correct / max(val_total, 1)) * 100
        print(f"Epoch {epoch}/{epochs} | Train Loss: {train_loss:.4f} | Train Acc: {train_acc:.1f}% | Val Acc: {val_acc:.1f}%")

        if val_acc > best_acc:
            best_acc = val_acc

    elapsed = time.time() - start_time
    print(f"[✓] Completed {epochs} epochs in {elapsed:.1f}s. Best Val Accuracy: {best_acc:.1f}%")

    # Save PyTorch Model
    pt_path = os.path.join(MODELS_DIR, "crop_classifier.pt")
    torch.save({
        "state_dict": model.state_dict(),
        "classes": class_names,
        "arch": "mobilenet_v3_small",
        "num_classes": num_classes
    }, pt_path)
    print(f"[✓] Saved PyTorch weights to: {pt_path}")

    # Export to ONNX (on CPU for portable graph)
    try:
        model.to("cpu")
        dummy_input = torch.randn(1, 3, 224, 224)
        onnx_path = os.path.join(MODELS_DIR, "crop_classifier.onnx")
        torch.onnx.export(
            model,
            dummy_input,
            onnx_path,
            input_names=["input"],
            output_names=["output"],
            dynamic_axes={"input": {0: "batch_size"}, "output": {0: "batch_size"}},
            opset_version=14
        )
        print(f"[✓] Exported ONNX model to: {onnx_path}")
    except Exception as e:
        print(f"[!] ONNX export skipped: {e}")

if __name__ == "__main__":
    train(epochs=5, batch_size=8, lr=0.001)
