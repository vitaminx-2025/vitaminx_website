from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="VitaminX API")

app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"https?://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/api/ping")
def ping():
    return {"message": "pong"}

@app.post("/api/ai/mock")
def ai_mock(payload: dict):
    texts = payload.get("texts", [])
    joined = " | ".join([str(t) for t in texts]) if texts else "no input"
    return {"result": f"AI idea from {joined}"}

# ---- Simple in-memory notes API (reset on server restart) ----
_notes = []
_next_id = 1

@app.get("/api/notes")
def list_notes():
    return {"items": _notes}

@app.post("/api/notes")
def add_note(payload: dict):
    global _next_id
    text = (payload.get("text") or "").strip()
    if not text:
        raise HTTPException(status_code=400, detail="text is required")
    note = {"id": _next_id, "text": text}
    _notes.append(note)
    _next_id += 1
    return note

@app.delete("/api/notes/{note_id}")
def delete_note(note_id: int):
    idx = next((i for i, n in enumerate(_notes) if n["id"] == note_id), None)
    if idx is None:
        raise HTTPException(status_code=404, detail="not found")
    _notes.pop(idx)
    return {"ok": True}
