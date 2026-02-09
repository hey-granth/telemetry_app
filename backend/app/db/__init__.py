"""Database layer package.

Provides:
- Base: Declarative base for all models
- Session management
- Database initialization
"""

from app.db.base import Base
from app.db.models import DeviceModel, ReadingModel
from app.db.session import (
    DatabaseSession,
    close_database,
    get_db_session,
    init_database,
)

__all__ = [
    "Base",
    "DeviceModel",
    "ReadingModel",
    "DatabaseSession",
    "get_db_session",
    "init_database",
    "close_database",
]

