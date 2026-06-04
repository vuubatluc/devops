from pathlib import Path

from fastapi.responses import FileResponse

from app.main import app, frontend


def test_frontend_route_returns_index_file():
    response = frontend()
    assert isinstance(response, FileResponse)
    assert Path(response.path).name == "index.html"
    assert "FastAPI Demo Console" in Path(response.path).read_text(encoding="utf-8")


def test_expected_routes_are_registered():
    routes = {route.path for route in app.routes}
    assert "/" in routes
    assert "/health" in routes
    assert "/metrics" in routes
    assert "/items/" in routes
