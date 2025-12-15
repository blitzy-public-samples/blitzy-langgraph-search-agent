from pydantic import BaseModel
from typing import Optional, List

class QueryRequest(BaseModel):
    query: str
    session_id: Optional[str] = None

class QueryResponse(BaseModel):
    response: str
    session_id: str
    sources: Optional[List] = []
