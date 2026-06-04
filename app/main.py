from fastapi import FastAPI
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from prometheus_fastapi_instrumentator import Instrumentator

from app.database import init_db
from app.routers.health import router as health_router
from app.routers.items import router as items_router


app = FastAPI(title="FastAPI Demo: EC2 + RDS + S3")
app.mount("/static", StaticFiles(directory="frontend"), name="static")
Instrumentator().instrument(app).expose(app, endpoint="/metrics", include_in_schema=False)


@app.on_event("startup")
def on_startup() -> None:
    init_db()


app.include_router(items_router)
app.include_router(health_router)


@app.get("/", include_in_schema=False)
def frontend():
    return FileResponse("frontend/index.html")
