"""
Database connection management.

Provides async SQLAlchemy engine and session management.
Uses connection pooling for production workloads.
"""

from collections.abc import AsyncGenerator
from contextlib import asynccontextmanager
from typing import Annotated

from fastapi import Depends
from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

from app.config.logging import get_logger
from app.config.settings import Settings, get_settings

logger = get_logger(__name__)

# Module-level engine and session factory
_engine: AsyncEngine | None = None
_session_factory: async_sessionmaker[AsyncSession] | None = None


async def init_database(settings: Settings | None = None) -> None:
    """
    Initialize database engine and session factory.

    Should be called once during application startup.

    Args:
        settings: Application settings. If None, loads from environment.
    """
    global _engine, _session_factory

    if _engine is not None:
        logger.warning("Database already initialized, skipping")
        return

    settings = settings or get_settings()

    logger.info(
        "Initializing database connection",
        database_url=str(settings.database_url).split("@")[-1],  # Log without credentials
        pool_size=settings.db_pool_size,
    )

    # Check if using SQLite - it has different pooling requirements
    is_sqlite = settings.database_url.startswith("sqlite")

    if is_sqlite:
        # SQLite-specific settings (no connection pooling)
        _engine = create_async_engine(
            settings.database_url_str,
            connect_args={"check_same_thread": False},  # Allow SQLite across threads
            echo=settings.debug,  # Log SQL in debug mode
        )
    else:
        # PostgreSQL and other databases with full pooling support
        _engine = create_async_engine(
            settings.database_url_str,
            pool_size=settings.db_pool_size,
            max_overflow=settings.db_max_overflow,
            pool_timeout=settings.db_pool_timeout,
            pool_pre_ping=True,  # Verify connections before use
            echo=settings.debug,  # Log SQL in debug mode
        )

    _session_factory = async_sessionmaker(
        bind=_engine,
        class_=AsyncSession,
        expire_on_commit=False,
        autocommit=False,
        autoflush=False,
    )

    logger.info("Database connection initialized successfully")


async def close_database() -> None:
    """
    Close database connections.

    Should be called during application shutdown.
    """
    global _engine, _session_factory

    if _engine is None:
        logger.warning("Database not initialized, nothing to close")
        return

    logger.info("Closing database connections")
    await _engine.dispose()
    _engine = None
    _session_factory = None
    logger.info("Database connections closed")


def get_engine() -> AsyncEngine:
    """
    Get the database engine.

    Returns:
        Configured AsyncEngine instance.

    Raises:
        RuntimeError: If database is not initialized.
    """
    if _engine is None:
        raise RuntimeError("Database not initialized. Call init_database() first.")
    return _engine


def get_session_factory() -> async_sessionmaker[AsyncSession]:
    """
    Get the session factory.

    Returns:
        Configured session factory.

    Raises:
        RuntimeError: If database is not initialized.
    """
    if _session_factory is None:
        raise RuntimeError("Database not initialized. Call init_database() first.")
    return _session_factory


async def get_db_session() -> AsyncGenerator[AsyncSession, None]:
    """
    Dependency for getting a database session.

    Provides a session that is automatically closed after use.
    Use with FastAPI's Depends() for dependency injection.

    Yields:
        AsyncSession for database operations.

    Raises:
        RuntimeError: If database is not initialized.
    """
    factory = get_session_factory()
    async with factory() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise


@asynccontextmanager
async def get_db_session_context() -> AsyncGenerator[AsyncSession, None]:
    """
    Context manager for database sessions outside of request handlers.

    Useful for background tasks and CLI commands.

    Yields:
        AsyncSession for database operations.
    """
    factory = get_session_factory()
    async with factory() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise


# Type alias for dependency injection
DatabaseSession = Annotated[AsyncSession, Depends(get_db_session)]
