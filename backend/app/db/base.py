"""SQLAlchemy declarative base.

All ORM models must inherit from this Base.
This ensures Alembic can discover all models for autogeneration.
"""

from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.orm import DeclarativeBase
from uuid import UUID


class Base(DeclarativeBase):
    """
    Declarative base for all SQLAlchemy models.

    Configures type mappings for cross-database compatibility.
    """

    type_annotation_map = {
        UUID: PGUUID(as_uuid=True),
    }


# Import all models here so Alembic can detect them
# This is the single source of truth for model discovery
def __import_models():
    """Import models to register them with Base.metadata"""
    from app.db import models  # noqa: F401


__import_models()

__all__ = ["Base"]
