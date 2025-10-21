from sqlmodel import SQLModel, create_engine, Session

# Safer SQLite for threaded dev servers; no noisy logs
engine = create_engine(
    "sqlite:///./app.db",
    echo=False,
    connect_args={"check_same_thread": False},
)

def init_db():
    SQLModel.metadata.create_all(engine)

def get_session():
    # Avoid DetachedInstanceError after commit
    with Session(engine, expire_on_commit=False) as session:
        yield session
