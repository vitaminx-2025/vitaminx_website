from fastapi import FastAPI
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
