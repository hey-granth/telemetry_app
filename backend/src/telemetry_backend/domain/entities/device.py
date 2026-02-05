"""
Device entity.

Represents an IoT device that produces sensor readings.
Immutable domain entity with business rules.
"""

from dataclasses import dataclass
from datetime import datetime
from typing import Self
from uuid import UUID, uuid4


@dataclass(frozen=True, slots=True)
class Device:
    """
    IoT device entity.

    Represents a registered device that can submit sensor readings.
    Immutable to ensure domain invariants are preserved.

    Attributes:
        id: Unique device identifier (UUID).
        device_id: Human-readable device identifier (e.g., "esp32_01").
        name: Optional friendly name for the device.
        api_key_hash: Hashed API key for device authentication.
        is_active: Whether the device is currently active.
        created_at: Timestamp when device was registered (UTC).
        last_seen_at: Timestamp of last reading received (UTC).
    """

    id: UUID
    device_id: str
    name: str | None
    api_key_hash: str
    is_active: bool
    created_at: datetime
    last_seen_at: datetime | None

    @classmethod
    def create(
        cls,
        device_id: str,
        api_key_hash: str,
        name: str | None = None,
        created_at: datetime | None = None,
    ) -> Self:
        """
        Factory method to create a new device.

        Args:
            device_id: Human-readable device identifier.
            api_key_hash: Hashed API key for authentication.
            name: Optional friendly name.
            created_at: Creation timestamp (defaults to now).

        Returns:
            New Device instance.

        Raises:
            ValueError: If device_id is empty or invalid.
        """
        if not device_id or not device_id.strip():
            raise ValueError("device_id cannot be empty")

        if len(device_id) > 64:
            raise ValueError("device_id cannot exceed 64 characters")

        # Only allow alphanumeric, underscore, and hyphen
        if not all(c.isalnum() or c in "_-" for c in device_id):
            raise ValueError(
                "device_id can only contain alphanumeric characters, underscores, and hyphens"
            )

        return cls(
            id=uuid4(),
            device_id=device_id.strip(),
            name=name.strip() if name else None,
            api_key_hash=api_key_hash,
            is_active=True,
            created_at=created_at or datetime.utcnow(),
            last_seen_at=None,
        )

    def with_last_seen(self, timestamp: datetime) -> Self:
        """
        Create a copy with updated last_seen_at timestamp.

        Args:
            timestamp: New last seen timestamp (UTC).

        Returns:
            New Device instance with updated timestamp.
        """
        return Device(
            id=self.id,
            device_id=self.device_id,
            name=self.name,
            api_key_hash=self.api_key_hash,
            is_active=self.is_active,
            created_at=self.created_at,
            last_seen_at=timestamp,
        )

    def deactivate(self) -> Self:
        """
        Create a deactivated copy of this device.

        Returns:
            New Device instance with is_active=False.
        """
        return Device(
            id=self.id,
            device_id=self.device_id,
            name=self.name,
            api_key_hash=self.api_key_hash,
            is_active=False,
            created_at=self.created_at,
            last_seen_at=self.last_seen_at,
        )

    def __str__(self) -> str:
        return f"Device({self.device_id})"
