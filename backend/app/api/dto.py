"""
API response DTOs.

Pydantic models for consistent API responses.
"""

from datetime import datetime
from typing import Generic, TypeVar

from pydantic import BaseModel, ConfigDict, Field

T = TypeVar("T")


class ResponseEnvelope(BaseModel, Generic[T]):
    """
    Standard response envelope for all API responses.

    Provides consistent structure for success and error responses.
    """

    success: bool = Field(description="Whether the request succeeded")
    data: T | None = Field(default=None, description="Response payload")
    error: str | None = Field(default=None, description="Error message if failed")
    code: str | None = Field(default=None, description="Error code if failed")
    timestamp: datetime = Field(
        default_factory=datetime.utcnow,
        description="Response timestamp (UTC)",
    )

    model_config = ConfigDict(
        json_schema_extra={
            "examples": [
                {
                    "success": True,
                    "data": {"device_id": "esp32_01"},
                    "error": None,
                    "code": None,
                    "timestamp": "2024-01-15T10:30:00Z",
                }
            ]
        }
    )


class MetricsDTO(BaseModel):
    """Sensor metrics data transfer object."""

    temperature: float | None = Field(
        default=None,
        ge=-40.0,
        le=85.0,
        description="Temperature in degrees Celsius",
    )
    humidity: float | None = Field(
        default=None,
        ge=0.0,
        le=100.0,
        description="Relative humidity percentage",
    )
    voltage: float | None = Field(
        default=None,
        ge=0.0,
        le=24.0,
        description="Power/battery voltage in volts",
    )

    model_config = ConfigDict(
        json_schema_extra={
            "examples": [
                {
                    "temperature": 25.5,
                    "humidity": 60.0,
                    "voltage": 3.3,
                }
            ]
        }
    )


class IngestPayloadDTO(BaseModel):
    """
    Payload for sensor data ingestion.

    Note: Client-provided timestamps are ignored.
    Server assigns UTC timestamp on receipt.
    """

    device_id: str = Field(
        min_length=1,
        max_length=64,
        pattern=r"^[a-zA-Z0-9_-]+$",
        description="Device identifier",
    )
    metrics: MetricsDTO = Field(description="Sensor metric values")

    model_config = ConfigDict(
        json_schema_extra={
            "examples": [
                {
                    "device_id": "esp32_01",
                    "metrics": {
                        "temperature": 31.4,
                        "humidity": 62.1,
                        "voltage": 3.91,
                    },
                }
            ]
        }
    )


class ReadingDTO(BaseModel):
    """Reading response DTO."""

    id: str = Field(description="Reading UUID")
    device_id: str = Field(description="Device identifier")
    metrics: MetricsDTO = Field(description="Sensor metric values")
    timestamp: str = Field(description="Server-assigned timestamp (ISO 8601)")

    model_config = ConfigDict(from_attributes=True)


class DeviceDTO(BaseModel):
    """Device response DTO."""

    id: str = Field(description="Device UUID")
    device_id: str = Field(description="Human-readable device identifier")
    name: str | None = Field(description="Friendly device name")
    is_active: bool = Field(description="Whether device is active")
    created_at: str = Field(description="Registration timestamp (ISO 8601)")
    last_seen_at: str | None = Field(description="Last reading timestamp (ISO 8601)")

    model_config = ConfigDict(from_attributes=True)


class DeviceSummaryDTO(DeviceDTO):
    """Device summary with latest reading info."""

    reading_count: int = Field(description="Total number of readings")
    latest_reading: ReadingDTO | None = Field(description="Most recent reading")


class DeviceRegistrationDTO(BaseModel):
    """Device registration request DTO."""

    device_id: str = Field(
        min_length=1,
        max_length=64,
        pattern=r"^[a-zA-Z0-9_-]+$",
        description="Device identifier",
    )
    name: str | None = Field(
        default=None,
        max_length=255,
        description="Friendly device name",
    )

    model_config = ConfigDict(
        json_schema_extra={
            "examples": [
                {
                    "device_id": "esp32_01",
                    "name": "Living Room Sensor",
                }
            ]
        }
    )


class DeviceRegistrationResponseDTO(BaseModel):
    """Device registration response DTO."""

    id: str = Field(description="Device UUID")
    device_id: str = Field(description="Device identifier")
    name: str | None = Field(description="Friendly device name")
    api_key: str = Field(description="API key for device authentication")
    created_at: str = Field(description="Registration timestamp")
    message: str = Field(description="Important notice about API key")


class StatMetricDTO(BaseModel):
    """Statistical metric DTO."""

    min: float | None = Field(description="Minimum value")
    max: float | None = Field(description="Maximum value")
    avg: float | None = Field(description="Average value")
    unit: str = Field(description="Measurement unit")


class DeviceStatsDTO(BaseModel):
    """Device statistics DTO."""

    device_id: str = Field(description="Device identifier")
    time_range: dict[str, str] = Field(description="Query time range")
    reading_count: int = Field(description="Number of readings in range")
    first_reading: str | None = Field(description="Earliest reading timestamp")
    last_reading: str | None = Field(description="Latest reading timestamp")
    temperature: StatMetricDTO = Field(description="Temperature statistics")
    humidity: StatMetricDTO = Field(description="Humidity statistics")
    voltage: StatMetricDTO = Field(description="Voltage statistics")


class PaginationDTO(BaseModel):
    """Pagination metadata DTO."""

    total: int = Field(description="Total number of items")
    limit: int = Field(description="Items per page")
    offset: int = Field(description="Current offset")
    has_more: bool = Field(description="Whether more items exist")


class ErrorDetailDTO(BaseModel):
    """Error detail DTO."""

    field: str | None = Field(default=None, description="Field that caused error")
    message: str = Field(description="Error description")
    code: str = Field(description="Error code")
