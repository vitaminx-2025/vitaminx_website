from fastapi import APIRouter
from pydantic import BaseModel
from typing import List

class EdgeIn(BaseModel):
    source_id: int
    target_id: int
    weight: float = 1.0

class EdgeOut(EdgeIn):
    id: int

router = APIRouter(prefix="/api/edges", tags=["edges"])

_edges: List[EdgeOut] = []
_next_id = 1

@router.post("", response_model=EdgeOut)
def create_edge(edge: EdgeIn):
    global _next_id
    item = EdgeOut(id=_next_id, **edge.dict())
    _next_id += 1
    _edges.append(item)
    return item

@router.get("", response_model=List[EdgeOut])
def list_edges():
    return _edges
