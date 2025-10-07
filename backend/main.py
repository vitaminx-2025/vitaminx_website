from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from sqlmodel import SQLModel, Field, Session, create_engine, select
from sqlalchemy import func
from datetime import datetime
from typing import Optional, List

engine = create_engine("sqlite:///vitaminx.db", echo=False)

class Note(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    text: str
    created_at: datetime = Field(default_factory=datetime.utcnow)

class NotesPage(SQLModel):
    items: List[Note]
    total: int
    limit: int
    offset: int
    has_more: bool

def init_db() -> None:
    SQLModel.metadata.create_all(engine)

app = FastAPI(title="VitaminX API - Day5")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # dev only
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
def on_startup():
    init_db()

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/api/ping")
def ping():
    return {"message": "pong"}

@app.get("/api/notes", response_model=NotesPage)
def list_notes(
    q: Optional[str] = Query(default=None),
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
):
    with Session(engine) as s:
        base = select(Note)
        if q:
            base = base.where(Note.text.contains(q))
        items = s.exec(base.order_by(Note.id.desc()).offset(offset).limit(limit)).all()

        count_stmt = select(func.count(Note.id))
        if q:
            count_stmt = count_stmt.where(Note.text.contains(q))
        total = s.exec(count_stmt).one()

        has_more = offset + len(items) < total
        return NotesPage(items=items, total=total, limit=limit, offset=offset, has_more=has_more)

@app.post("/api/notes", response_model=Note)
def create_note(payload: dict):
    text = (payload or {}).get("text", "").strip()
    if not text:
        raise HTTPException(status_code=400, detail="text required")
    note = Note(text=text)
    with Session(engine) as s:
        s.add(note)
        s.commit()
        s.refresh(note)
        return note

@app.put("/api/notes/{note_id}", response_model=Note)
def update_note(note_id: int, payload: dict):
    new_text = (payload or {}).get("text", "").strip()
    if not new_text:
        raise HTTPException(status_code=400, detail="text required")
    with Session(engine) as s:
        note = s.get(Note, note_id)
        if not note:
            raise HTTPException(status_code=404, detail="not found")
        note.text = new_text
        s.add(note)
        s.commit()
        s.refresh(note)
        return note

@app.delete("/api/notes/{note_id}")
def delete_note(note_id: int):
    with Session(engine) as s:
        note = s.get(Note, note_id)
        if not note:
            raise HTTPException(status_code=404, detail="not found")
        s.delete(note)
        s.commit()
        return {"ok": True}
