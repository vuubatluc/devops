from fastapi import FastAPI

from app.database import init_db
from app.routers.health import router as health_router
from app.routers.items import router as items_router


app = FastAPI(title="FastAPI Demo: EC2 + RDS + S3")


@app.on_event("startup")
def on_startup() -> None:
    init_db()


app.include_router(items_router)
app.include_router(health_router)
