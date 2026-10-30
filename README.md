# CounterApp

Production-grade macOS counter application with a Python (FastAPI + SQLite) sidecar managed by a SwiftUI frontend.

## Structure

```
CounterApp/
├── backend/        Python sidecar (FastAPI, SQLite, tests)
├── counter/        SwiftUI macOS app (Xcode project at root)
├── scripts/        Build scripts
└── README.md
```

## Backend (development)

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
PYTHONPATH=src uvicorn counter_backend.main:app --host 127.0.0.1 --port 8765
```

Or run as a module (auto-allocates a port and prints `READY port=...`):

```bash
cd backend
COUNTER_DATA_DIR=./data PYTHONPATH=src python -m counter_backend.main
```

Tests:

```bash
cd backend
PYTHONPATH=src pytest -v
```

## macOS app

Open `counter.xcodeproj` in Xcode and run the `counter` scheme. The app launches the Python sidecar automatically.

## Environment variables (backend)

| Variable | Purpose |
| --- | --- |
| `COUNTER_DATA_DIR` | Directory for `counter.sqlite3` |
| `COUNTER_HOST` | Bind host (default `127.0.0.1`) |
| `COUNTER_PORT` | Port (default `0` = auto) |
| `COUNTER_SESSION_TOKEN` | Bearer token required on `/v1/*` (empty = dev mode) |

## Production notes

- Loopback binding only (`127.0.0.1`).
- Random per-launch session token passed via environment, validated on every `/v1/*` request.
- Dynamic port allocated by the backend and discovered via stdout `READY port=...` plus `/health` polling.
- Atomic-ish SQLite writes using `BEGIN IMMEDIATE`.
- Graceful shutdown on app quit (SIGTERM, then SIGKILL after timeout).

## Documentation

- [Creating a DMG](docs/CREATE_DMG.md)
