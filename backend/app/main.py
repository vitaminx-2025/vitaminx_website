from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from starlette.responses import StreamingResponse
from sqlmodel import SQLModel, Field, Session, create_engine, select
from sqlalchemy import text as sa_text
from datetime import datetime
from typing import Optional, List
import io
import csv

from .logging_config import setup_logging
from .routers.nodes import router as nodes_router
from .routers.edges import router as edges_router

# ---------- Logging ----------
setup_logging()

# ---------- App ----------
app = FastAPI(title="VitaminX API")

# Mount routers for nodes & edges
app.include_router(nodes_router)
app.include_router(edges_router)

# ---------- Middleware ----------
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"https?://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------- DB ----------
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


FTS_VT_SQL = """
CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING fts5(
    text,
    content='note',
    content_rowid='id'
);
"""

FTS_TRIGGERS_SQL = [
    """
    CREATE TRIGGER IF NOT EXISTS note_ai AFTER INSERT ON note BEGIN
      INSERT INTO notes_fts(rowid, text) VALUES (new.id, new.text);
    END;
    """,
    """
    CREATE TRIGGER IF NOT EXISTS note_ad AFTER DELETE ON note BEGIN
      DELETE FROM notes_fts WHERE rowid = old.id;
    END;
    """,
    """
    CREATE TRIGGER IF NOT EXISTS note_au AFTER UPDATE ON note BEGIN
      UPDATE notes_fts SET text = new.text WHERE rowid = new.id;
    END;
    """,
]

FTS_BACKFILL_SQL = """
INSERT INTO notes_fts(rowid, text)
SELECT id, text FROM note
WHERE NOT EXISTS (SELECT 1 FROM notes_fts WHERE rowid = note.id);
"""


def init_db() -> None:
    SQLModel.metadata.create_all(engine)
    with engine.begin() as conn:
        conn.exec_driver_sql(FTS_VT_SQL)
        for trig_sql in FTS_TRIGGERS_SQL:
            conn.exec_driver_sql(trig_sql)
        conn.exec_driver_sql(FTS_BACKFILL_SQL)


@app.on_event("startup")
def on_startup():
    init_db()


# ---------- Health ----------
@app.get("/health")
def health():
    return {"status": "ok", "version": "v0.7"}


@app.get("/api/ping")
def ping():
    return {"message": "pong"}


# ---------- Notes API ----------
@app.get("/api/notes", response_model=NotesPage)
def list_notes(
    q: Optional[str] = Query(None),
    limit: int = Query(10, ge=1, le=100),
    offset: int = Query(0, ge=0),
):
    with Session(engine) as session:
        if q:
            total = (
                session.exec(
                    sa_text(
                        "SELECT count(*) FROM notes_fts WHERE notes_fts MATCH :match"
                    ),
                    {"match": q},
                ).first()
                or 0
            )

            stmt = sa_text(
                "SELECT n.id, n.text, n.created_at "
                "FROM note n JOIN notes_fts f ON n.id = f.rowid "
                "WHERE notes_fts MATCH :match "
                "ORDER BY n.id DESC LIMIT :limit OFFSET :offset"
            )
            rows = session.exec(
                stmt,
                {"match": q, "limit": limit, "offset": offset},
            ).all()
            items = [Note(id=row[0], text=row[1], created_at=row[2]) for row in rows]
        else:
            total = session.exec(sa_text("SELECT count(*) FROM note")).first() or 0
            stmt = select(Note).order_by(Note.id.desc()).limit(limit).offset(offset)
            items = session.exec(stmt).all()

        has_more = offset + limit < total
        return NotesPage(
            items=items, total=total, limit=limit, offset=offset, has_more=has_more
        )


@app.post("/api/notes", response_model=Note)
def add_note(note: Note):
    with Session(engine) as session:
        session.add(note)
        session.commit()
        session.refresh(note)
        return note


@app.delete("/api/notes/{note_id}")
def delete_note(note_id: int):
    with Session(engine) as session:
        note = session.get(Note, note_id)
        if not note:
            raise HTTPException(status_code=404, detail="Note not found")
        session.delete(note)
        session.commit()
        return {"ok": True}


# ---------- CSV Export ----------
@app.get("/api/notes/export")
def export_notes_csv():
    with Session(engine) as session:
        stmt = select(Note).order_by(Note.id.desc())
        notes = session.exec(stmt).all()

    buf = io.StringIO()
    writer = csv.writer(buf)
    writer.writerow(["id", "text", "created_at"])
    for n in notes:
        writer.writerow([n.id, n.text, n.created_at.isoformat()])

    buf.seek(0)
    headers = {"Content-Disposition": 'attachment; filename="notes_export.csv"'}
    return StreamingResponse(buf, media_type="text/csv", headers=headers)
