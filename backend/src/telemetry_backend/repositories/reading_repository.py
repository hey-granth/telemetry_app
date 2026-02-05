"""
Reading repository.

Handles all database operations for sensor readings.
Optimized for time-series append operations and range queries.
"""

from typing import Any

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from telemetry_backend.config.logging import get_logger
from telemetry_backend.domain.entities.reading import Reading
from telemetry_backend.domain.value_objects.metrics import SensorMetrics
from telemetry_backend.domain.value_objects.time_range import TimeRange
from telemetry_backend.infrastructure.database.models import ReadingModel

logger = get_logger(__name__)


class ReadingRepository:
    """
    Repository for reading persistence operations.
    
    Provides an abstraction over SQLAlchemy for sensor reading data access.
    Optimized for time-series data patterns:
    - Append-only inserts
    - Range queries by device and time
    - Aggregation queries
    """

    def __init__(self, session: AsyncSession) -> None:
        """
        Initialize repository with database session.
        
        Args:
            session: SQLAlchemy async session.
        """
        self._session = session

    async def create(self, reading: Reading) -> Reading:
        """
        Persist a new reading.
        
        Readings are immutable - once created, they are never updated.
        
        Args:
            reading: Reading entity to persist.
            
        Returns:
            Created Reading entity.
        """
        model = ReadingModel(
            id=reading.id,
            device_id=reading.device_id,
            timestamp=reading.timestamp,
            temperature=reading.metrics.temperature,
            humidity=reading.metrics.humidity,
            voltage=reading.metrics.voltage,
        )

        self._session.add(model)
        await self._session.flush()

        logger.debug(
            "Reading created",
            reading_id=str(reading.id),
            device_id=reading.device_id,
        )
        return reading

    async def get_latest(self, device_id: str) -> Reading | None:
        """
        Get the most recent reading for a device.
        
        Args:
            device_id: Human-readable device identifier.
            
        Returns:
            Latest Reading entity if exists, None otherwise.
        """
        stmt = (
            select(ReadingModel)
            .where(ReadingModel.device_id == device_id)
            .order_by(ReadingModel.timestamp.desc())
            .limit(1)
        )

        result = await self._session.execute(stmt)
        model = result.scalar_one_or_none()

        if model is None:
            return None

        return self._to_entity(model)

    async def get_history(
        self,
        device_id: str,
        time_range: TimeRange,
        limit: int = 1000,
    ) -> list[Reading]:
        """
        Get readings for a device within a time range.
        
        Args:
            device_id: Human-readable device identifier.
            time_range: Time range for the query.
            limit: Maximum number of readings to return.
            
        Returns:
            List of Reading entities, ordered by timestamp ascending.
        """
        stmt = (
            select(ReadingModel)
            .where(
                ReadingModel.device_id == device_id,
                ReadingModel.timestamp >= time_range.start,
                ReadingModel.timestamp <= time_range.end,
            )
            .order_by(ReadingModel.timestamp.asc())
            .limit(limit)
        )

        result = await self._session.execute(stmt)
        models = result.scalars().all()

        return [self._to_entity(model) for model in models]

    async def get_stats(
        self,
        device_id: str,
        time_range: TimeRange,
    ) -> dict[str, Any]:
        """
        Compute aggregated statistics for a device within a time range.
        
        Computes min, max, avg for each metric type.
        
        Args:
            device_id: Human-readable device identifier.
            time_range: Time range for the aggregation.
            
        Returns:
            Dictionary with aggregated statistics.
        """
        stmt = (
            select(
                func.count(ReadingModel.id).label("count"),
                func.min(ReadingModel.timestamp).label("first_reading"),
                func.max(ReadingModel.timestamp).label("last_reading"),
                # Temperature stats
                func.min(ReadingModel.temperature).label("temp_min"),
                func.max(ReadingModel.temperature).label("temp_max"),
                func.avg(ReadingModel.temperature).label("temp_avg"),
                # Humidity stats
                func.min(ReadingModel.humidity).label("humidity_min"),
                func.max(ReadingModel.humidity).label("humidity_max"),
                func.avg(ReadingModel.humidity).label("humidity_avg"),
                # Voltage stats
                func.min(ReadingModel.voltage).label("voltage_min"),
                func.max(ReadingModel.voltage).label("voltage_max"),
                func.avg(ReadingModel.voltage).label("voltage_avg"),
            )
            .where(
                ReadingModel.device_id == device_id,
                ReadingModel.timestamp >= time_range.start,
                ReadingModel.timestamp <= time_range.end,
            )
        )

        result = await self._session.execute(stmt)
        row = result.one()

        return {
            "device_id": device_id,
            "time_range": {
                "start": time_range.start.isoformat() + "Z",
                "end": time_range.end.isoformat() + "Z",
            },
            "reading_count": row.count,
            "first_reading": row.first_reading.isoformat() + "Z" if row.first_reading else None,
            "last_reading": row.last_reading.isoformat() + "Z" if row.last_reading else None,
            "temperature": {
                "min": round(row.temp_min, 2) if row.temp_min is not None else None,
                "max": round(row.temp_max, 2) if row.temp_max is not None else None,
                "avg": round(row.temp_avg, 2) if row.temp_avg is not None else None,
                "unit": "°C",
            },
            "humidity": {
                "min": round(row.humidity_min, 2) if row.humidity_min is not None else None,
                "max": round(row.humidity_max, 2) if row.humidity_max is not None else None,
                "avg": round(row.humidity_avg, 2) if row.humidity_avg is not None else None,
                "unit": "%",
            },
            "voltage": {
                "min": round(row.voltage_min, 2) if row.voltage_min is not None else None,
                "max": round(row.voltage_max, 2) if row.voltage_max is not None else None,
                "avg": round(row.voltage_avg, 2) if row.voltage_avg is not None else None,
                "unit": "V",
            },
        }

    async def count_by_device(self, device_id: str) -> int:
        """
        Count total readings for a device.
        
        Args:
            device_id: Human-readable device identifier.
            
        Returns:
            Total number of readings.
        """
        stmt = (
            select(func.count(ReadingModel.id))
            .where(ReadingModel.device_id == device_id)
        )
        result = await self._session.execute(stmt)
        return result.scalar() or 0

    @staticmethod
    def _to_entity(model: ReadingModel) -> Reading:
        """Convert ORM model to domain entity."""
        return Reading(
            id=model.id,
            device_id=model.device_id,
            metrics=SensorMetrics(
                temperature=model.temperature,
                humidity=model.humidity,
                voltage=model.voltage,
            ),
            timestamp=model.timestamp,
        )
