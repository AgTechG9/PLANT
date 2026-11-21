from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.models import User
from app.schemas.schemas import UserLogin, UserCreate, UserResponse, LoginResponse
from app.core.security import generate_salt, hash_password, verify_password, generate_session_token

router = APIRouter()

# In-memory session token store (token -> user_id)
# For hackathon MVP, provides clean fast state without external Redis dependencies
ACTIVE_SESSIONS: dict[str, str] = {}

VALID_ROLES = {"ADMIN", "AGENT", "FARMER"}

@router.post("/auth/register", response_model=UserResponse)
def register(payload: UserCreate, db: Session = Depends(get_db)):
    role_upper = payload.role.strip().upper()
    if role_upper not in VALID_ROLES:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid role '{payload.role}'. Must be one of: {', '.join(sorted(VALID_ROLES))}"
        )

    existing = db.query(User).filter(User.username == payload.username.strip().lower()).first()
    if existing:
        raise HTTPException(status_code=400, detail="Username is already taken")

    salt = generate_salt()
    pw_hash = hash_password(payload.password, salt)

    user = User(
        username=payload.username.strip().lower(),
        password_hash=pw_hash,
        salt=salt,
        role=role_upper,
        full_name=payload.full_name.strip(),
        phone_number=payload.phone_number,
        county=payload.county
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user

@router.post("/auth/login", response_model=LoginResponse)
def login(payload: UserLogin, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.username == payload.username.strip().lower()).first()
    if not user:
        raise HTTPException(status_code=401, detail="Invalid username or password")

    if not verify_password(payload.password, user.password_hash, user.salt):
        raise HTTPException(status_code=401, detail="Invalid username or password")

    if not user.is_active:
        raise HTTPException(status_code=403, detail="User account is deactivated")

    token = generate_session_token()
    ACTIVE_SESSIONS[token] = user.id

    return LoginResponse(
        access_token=token,
        token_type="bearer",
        user=user
    )

@router.get("/auth/me", response_model=UserResponse)
def get_current_user(
    authorization: str = Header(None, description="Bearer token"),
    db: Session = Depends(get_db)
):
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing or invalid Authorization header")

    token = authorization.split(" ")[1]
    user_id = ACTIVE_SESSIONS.get(token)
    if not user_id:
        raise HTTPException(status_code=401, detail="Session expired or invalid token")

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    return user
