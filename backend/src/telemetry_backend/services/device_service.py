"""
Device service.

Handles device management operations.
"""

import hashlib
import secrets
from datetime import UTC, datetime
from typing import Any

from telemetry_backend.config.logging import get_logger
from telemetry_backend.domain.entities.device import Device
from telemetry_backend.repositories.device_repository import DeviceRepository

logger = get_logger(__name__)


class DeviceError(Exception):
    """Base exception for device errors."""

    def __init__(self, message: str, code: str) -> None:
        self.message = message
        self.code = code
        super().__init__(message)


class DeviceExistsError(DeviceError):
    """Device already exists."""

    def __init__(self, device_id: str) -> None:
        super().__init__(
            message=f"Device already exists: {device_id}",
            code="DEVICE_EXISTS",
        )


class DeviceNotFoundError(DeviceError):
    """Device not found."""

    def __init__(self, device_id: str) -> None:
        super().__init__(
            message=f"Device not found: {device_id}",
            code="DEVICE_NOT_FOUND",
        )


class DeviceService:
    """
    Service for device management operations.
    
    Responsibilities:
    - Register new devices
    - Deactivate devices
    - Query device information
    - Generate API keys
    """

    def __init__(self, device_repository: DeviceRepository) -> None:
        """
        Initialize device service.
        
        Args:
            device_repository: Repository for device data access.
        """
        self._device_repo = device_repository

    async def register_device(
        self,
        device_id: str,
        name: str | None = None,
    ) -> dict[str, Any]:
        """
        Register a new device.
        
        Generates an API key for the device to use for authentication.
        The raw API key is only returned once - store it securely.
        
        Args:
            device_id: Human-readable device identifier.
            name: Optional friendly name.
            
        Returns:
            Dictionary with device info and raw API key.
            
        Raises:
            DeviceExistsError: If device_id already exists.
            ValueError: If device_id is invalid.
        """
        # Check if device already exists
        if await self._device_repo.exists(device_id):
            raise DeviceExistsError(device_id)

        # Generate API key
        raw_api_key = self._generate_api_key()
        api_key_hash = self._hash_api_key(raw_api_key)

        # Create device entity
        device = Device.create(
            device_id=device_id,
            api_key_hash=api_key_hash,
            name=name,
            created_at=datetime.now(UTC),
        )

        # Persist device
        await self._device_repo.create(device)

        logger.info("Device registered", device_id=device_id)

        return {
            "id": str(device.id),
            "device_id": device.device_id,
            "name": device.name,
            "api_key": raw_api_key,  # Only returned on creation!
            "created_at": device.created_at.isoformat() + "Z",
            "message": "Store the API key securely - it will not be shown again.",
        }

    async def get_device(self, device_id: str) -> dict[str, Any]:
        """
        Get device information.
        
        Args:
            device_id: Human-readable device identifier.
            
        Returns:
            Device information dictionary.
            
        Raises:
            DeviceNotFoundError: If device doesn't exist.
        """
        device = await self._device_repo.get_by_id(device_id)

        if device is None:
            raise DeviceNotFoundError(device_id)

        return {
            "id": str(device.id),
            "device_id": device.device_id,
            "name": device.name,
            "is_active": device.is_active,
            "created_at": device.created_at.isoformat() + "Z",
            "last_seen_at": device.last_seen_at.isoformat() + "Z" if device.last_seen_at else None,
        }

    async def list_devices(self, include_inactive: bool = False) -> list[dict[str, Any]]:
        """
        List all devices.
        
        Args:
            include_inactive: Include deactivated devices.
            
        Returns:
            List of device information dictionaries.
        """
        devices = await self._device_repo.get_all(include_inactive=include_inactive)

        return [
            {
                "id": str(device.id),
                "device_id": device.device_id,
                "name": device.name,
                "is_active": device.is_active,
                "created_at": device.created_at.isoformat() + "Z",
                "last_seen_at": device.last_seen_at.isoformat() + "Z" if device.last_seen_at else None,
            }
            for device in devices
        ]

    async def deactivate_device(self, device_id: str) -> dict[str, Any]:
        """
        Deactivate a device.
        
        Deactivated devices cannot submit readings.
        
        Args:
            device_id: Human-readable device identifier.
            
        Returns:
            Confirmation message.
            
        Raises:
            DeviceNotFoundError: If device doesn't exist.
        """
        success = await self._device_repo.deactivate(device_id)

        if not success:
            raise DeviceNotFoundError(device_id)

        logger.info("Device deactivated", device_id=device_id)

        return {
            "device_id": device_id,
            "is_active": False,
            "message": "Device deactivated successfully.",
        }

    @staticmethod
    def _generate_api_key() -> str:
        """Generate a cryptographically secure API key."""
        return secrets.token_urlsafe(32)

    @staticmethod
    def _hash_api_key(api_key: str) -> str:
        """Hash API key for storage."""
        return hashlib.sha256(api_key.encode()).hexdigest()
