from fastapi import APIRouter
from pydantic import BaseModel
from typing import List

class NodeIn(BaseModel):
    text: str
    x: int
    y: int
    kind: str  # e.g. "square"

class NodeOut(NodeIn):
    id: int

router = APIRouter(prefix="/api/nodes", tags=["nodes"])

_nodes: List[NodeOut] = []
_next_id = 1

@router.post("", response_model=NodeOut)
def create_node(node: NodeIn):
    global _next_id
    item = NodeOut(id=_next_id, **node.dict())
    _next_id += 1
    _nodes.append(item)
    return item

@router.get("", response_model=List[NodeOut])
def list_nodes():
    return _nodes
