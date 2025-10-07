from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from sqlmodel import SQLModel, Field, Session, create_engine, select
from datetime import datetime
from typing import Optional, List

# ---------- DB ----------
engine = create_engine("sqlite:///vitaminx.db", echo=False)

class Note(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    text: str
    created_at: datetime = Field(default_factory=datetime.utcnow)

def init_db() -> None:
    SQLModel.metadata.create_all(engine)

# ---------- App ----------
app = FastAPI(title="VitaminX API - Day4")

# dev CORS
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

# ---------- Notes ----------
@app.get("/api/notes", response_model=List[Note])
def list_notes(q: Optional[str] = Query(default=None)):
    with Session(engine) as s:
        stmt = select(Note).order_by(Note.id.desc())
        if q:
            stmt = stmt.where(Note.text.contains(q))
        return s.exec(stmt).all()

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
