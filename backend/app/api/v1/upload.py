import os
import uuid
from fastapi import APIRouter, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse

router = APIRouter()

UPLOAD_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "uploads")
os.makedirs(UPLOAD_DIR, exist_ok=True)

ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}

@router.post("/upload")
async def upload_image(file: UploadFile = File(...)):
    ext = os.path.splitext(file.filename)[1].lower()
    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported file format '{ext}'. Allowed: {', '.join(ALLOWED_EXTENSIONS)}"
        )

    unique_filename = f"leaf_{uuid.uuid4().hex[:12]}{ext}"
    filepath = os.path.join(UPLOAD_DIR, unique_filename)

    contents = await file.read()
    with open(filepath, "wb") as f:
        f.write(contents)

    file_url = f"/uploads/{unique_filename}"
    
    # Attempt upload to Supabase 'crop-scans' bucket if cloud storage is configured
    from app.core.supabase_storage import upload_leaf_to_supabase
    mime = "image/png" if ext == ".png" else "image/jpeg"
    supabase_url = upload_leaf_to_supabase(unique_filename, contents, mime_type=mime)

    return {
        "filename": unique_filename,
        "url": supabase_url or file_url,
        "local_url": file_url,
        "supabase_url": supabase_url,
        "size_bytes": len(contents),
        "status": "UPLOADED"
    }
