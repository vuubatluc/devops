import logging
import os
import time

from sqlalchemy import create_engine
from sqlalchemy import text
from sqlalchemy.orm import declarative_base, sessionmaker

from app.config import settings


logger = logging.getLogger(__name__)

engine = create_engine(settings.database_url, pool_pre_ping=True)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def init_db() -> None:
    from app.models.item import ItemDB

    wait_seconds = int(os.getenv("DB_STARTUP_WAIT_SECONDS", "120"))
    retry_interval_seconds = int(os.getenv("DB_STARTUP_RETRY_INTERVAL_SECONDS", "5"))
    deadline = time.monotonic() + wait_seconds

    while True:
        try:
            with engine.connect() as connection:
                connection.execute(text("SELECT 1"))
            Base.metadata.create_all(bind=engine)
            return
        except Exception:
            if time.monotonic() >= deadline:
                raise
            logger.warning(
                "Database is not ready yet; retrying in %s seconds",
                retry_interval_seconds,
                exc_info=True,
            )
            time.sleep(retry_interval_seconds)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
