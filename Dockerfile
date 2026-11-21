FROM python:3.11-slim

WORKDIR /app

# Install system dependencies for OpenCV, PyTorch, psycopg2, and curl
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    libgl1 \
    libglib2.0-0 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install lightweight CPU-only PyTorch and torchvision
RUN pip install --no-cache-dir --extra-index-url https://download.pytorch.org/whl/cpu torch torchvision

# Install python dependencies from backend/requirements.txt
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy only backend application code
COPY backend/ .

ENV PYTHONUNBUFFERED=1

EXPOSE 8000

# Use dynamic PORT provided by Railway / cloud host
CMD uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}
