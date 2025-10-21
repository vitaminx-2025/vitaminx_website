from typing import Optional
from sqlmodel import SQLModel, Field, Index
from datetime import datetime

class Node(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    text: str
    x: float
    y: float
    kind: str = "square"

class Edge(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    source_id: int
    target_id: int
    weight: float = 1.0

# Speed up neighbor lookups
Index("ix_edge_source", Edge.source_id)
Index("ix_edge_target", Edge.target_id)
