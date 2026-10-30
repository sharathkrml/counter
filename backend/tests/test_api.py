import os
import tempfile

_tmp = tempfile.mkdtemp()
os.environ["COUNTER_DATA_DIR"] = _tmp
os.environ["COUNTER_PORT"] = "0"

from fastapi.testclient import TestClient

from counter_backend.database import initialize_database
from counter_backend.main import app

initialize_database()
client = TestClient(app)


def setup_function():
    # reset counter before each test
    client.post("/v1/counter/reset")


def test_health():
    r = client.get("/health")
    assert r.status_code == 200
    data = r.json()
    assert data["status"] == "ready"
    assert "version" in data


def test_get_counter():
    r = client.get("/v1/counter")
    assert r.status_code == 200
    assert r.json() == {"count": 0}


def test_increment():
    r = client.post("/v1/counter/increment")
    assert r.status_code == 200
    assert r.json() == {"count": 1}


def test_decrement():
    r = client.post("/v1/counter/decrement")
    assert r.status_code == 200
    assert r.json() == {"count": -1}


def test_reset():
    client.post("/v1/counter/increment")
    r = client.post("/v1/counter/reset")
    assert r.status_code == 200
    assert r.json() == {"count": 0}


def test_invalid_endpoint():
    r = client.get("/v1/nope")
    assert r.status_code == 404


def test_auth_required():
    os.environ["COUNTER_SESSION_TOKEN"] = "secret123"
    try:
        r = client.get("/v1/counter")
        assert r.status_code == 401
        r2 = client.get("/v1/counter", headers={"Authorization": "Bearer secret123"})
        assert r2.status_code == 200
        r3 = client.get("/v1/counter", headers={"Authorization": "Bearer wrong"})
        assert r3.status_code == 401
    finally:
        del os.environ["COUNTER_SESSION_TOKEN"]
