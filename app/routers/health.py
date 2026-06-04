from fastapi import APIRouter
from sqlalchemy import text

from app.database import SessionLocal
from app.s3 import check_s3_connection


router = APIRouter(tags=["Health"])


@router.get("/health")
def health():
    db_ok = False
    s3_ok = False

    db = None
    try:
        db = SessionLocal()
        db.execute(text("SELECT 1"))
        db_ok = True
    except Exception:
        db_ok = False
    finally:
        if db is not None:
            db.close()

    s3_ok = check_s3_connection()
    status = "ok" if db_ok and s3_ok else "degraded"

    return {
        "status": status,
        "rds": "connected" if db_ok else "error",
        "s3": "connected" if s3_ok else "error",
    }
