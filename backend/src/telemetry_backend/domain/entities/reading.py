"""
Reading entity.

Represents a single sensor reading from an IoT device.
Immutable and append-only - readings are never modified after creation.
"""

from dataclasses import dataclass
from datetime import datetime
from typing import Self
from uuid import UUID, uuid4

from telemetry_backend.domain.value_objects.metrics import SensorMetrics


@dataclass(frozen=True, slots=True)
class Reading:
    """
    Sensor reading entity.

    Represents a single immutable sensor reading from a device.
    Timestamps are always server-assigned in UTC - never trust client time.

    Attributes:
        id: Unique reading identifier (UUID).
        device_id: Reference to the device that produced this reading.
        metrics: Sensor metric values (temperature, humidity, voltage).
        timestamp: Server-assigned UTC timestamp when reading was received.
    """

    id: UUID
    device_id: str
    metrics: SensorMetrics
    timestamp: datetime

    @classmethod
    def create(
        cls,
        device_id: str,
        metrics: SensorMetrics,
        timestamp: datetime | None = None,
    ) -> Self:
        """
        Factory method to create a new reading.

        Timestamp is assigned server-side to ensure consistency.
        Client-provided timestamps are ignored for data integrity.

        Args:
            device_id: Device that produced this reading.
            metrics: Sensor metric values.
            timestamp: Server timestamp (defaults to now). Only for testing.

        Returns:
            New Reading instance with server-assigned timestamp.

        Raises:
            ValueError: If device_id is empty.
        """
        if not device_id or not device_id.strip():
            raise ValueError("device_id cannot be empty")

        return cls(
            id=uuid4(),
            device_id=device_id.strip(),
            metrics=metrics,
            timestamp=timestamp or datetime.utcnow(),
        )

    def to_dict(self) -> dict:
        """
        Convert reading to dictionary for serialization.

        Returns:
            Dictionary representation of the reading.
        """
        return {
            "id": str(self.id),
            "device_id": self.device_id,
            "metrics": self.metrics.to_dict(),
            "timestamp": self.timestamp.isoformat() + "Z",
        }

    def __str__(self) -> str:
        return f"Reading({self.device_id}, {self.timestamp.isoformat()})"
