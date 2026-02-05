"""
Dependency injection for API routes.

Provides factory functions for service and repository dependencies.
"""

from typing import Annotated

from fastapi import Depends, Header, HTTPException, status

from app.config.settings import Settings, get_settings
from app.infrastructure.database.connection import DatabaseSession
from app.infrastructure.websocket.manager import WebSocketManager
from app.repositories.device_repository import DeviceRepository
from app.repositories.reading_repository import ReadingRepository
from app.services.aggregation_service import AggregationService
from app.services.device_service import DeviceService
from app.services.ingestion_service import IngestionService

# Singleton WebSocket manager
_ws_manager: WebSocketManager | None = None


def get_ws_manager() -> WebSocketManager:
    """Get the WebSocket manager singleton."""
    global _ws_manager
    if _ws_manager is None:
        _ws_manager = WebSocketManager()
    return _ws_manager


# Repository dependencies
def get_device_repository(session: DatabaseSession) -> DeviceRepository:
    """Get device repository instance."""
    return DeviceRepository(session)


def get_reading_repository(session: DatabaseSession) -> ReadingRepository:
    """Get reading repository instance."""
    return ReadingRepository(session)


# Service dependencies
def get_device_service(
    device_repo: Annotated[DeviceRepository, Depends(get_device_repository)],
) -> DeviceService:
    """Get device service instance."""
    return DeviceService(device_repo)


def get_aggregation_service(
    device_repo: Annotated[DeviceRepository, Depends(get_device_repository)],
    reading_repo: Annotated[ReadingRepository, Depends(get_reading_repository)],
    settings: Annotated[Settings, Depends(get_settings)],
) -> AggregationService:
    """Get aggregation service instance."""
    return AggregationService(device_repo, reading_repo, settings)


def get_ingestion_service(
    device_repo: Annotated[DeviceRepository, Depends(get_device_repository)],
    reading_repo: Annotated[ReadingRepository, Depends(get_reading_repository)],
    settings: Annotated[Settings, Depends(get_settings)],
    ws_manager: Annotated[WebSocketManager, Depends(get_ws_manager)],
) -> IngestionService:
    """Get ingestion service instance."""
    return IngestionService(device_repo, reading_repo, settings, ws_manager)


# Auth dependency
def get_api_key(
    x_api_key: Annotated[str | None, Header(alias="X-API-Key")] = None,
) -> str | None:
    """Extract API key from request header."""
    return x_api_key


def require_admin_api_key(
    x_api_key: Annotated[str | None, Header(alias="X-API-Key")] = None,
    settings: Settings = Depends(get_settings),
) -> str:
    """
    Require admin API key for protected endpoints.
    
    Raises:
        HTTPException: If API key is missing or invalid.
    """
    if not x_api_key:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing X-API-Key header",
        )

    if x_api_key != settings.api_secret_key:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Invalid API key",
        )

    return x_api_key


# Type aliases for dependency injection
DeviceRepositoryDep = Annotated[DeviceRepository, Depends(get_device_repository)]
ReadingRepositoryDep = Annotated[ReadingRepository, Depends(get_reading_repository)]
DeviceServiceDep = Annotated[DeviceService, Depends(get_device_service)]
AggregationServiceDep = Annotated[AggregationService, Depends(get_aggregation_service)]
IngestionServiceDep = Annotated[IngestionService, Depends(get_ingestion_service)]
WebSocketManagerDep = Annotated[WebSocketManager, Depends(get_ws_manager)]
ApiKeyDep = Annotated[str | None, Depends(get_api_key)]
AdminApiKeyDep = Annotated[str, Depends(require_admin_api_key)]
SettingsDep = Annotated[Settings, Depends(get_settings)]
