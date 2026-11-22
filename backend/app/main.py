import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse, FileResponse
from app.core.config import settings
from app.core.database import engine, Base, SessionLocal
from app.initial_data import seed_database
from app.api.v1 import auth, upload, health, farmers, cases, knowledge, sms, ussd, diagnostics, weather

# Create DB tables — wrapped so a transient DB connection failure doesn't kill startup
try:
    Base.metadata.create_all(bind=engine)
    print("[Startup] DB tables ensured.")
except Exception as e:
    print(f"[Startup] WARNING: Could not create DB tables: {e}")

# Seed database with initial Liberian agricultural data and users
try:
    db = SessionLocal()
    try:
        seed_database(db)
    finally:
        db.close()
except Exception as e:
    print(f"[Startup] WARNING: Could not seed database: {e}")

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="PLANT: AI Smart Farming Assistant - Backend Platform API (Liberia AgTech Hackathon 2026)",
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    docs_url=f"{settings.API_V1_STR}/docs",
    redoc_url=f"{settings.API_V1_STR}/redoc",
)

# Static files for uploaded crop images and local dialect voice guidance
UPLOAD_DIR = os.path.join(os.path.dirname(__file__), "uploads")
os.makedirs(UPLOAD_DIR, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")

AUDIO_DIR = os.path.join(os.path.dirname(__file__), "static", "audio")
os.makedirs(AUDIO_DIR, exist_ok=True)
app.mount("/audio", StaticFiles(directory=AUDIO_DIR), name="audio")
app.mount("/static/audio", StaticFiles(directory=AUDIO_DIR), name="static_audio")

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount API Routers
app.include_router(auth.router, prefix=settings.API_V1_STR, tags=["Authentication (Admin, Agent, Farmer)"])
app.include_router(upload.router, prefix=settings.API_V1_STR, tags=["File & Image Upload"])
app.include_router(health.router, prefix=settings.API_V1_STR, tags=["Health & Telemetry"])
app.include_router(farmers.router, prefix=settings.API_V1_STR, tags=["Farmers"])
app.include_router(cases.router, prefix=settings.API_V1_STR, tags=["Cases & Triage"])
app.include_router(knowledge.router, prefix=settings.API_V1_STR, tags=["Knowledge Base (CARI)"])
app.include_router(sms.router, prefix=settings.API_V1_STR, tags=["SMS & Broadcast"])
app.include_router(ussd.router, prefix=settings.API_V1_STR, tags=["USSD Engine (*123#)"])
app.include_router(diagnostics.router, prefix=settings.API_V1_STR, tags=["Diagnostics & Safety"])
app.include_router(weather.router, prefix=settings.API_V1_STR, tags=["Agro-Met Weather"])

ADMIN_HTML_STATIC = os.path.join(os.path.dirname(__file__), "static", "desktop_admin.html")
ADMIN_HTML_DEV = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "apps", "desktop", "desktop_admin.html"))

@app.get("/admin", response_class=HTMLResponse)
@app.get("/desktop", response_class=HTMLResponse)
def get_desktop_admin():
    for path in [ADMIN_HTML_STATIC, ADMIN_HTML_DEV]:
        if os.path.exists(path):
            return FileResponse(path)
    return HTMLResponse("<h1>Desktop Admin UI not found</h1>", status_code=404)

@app.get("/health")
def health_check():
    return {"status": "ok", "app": settings.PROJECT_NAME}

@app.get("/")
def root():
    return {
        "app": settings.PROJECT_NAME,
        "version": settings.VERSION,
        "status": "online",
        "docs": f"{settings.API_V1_STR}/docs",
        "health": f"{settings.API_V1_STR}/health",
        "admin": "/admin",
        "desktop": "/desktop"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
