from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select
from ..db import get_session
from ..models import Node, Edge

router = APIRouter(prefix="/api", tags=["graph"])

# ------------------------
# Create a new node
# ------------------------
@router.post("/nodes")
def create_node(n: Node, session: Session = Depends(get_session)):
    # --- Defensive validation on node text and coordinates ---
    max_len = 200
    n.text = (n.text or "").strip()[:max_len]
    n.x = float(max(0.0, min(10000.0, n.x)))
    n.y = float(max(0.0, min(10000.0, n.y)))

    # --- Save node ---
    session.add(n)
    session.commit()
    session.refresh(n)
    return n


# ------------------------
# List all nodes
# ------------------------
@router.get("/nodes")
def list_nodes(session: Session = Depends(get_session)):
    return session.exec(select(Node)).all()


# ------------------------
# Create a new edge
# ------------------------
@router.post("/edges")
def create_edge(e: Edge, session: Session = Depends(get_session)):
    # --- Basic validation ---
    if not session.get(Node, e.source_id) or not session.get(Node, e.target_id):
        raise HTTPException(status_code=400, detail="Invalid node IDs")

    # --- Save edge ---
    session.add(e)
    session.commit()
    session.refresh(e)
    return e


# ------------------------
# List all edges
# ------------------------
@router.get("/edges")
def list_edges(session: Session = Depends(get_session)):
    return session.exec(select(Edge)).all()
