"""
Devices API routes.

Handles device management and query operations.
"""

from datetime import datetime

from fastapi import APIRouter, HTTPException, Query, status

from app.api.dependencies import (
    AdminApiKeyDep,
    AggregationServiceDep,
    DeviceServiceDep,
)
from app.api.dto import (
    DeviceDTO,
    DeviceRegistrationDTO,
    DeviceRegistrationResponseDTO,
    DeviceStatsDTO,
    DeviceSummaryDTO,
    ReadingDTO,
    ResponseEnvelope,
)
from app.config.logging import get_logger
from app.services.device_service import DeviceExistsError, DeviceNotFoundError

logger = get_logger(__name__)

router = APIRouter(prefix="/devices", tags=["Devices"])


@router.get(
    "",
    response_model=ResponseEnvelope[list[DeviceSummaryDTO]],
    summary="List all devices",
    description="Get a list of all registered devices with their latest reading info.",
)
async def list_devices(
    aggregation_service: AggregationServiceDep,
    include_inactive: bool = Query(default=False, description="Include inactive devices"),
) -> ResponseEnvelope[list[DeviceSummaryDTO]]:
    """List all registered devices with summary information."""
    summaries = await aggregation_service.get_all_devices_summary()
    return ResponseEnvelope(success=True, data=summaries)


@router.post(
    "",
    response_model=ResponseEnvelope[DeviceRegistrationResponseDTO],
    status_code=status.HTTP_201_CREATED,
    summary="Register a new device",
    description="""
    Register a new IoT device.
    
    **Authentication:** Requires admin API key (X-API-Key header).
    
    **Important:** The device API key is only returned once. Store it securely.
    """,
    responses={
        201: {"description": "Device registered successfully"},
        401: {"description": "Missing admin API key"},
        403: {"description": "Invalid admin API key"},
        409: {"description": "Device already exists"},
    },
)
async def register_device(
    payload: DeviceRegistrationDTO,
    device_service: DeviceServiceDep,
    _: AdminApiKeyDep,  # Validates admin access
) -> ResponseEnvelope[DeviceRegistrationResponseDTO]:
    """Register a new device and generate its API key."""
    try:
        result = await device_service.register_device(
            device_id=payload.device_id,
            name=payload.name,
        )

        return ResponseEnvelope(
            success=True,
            data=DeviceRegistrationResponseDTO(**result),
        )

    except DeviceExistsError as e:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=e.message,
        )

    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )


@router.get(
    "/{device_id}",
    response_model=ResponseEnvelope[DeviceDTO],
    summary="Get device details",
    description="Get detailed information about a specific device.",
    responses={
        200: {"description": "Device details"},
        404: {"description": "Device not found"},
    },
)
async def get_device(
    device_id: str,
    device_service: DeviceServiceDep,
) -> ResponseEnvelope[DeviceDTO]:
    """Get device information by device_id."""
    try:
        device = await device_service.get_device(device_id)
        return ResponseEnvelope(success=True, data=device)

    except DeviceNotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=e.message,
        )


@router.get(
    "/{device_id}/latest",
    response_model=ResponseEnvelope[ReadingDTO | None],
    summary="Get latest reading",
    description="Get the most recent sensor reading for a device.",
    responses={
        200: {"description": "Latest reading (or null if none exist)"},
        404: {"description": "Device not found"},
    },
)
async def get_latest_reading(
    device_id: str,
    aggregation_service: AggregationServiceDep,
    device_service: DeviceServiceDep,
) -> ResponseEnvelope[ReadingDTO | None]:
    """Get the latest reading for a device."""
    # Verify device exists
    try:
        await device_service.get_device(device_id)
    except DeviceNotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=e.message,
        )

    latest = await aggregation_service.get_latest_reading(device_id)
    return ResponseEnvelope(success=True, data=latest)


@router.get(
    "/{device_id}/stats",
    response_model=ResponseEnvelope[DeviceStatsDTO],
    summary="Get device statistics",
    description="""
    Get aggregated statistics for a device within a time range.
    
    Computes min, max, and average for each metric type.
    """,
    responses={
        200: {"description": "Device statistics"},
        400: {"description": "Invalid time range"},
        404: {"description": "Device not found"},
    },
)
async def get_device_stats(
    device_id: str,
    aggregation_service: AggregationServiceDep,
    device_service: DeviceServiceDep,
    range: str = Query(
        default="24h",
        pattern=r"^\d+[hdmw]$",
        description="Time range (e.g., 24h, 7d, 2w)",
    ),
) -> ResponseEnvelope[DeviceStatsDTO]:
    """Get aggregated statistics for a device."""
    # Verify device exists
    try:
        await device_service.get_device(device_id)
    except DeviceNotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=e.message,
        )

    try:
        stats = await aggregation_service.get_device_stats(device_id, range)
        return ResponseEnvelope(success=True, data=stats)

    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )


@router.get(
    "/{device_id}/history",
    response_model=ResponseEnvelope[list[ReadingDTO]],
    summary="Get reading history",
    description="""
    Get historical readings for a device.
    
    Can specify either a relative time range (e.g., "24h") or explicit timestamps.
    """,
    responses={
        200: {"description": "List of readings"},
        400: {"description": "Invalid time range"},
        404: {"description": "Device not found"},
    },
)
async def get_device_history(
    device_id: str,
    aggregation_service: AggregationServiceDep,
    device_service: DeviceServiceDep,
    range: str | None = Query(
        default="24h",
        pattern=r"^\d+[hdmw]$",
        description="Relative time range (e.g., 24h, 7d)",
    ),
    start: datetime | None = Query(
        default=None,
        description="Start timestamp (ISO 8601)",
    ),
    end: datetime | None = Query(
        default=None,
        description="End timestamp (ISO 8601)",
    ),
    limit: int = Query(
        default=1000,
        ge=1,
        le=10000,
        description="Maximum readings to return",
    ),
) -> ResponseEnvelope[list[ReadingDTO]]:
    """Get historical readings for a device."""
    # Verify device exists
    try:
        await device_service.get_device(device_id)
    except DeviceNotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=e.message,
        )

    try:
        history = await aggregation_service.get_history(
            device_id=device_id,
            start=start,
            end=end,
            range_str=range if not start else None,
            limit=limit,
        )
        return ResponseEnvelope(success=True, data=history)

    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )


@router.delete(
    "/{device_id}",
    response_model=ResponseEnvelope[dict],
    summary="Deactivate a device",
    description="""
    Deactivate a device. Deactivated devices cannot submit readings.
    
    **Authentication:** Requires admin API key (X-API-Key header).
    """,
    responses={
        200: {"description": "Device deactivated"},
        401: {"description": "Missing admin API key"},
        403: {"description": "Invalid admin API key"},
        404: {"description": "Device not found"},
    },
)
async def deactivate_device(
    device_id: str,
    device_service: DeviceServiceDep,
    _: AdminApiKeyDep,
) -> ResponseEnvelope[dict]:
    """Deactivate a device."""
    try:
        result = await device_service.deactivate_device(device_id)
        return ResponseEnvelope(success=True, data=result)

    except DeviceNotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=e.message,
        )
