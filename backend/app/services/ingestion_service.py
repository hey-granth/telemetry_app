"""
Ingestion service.

Handles sensor data ingestion with validation, authentication,
server-side timestamping, and persistence.
"""

from datetime import datetime, timezone
from typing import Any

from app.config.logging import get_logger
from app.config.settings import Settings
from app.domain.entities.reading import Reading
from app.domain.value_objects.metrics import SensorMetrics
from app.repositories.device_repository import DeviceRepository
from app.repositories.reading_repository import ReadingRepository

logger = get_logger(__name__)


class IngestionError(Exception):
    """Base exception for ingestion errors."""

    def __init__(self, message: str, code: str) -> None:
        self.message = message
        self.code = code
        super().__init__(message)


class DeviceNotFoundError(IngestionError):
    """Device does not exist."""

    def __init__(self, device_id: str) -> None:
        super().__init__(
            message=f"Device not found: {device_id}",
            code="DEVICE_NOT_FOUND",
        )


class DeviceInactiveError(IngestionError):
    """Device is deactivated."""

    def __init__(self, device_id: str) -> None:
        super().__init__(
            message=f"Device is inactive: {device_id}",
            code="DEVICE_INACTIVE",
        )


class InvalidPayloadError(IngestionError):
    """Payload validation failed."""

    def __init__(self, message: str) -> None:
        super().__init__(message=message, code="INVALID_PAYLOAD")


class AuthenticationError(IngestionError):
    """Device authentication failed."""

    def __init__(self) -> None:
        super().__init__(
            message="Invalid or missing API key",
            code="AUTHENTICATION_FAILED",
        )


class IngestionService:
    """
    Service for ingesting sensor readings from ESP32 devices.
    
    Responsibilities:
    - Validate incoming payloads
    - Authenticate devices via API key
    - Assign server-side UTC timestamps (never trust client time)
    - Persist readings
    - Notify WebSocket subscribers
    """

    def __init__(
        self,
        device_repository: DeviceRepository,
        reading_repository: ReadingRepository,
        settings: Settings,
        websocket_manager: Any = None,  # Optional, injected for realtime
    ) -> None:
        """
        Initialize ingestion service.
        
        Args:
            device_repository: Repository for device data access.
            reading_repository: Repository for reading data access.
            settings: Application settings.
            websocket_manager: Optional WebSocket manager for realtime updates.
        """
        self._device_repo = device_repository
        self._reading_repo = reading_repository
        self._settings = settings
        self._ws_manager = websocket_manager

    async def ingest(
        self,
        device_id: str,
        metrics_data: dict[str, Any],
        api_key: str | None,
    ) -> Reading:
        """
        Ingest a sensor reading from a device.
        
        Flow:
        1. Validate API key is present
        2. Validate device exists and is active
        3. Validate metric values
        4. Assign server-side UTC timestamp
        5. Persist reading
        6. Update device last_seen_at
        7. Broadcast to WebSocket subscribers
        
        Args:
            device_id: Human-readable device identifier.
            metrics_data: Dictionary with temperature, humidity, voltage.
            api_key: API key for device authentication.
            
        Returns:
            Created Reading entity.
            
        Raises:
            AuthenticationError: If API key is invalid.
            DeviceNotFoundError: If device doesn't exist.
            DeviceInactiveError: If device is deactivated.
            InvalidPayloadError: If metrics are invalid.
        """
        # 1. Validate API key
        if not api_key:
            logger.warning("Ingestion attempt without API key", device_id=device_id)
            raise AuthenticationError()

        if api_key not in self._settings.device_api_keys_set:
            logger.warning(
                "Ingestion attempt with invalid API key",
                device_id=device_id,
                api_key_prefix=api_key[:8] if len(api_key) > 8 else "***",
            )
            raise AuthenticationError()

        # 2. Validate device exists
        device = await self._device_repo.get_by_id(device_id)
        if device is None:
            logger.warning("Ingestion for unknown device", device_id=device_id)
            raise DeviceNotFoundError(device_id)

        if not device.is_active:
            logger.warning("Ingestion for inactive device", device_id=device_id)
            raise DeviceInactiveError(device_id)

        # 3. Validate and parse metrics
        try:
            metrics = SensorMetrics.from_dict(metrics_data)
        except ValueError as e:
            logger.warning(
                "Invalid metrics in payload",
                device_id=device_id,
                error=str(e),
            )
            raise InvalidPayloadError(str(e))

        if not metrics.has_any_metric:
            raise InvalidPayloadError("At least one metric value is required")

        # 4. Assign server-side timestamp
        # CRITICAL: Never trust client timestamps
        server_timestamp = datetime.now(timezone.utc)

        # 5. Create and persist reading
        reading = Reading.create(
            device_id=device_id,
            metrics=metrics,
            timestamp=server_timestamp,
        )

        reading = await self._reading_repo.create(reading)

        # 6. Update device last_seen_at
        await self._device_repo.update_last_seen(device_id, server_timestamp)

        logger.info(
            "Reading ingested successfully",
            device_id=device_id,
            reading_id=str(reading.id),
            timestamp=server_timestamp.isoformat(),
        )

        # 7. Broadcast to WebSocket subscribers
        if self._ws_manager is not None:
            await self._ws_manager.broadcast_to_device(device_id, reading.to_dict())

        return reading
