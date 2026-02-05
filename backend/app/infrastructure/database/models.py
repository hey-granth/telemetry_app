"""
SQLAlchemy ORM models.

Database models for devices and readings.
Separate from domain entities to maintain layer independence.
"""

from datetime import datetime
from typing import Any
from uuid import UUID

from sqlalchemy import (
    Boolean,
    DateTime,
    Float,
    ForeignKey,
    Index,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship


class Base(DeclarativeBase):
    """Base class for all ORM models."""

    type_annotation_map = {
        UUID: PGUUID(as_uuid=True),
    }


class DeviceModel(Base):
    """
    ORM model for devices table.
    
    Stores registered IoT devices and their metadata.
    """

    __tablename__ = "devices"

    id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        primary_key=True,
        comment="Unique device identifier (UUID)",
    )
    device_id: Mapped[str] = mapped_column(
        String(64),
        unique=True,
        nullable=False,
        index=True,
        comment="Human-readable device identifier",
    )
    name: Mapped[str | None] = mapped_column(
        String(255),
        nullable=True,
        comment="Friendly device name",
    )
    api_key_hash: Mapped[str] = mapped_column(
        String(128),
        nullable=False,
        comment="Hashed API key for authentication",
    )
    is_active: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
        nullable=False,
        comment="Whether device is currently active",
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        comment="Device registration timestamp (UTC)",
    )
    last_seen_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
        comment="Timestamp of last reading received (UTC)",
    )

    # Relationships
    readings: Mapped[list["ReadingModel"]] = relationship(
        "ReadingModel",
        back_populates="device",
        lazy="dynamic",
        cascade="all, delete-orphan",
    )

    def to_dict(self) -> dict[str, Any]:
        """Convert model to dictionary."""
        return {
            "id": str(self.id),
            "device_id": self.device_id,
            "name": self.name,
            "is_active": self.is_active,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "last_seen_at": self.last_seen_at.isoformat() if self.last_seen_at else None,
        }

    def __repr__(self) -> str:
        return f"DeviceModel(id={self.id}, device_id={self.device_id})"


class ReadingModel(Base):
    """
    ORM model for readings table.
    
    Stores immutable sensor readings with server-assigned timestamps.
    Append-only - readings are never updated or deleted.
    """

    __tablename__ = "readings"

    id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        primary_key=True,
        comment="Unique reading identifier (UUID)",
    )
    device_id: Mapped[str] = mapped_column(
        String(64),
        ForeignKey("devices.device_id", ondelete="CASCADE"),
        nullable=False,
        comment="Device that produced this reading",
    )
    timestamp: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        comment="Server-assigned timestamp (UTC)",
    )

    # Sensor metrics - nullable to support partial readings
    temperature: Mapped[float | None] = mapped_column(
        Float,
        nullable=True,
        comment="Temperature in degrees Celsius",
    )
    humidity: Mapped[float | None] = mapped_column(
        Float,
        nullable=True,
        comment="Relative humidity percentage",
    )
    voltage: Mapped[float | None] = mapped_column(
        Float,
        nullable=True,
        comment="Power/battery voltage in volts",
    )

    # Relationships
    device: Mapped["DeviceModel"] = relationship(
        "DeviceModel",
        back_populates="readings",
    )

    # Composite index for efficient time-series queries
    __table_args__ = (
        Index(
            "ix_readings_device_timestamp",
            "device_id",
            "timestamp",
            postgresql_using="btree",
        ),
        Index(
            "ix_readings_timestamp",
            "timestamp",
            postgresql_using="btree",
        ),
        {"comment": "Immutable sensor readings time-series"},
    )

    def to_dict(self) -> dict[str, Any]:
        """Convert model to dictionary."""
        metrics = {}
        if self.temperature is not None:
            metrics["temperature"] = self.temperature
        if self.humidity is not None:
            metrics["humidity"] = self.humidity
        if self.voltage is not None:
            metrics["voltage"] = self.voltage

        return {
            "id": str(self.id),
            "device_id": self.device_id,
            "timestamp": self.timestamp.isoformat() if self.timestamp else None,
            "metrics": metrics,
        }

    def __repr__(self) -> str:
        return f"ReadingModel(id={self.id}, device_id={self.device_id}, timestamp={self.timestamp})"
