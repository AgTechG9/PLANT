import hashlib
import secrets

def generate_salt() -> str:
    return secrets.token_hex(16)

def hash_password(password: str, salt: str) -> str:
    key = hashlib.pbkdf2_hmac(
        'sha256',
        password.encode('utf-8'),
        salt.encode('utf-8'),
        100000
    )
    return key.hex()

def verify_password(plain_password: str, password_hash: str, salt: str) -> bool:
    return hash_password(plain_password, salt) == password_hash

def generate_session_token() -> str:
    return f"plant_tok_{secrets.token_urlsafe(32)}"
