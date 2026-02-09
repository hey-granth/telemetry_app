"""
Aggregation service.

Computes statistics and aggregations on sensor readings.
Aggregations are computed on-demand with caching.
"""

from datetime import datetime
from typing import Any

from app.config.logging import get_logger
from app.config.settings import Settings
from app.domain.value_objects.time_range import TimeRange
from app.repositories.device_repository import DeviceRepository
from app.repositories.reading_repository import ReadingRepository

logger = get_logger(__name__)


class AggregationService:
    """
    Service for computing aggregations on sensor data.

    Provides:
    - Latest readings per device
    - Statistical aggregations (min, max, avg)
    - Historical data with time range filtering

    Design decisions:
    - Aggregations are computed on-demand (not pre-computed)
    - Simple in-memory caching for frequently requested data
    - Raw data is never mutated
    """

    def __init__(
        self,
        device_repository: DeviceRepository,
        reading_repository: ReadingRepository,
        settings: Settings,
    ) -> None:
        """
        Initialize aggregation service.

        Args:
            device_repository: Repository for device data access.
            reading_repository: Repository for reading data access.
            settings: Application settings.
        """
        self._device_repo = device_repository
        self._reading_repo = reading_repository
        self._settings = settings

        # Simple in-memory cache with expiration tracking
        self._cache: dict[str, tuple[datetime, Any]] = {}

    async def get_latest_reading(self, device_id: str) -> dict[str, Any] | None:
        """
        Get the most recent reading for a device.

        Args:
            device_id: Human-readable device identifier.

        Returns:
            Latest reading as dictionary, or None if no readings exist.
        """
        reading = await self._reading_repo.get_latest(device_id)

        if reading is None:
            return None

        return reading.to_dict()

    async def get_device_stats(
        self,
        device_id: str,
        range_str: str = "24h",
    ) -> dict[str, Any]:
        """
        Get aggregated statistics for a device.

        Args:
            device_id: Human-readable device identifier.
            range_str: Time range string (e.g., "24h", "7d", "1w").

        Returns:
            Dictionary with aggregated statistics.

        Raises:
            ValueError: If range string is invalid.
        """
        # Parse time range
        time_range = TimeRange.last(range_str)

        # Check cache
        cache_key = f"stats:{device_id}:{range_str}"
        cached = self._get_cached(cache_key)
        if cached is not None:
            logger.debug("Cache hit for stats", device_id=device_id, range=range_str)
            return cached

        # Compute stats
        stats = await self._reading_repo.get_stats(device_id, time_range)

        # Cache result
        self._set_cached(cache_key, stats)

        logger.debug(
            "Computed stats for device",
            device_id=device_id,
            range=range_str,
            reading_count=stats.get("reading_count"),
        )

        return stats

    async def get_history(
        self,
        device_id: str,
        start: datetime | None = None,
        end: datetime | None = None,
        range_str: str | None = None,
        limit: int | None = None,
    ) -> list[dict[str, Any]]:
        """
        Get historical readings for a device.

        Can specify either:
        - start/end timestamps explicitly
        - range_str for relative time (e.g., "24h")

        Args:
            device_id: Human-readable device identifier.
            start: Start timestamp (optional if range_str provided).
            end: End timestamp (optional, defaults to now).
            range_str: Relative time range (e.g., "24h").
            limit: Maximum number of readings to return.

        Returns:
            List of readings as dictionaries.

        Raises:
            ValueError: If time range cannot be determined.
        """
        limit = limit or self._settings.history_default_limit

        # Determine time range
        if range_str:
            time_range = TimeRange.last(range_str)
        elif start:
            end = end or datetime.utcnow()
            time_range = TimeRange.between(start, end)
        else:
            # Default to last 24 hours
            time_range = TimeRange.last("24h")

        # Fetch readings
        readings = await self._reading_repo.get_history(
            device_id=device_id,
            time_range=time_range,
            limit=limit,
        )

        logger.debug(
            "Fetched history for device",
            device_id=device_id,
            reading_count=len(readings),
            limit=limit,
        )

        return [r.to_dict() for r in readings]

    async def get_all_devices_summary(self) -> list[dict[str, Any]]:
        """
        Get summary information for all active devices.

        Returns:
            List of device summaries with latest reading info.
        """
        devices = await self._device_repo.get_all(include_inactive=False)
        summaries = []

        for device in devices:
            latest = await self._reading_repo.get_latest(device.device_id)
            reading_count = await self._reading_repo.count_by_device(device.device_id)

            summary = {
                "id": str(device.id),
                "device_id": device.device_id,
                "name": device.name,
                "is_active": device.is_active,
                "created_at": device.created_at.isoformat() + "Z",
                "last_seen_at": device.last_seen_at.isoformat() + "Z"
                if device.last_seen_at
                else None,
                "reading_count": reading_count,
                "latest_reading": latest.to_dict() if latest else None,
            }
            summaries.append(summary)

        return summaries

    def _get_cached(self, key: str) -> Any | None:
        """Get cached value if not expired."""
        if key not in self._cache:
            return None

        cached_at, value = self._cache[key]
        age_seconds = (datetime.utcnow() - cached_at).total_seconds()

        if age_seconds > self._settings.aggregation_cache_ttl:
            del self._cache[key]
            return None

        return value

    def _set_cached(self, key: str, value: Any) -> None:
        """Set cached value with timestamp."""
        self._cache[key] = (datetime.utcnow(), value)

    def clear_cache(self, device_id: str | None = None) -> None:
        """
        Clear cached aggregations.

        Args:
            device_id: If provided, only clear cache for this device.
        """
        if device_id:
            keys_to_remove = [k for k in self._cache if device_id in k]
            for key in keys_to_remove:
                del self._cache[key]
        else:
            self._cache.clear()
