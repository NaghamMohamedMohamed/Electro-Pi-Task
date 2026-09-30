import os
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException 
from pydantic import BaseModel, Field 
from sqlalchemy import create_engine, text
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, sessionmaker


def database_url() -> str:
    user = os.environ["DB_USER"] 
    password = os.environ["DB_PASSWORD"] 
    host = os.environ["DB_HOST"] 
    port = os.getenv("DB_PORT", "5432")
    name = os.environ["DB_NAME"] 

    return (
        f"postgresql+psycopg://"
        f"{user}:{password}@{host}:{port}/{name}"
    )


engine = create_engine(
    database_url(),
    pool_pre_ping=True,
    pool_recycle=1800, 
    pool_size=5, 
    max_overflow=5, 
    connect_args={"connect_timeout": 5} 
)

SessionLocal = sessionmaker(
    bind=engine,
    autoflush=False, 
    autocommit=False 
)


class Base(DeclarativeBase):
    pass


class Item(Base):
    __tablename__ = "items"

    id: Mapped[int] = mapped_column(
        primary_key=True,
        autoincrement=True
    )

    name: Mapped[str]


class ItemIn(BaseModel):
    name: str = Field( 
        min_length=1, 
        max_length=100 
    ) 


@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(engine) 

    yield

    engine.dispose() 


app = FastAPI(
    title="Three-Tier Assessment API",
    version="1.0.0", 
    lifespan=lifespan
)


@app.get("/health")
def health():
    return {
        "status": "ok"
    }


@app.get("/api/items")
def list_items():

    try: 
        with SessionLocal() as session:

            rows = (
                session
                .query(Item)
                .order_by(Item.id)
                .all()
            )

            return [
                {
                    "id": row.id,
                    "name": row.name
                }
                for row in rows
            ]

    except Exception: 
        raise HTTPException( 
            status_code=503, 
            detail="Database unavailable" 
        ) 


@app.post("/api/items")
def create_item(item: ItemIn):

    try: 
        with SessionLocal() as session:

            row = Item(
                name=item.name.strip() 
            )

            session.add(row)
            session.commit()
            session.refresh(row)

            return {
                "id": row.id,
                "name": row.name
            }

    except Exception: 
        raise HTTPException( 
            status_code=503, 
            detail="Database unavailable" 
        ) 


@app.get("/api/db-health")
def db_health():

    try: 
        with engine.connect() as conn:

            conn.execute(
                text("SELECT 1")
            )

        return {
            "database": "ok"
        }

    except Exception: 
        raise HTTPException( 
            status_code=503, 
            detail="Database unavailable" 
        ) 