from fastapi import APIRouter, Depends, Header, HTTPException

import os
from counter_backend.models import CounterResponse
from counter_backend.services.counter import CounterService

router = APIRouter(prefix="/v1")
counter_service = CounterService()


def verify_token(authorization: str | None = Header(default=None)) -> None:
    token = os.environ.get("COUNTER_SESSION_TOKEN", "")
    if not token:
        return
    if authorization != f"Bearer {token}":
        raise HTTPException(status_code=401, detail="Unauthorized")


@router.get("/counter", response_model=CounterResponse, dependencies=[Depends(verify_token)])
def get_counter():
    return CounterResponse(count=counter_service.get_count())


@router.post("/counter/increment", response_model=CounterResponse, dependencies=[Depends(verify_token)])
def increment():
    return CounterResponse(count=counter_service.increment())


@router.post("/counter/decrement", response_model=CounterResponse, dependencies=[Depends(verify_token)])
def decrement():
    return CounterResponse(count=counter_service.decrement())


@router.post("/counter/reset", response_model=CounterResponse, dependencies=[Depends(verify_token)])
def reset():
    return CounterResponse(count=counter_service.reset())
