"""
Device repository.

Handles all database operations for devices.
Abstracts persistence details from the service layer.
"""

from datetime import datetime
from uuid import UUID

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from telemetry_backend.config.logging import get_logger
from telemetry_backend.domain.entities.device import Device
from telemetry_backend.infrastructure.database.models import DeviceModel

logger = get_logger(__name__)


class DeviceRepository:
    """
    Repository for device persistence operations.

    Provides an abstraction over SQLAlchemy for device data access.
    All methods are async for non-blocking I/O.
    """

    def __init__(self, session: AsyncSession) -> None:
        """
        Initialize repository with database session.

        Args:
            session: SQLAlchemy async session.
        """
        self._session = session

    async def get_by_id(self, device_id: str) -> Device | None:
        """
        Get device by human-readable device_id.

        Args:
            device_id: Human-readable device identifier (e.g., "esp32_01").

        Returns:
            Device entity if found, None otherwise.
        """
        stmt = select(DeviceModel).where(DeviceModel.device_id == device_id)
        result = await self._session.execute(stmt)
        model = result.scalar_one_or_none()

        if model is None:
            return None

        return self._to_entity(model)

    async def get_by_uuid(self, id: UUID) -> Device | None:
        """
        Get device by UUID.

        Args:
            id: Device UUID.

        Returns:
            Device entity if found, None otherwise.
        """
        stmt = select(DeviceModel).where(DeviceModel.id == id)
        result = await self._session.execute(stmt)
        model = result.scalar_one_or_none()

        if model is None:
            return None

        return self._to_entity(model)

    async def get_all(self, include_inactive: bool = False) -> list[Device]:
        """
        Get all registered devices.

        Args:
            include_inactive: If True, includes deactivated devices.

        Returns:
            List of Device entities.
        """
        stmt = select(DeviceModel).order_by(DeviceModel.device_id)

        if not include_inactive:
            stmt = stmt.where(DeviceModel.is_active == True)

        result = await self._session.execute(stmt)
        models = result.scalars().all()

        return [self._to_entity(model) for model in models]

    async def exists(self, device_id: str) -> bool:
        """
        Check if device exists.

        Args:
            device_id: Human-readable device identifier.

        Returns:
            True if device exists, False otherwise.
        """
        stmt = select(DeviceModel.id).where(DeviceModel.device_id == device_id)
        result = await self._session.execute(stmt)
        return result.scalar_one_or_none() is not None

    async def create(self, device: Device) -> Device:
        """
        Create a new device.

        Args:
            device: Device entity to persist.

        Returns:
            Created Device entity.

        Raises:
            IntegrityError: If device_id already exists.
        """
        model = DeviceModel(
            id=device.id,
            device_id=device.device_id,
            name=device.name,
            api_key_hash=device.api_key_hash,
            is_active=device.is_active,
            created_at=device.created_at,
            last_seen_at=device.last_seen_at,
        )

        self._session.add(model)
        await self._session.flush()

        logger.info("Device created", device_id=device.device_id)
        return device

    async def update_last_seen(self, device_id: str, timestamp: datetime) -> None:
        """
        Update device's last_seen_at timestamp.

        Args:
            device_id: Human-readable device identifier.
            timestamp: New last seen timestamp (UTC).
        """
        stmt = (
            update(DeviceModel)
            .where(DeviceModel.device_id == device_id)
            .values(last_seen_at=timestamp)
        )
        await self._session.execute(stmt)
        logger.debug("Updated last_seen_at", device_id=device_id, timestamp=timestamp)

    async def deactivate(self, device_id: str) -> bool:
        """
        Deactivate a device.

        Args:
            device_id: Human-readable device identifier.

        Returns:
            True if device was deactivated, False if not found.
        """
        stmt = update(DeviceModel).where(DeviceModel.device_id == device_id).values(is_active=False)
        result = await self._session.execute(stmt)

        if result.rowcount > 0:
            logger.info("Device deactivated", device_id=device_id)
            return True
        return False

    @staticmethod
    def _to_entity(model: DeviceModel) -> Device:
        """Convert ORM model to domain entity."""
        return Device(
            id=model.id,
            device_id=model.device_id,
            name=model.name,
            api_key_hash=model.api_key_hash,
            is_active=model.is_active,
            created_at=model.created_at,
            last_seen_at=model.last_seen_at,
        )
