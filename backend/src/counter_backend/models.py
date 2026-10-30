from pydantic import BaseModel


class CounterResponse(BaseModel):
    count: int


class HealthResponse(BaseModel):
    status: str
    version: str
