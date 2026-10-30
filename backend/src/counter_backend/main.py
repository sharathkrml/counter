import argparse
import os
import socket

parser = argparse.ArgumentParser(description="Counter backend")
parser.add_argument("--host", default=os.environ.get("COUNTER_HOST", "127.0.0.1"))
parser.add_argument("--port", type=int, default=int(os.environ.get("COUNTER_PORT", "0")))
parser.add_argument("--token", default=os.environ.get("COUNTER_SESSION_TOKEN", ""))
parser.add_argument("--data-dir", default=os.environ.get("COUNTER_DATA_DIR", "./data"))
args, _ = parser.parse_known_args()

os.environ["COUNTER_HOST"] = args.host
os.environ["COUNTER_DATA_DIR"] = args.data_dir
if args.token:
    os.environ["COUNTER_SESSION_TOKEN"] = args.token
os.environ["COUNTER_PORT"] = str(args.port)

from contextlib import asynccontextmanager

import uvicorn
from fastapi import FastAPI

from counter_backend.api.routes import router
from counter_backend.config import HOST, PORT, VERSION
from counter_backend.database import initialize_database
from counter_backend.models import HealthResponse


@asynccontextmanager
async def lifespan(app: FastAPI):
    initialize_database()
    print(f"READY port={PORT}", flush=True)
    yield


app = FastAPI(title="Counter Backend", version=VERSION, lifespan=lifespan)


@app.get("/health", response_model=HealthResponse)
def health():
    return HealthResponse(status="ready", version=VERSION)


app.include_router(router)


def main() -> None:
    uvicorn.run(app, host=HOST, port=PORT, log_level="info")


if __name__ == "__main__":
    main()
