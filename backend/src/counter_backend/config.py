import os
from pathlib import Path

APP_NAME = "CounterApp"
VERSION = "1.0.0"

DATA_DIR = Path(
    os.environ.get("COUNTER_DATA_DIR", "./data")
).expanduser()

DATABASE_PATH = DATA_DIR / "counter.sqlite3"

HOST = os.environ.get("COUNTER_HOST", "127.0.0.1")
_port_raw = os.environ.get("COUNTER_PORT", "0")
if _port_raw in ("", "0"):
    import socket as _socket
    _s = _socket.socket(_socket.AF_INET, _socket.SOCK_STREAM)
    _s.bind((os.environ.get("COUNTER_HOST", "127.0.0.1"), 0))
    PORT = _s.getsockname()[1]
    _s.close()
    os.environ["COUNTER_PORT"] = str(PORT)
else:
    PORT = int(_port_raw)

SESSION_TOKEN = os.environ.get("COUNTER_SESSION_TOKEN", "")
