"""Domain value objects module."""

from telemetry_backend.domain.value_objects.metrics import SensorMetrics
from telemetry_backend.domain.value_objects.time_range import TimeRange

__all__ = ["SensorMetrics", "TimeRange"]
