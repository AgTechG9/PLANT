import os
import urllib.request
import urllib.error
from typing import Optional

SUPABASE_URL = os.getenv("SUPABASE_URL", "https://cewomqasziwejjzjhykd.supabase.co")
SUPABASE_KEY = os.getenv("SUPABASE_KEY", "")
SUPABASE_BUCKET = os.getenv("SUPABASE_BUCKET_NAME", "crop-scans")

def upload_leaf_to_supabase(filename: str, file_bytes: bytes, mime_type: str = "image/jpeg") -> Optional[str]:
    """
    Attempts to upload an image to Supabase Storage bucket ('crop-scans').
    Returns the public CDN URL if successful, or None if offline/unreachable.
    """
    if not SUPABASE_KEY or not SUPABASE_URL:
        return None

    upload_endpoint = f"{SUPABASE_URL.rstrip('/')}/storage/v1/object/{SUPABASE_BUCKET}/{filename}"
    headers = {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Content-Type": mime_type,
        "x-upsert": "true"
    }

    try:
        req = urllib.request.Request(upload_endpoint, data=file_bytes, headers=headers, method="POST")
        with urllib.request.urlopen(req, timeout=4) as response:
            if response.status in (200, 201):
                public_url = f"{SUPABASE_URL.rstrip('/')}/storage/v1/object/public/{SUPABASE_BUCKET}/{filename}"
                return public_url
    except Exception as e:
        # Graceful fallback: offline mode or bucket not yet initialized
        print(f"[Supabase Storage] Notice: Could not upload to cloud storage ({e}). Using local fallback.")
    return None
