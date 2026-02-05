"""
Ingest API routes.

Handles sensor data ingestion from ESP32 devices.
"""

from datetime import datetime

from fastapi import APIRouter, status

from app.api.dependencies import ApiKeyDep, IngestionServiceDep
from app.api.dto import IngestPayloadDTO, ReadingDTO, ResponseEnvelope
from app.config.logging import get_logger
from app.services.ingestion_service import (
    AuthenticationError,
    DeviceInactiveError,
    DeviceNotFoundError,
    InvalidPayloadError,
)

logger = get_logger(__name__)

router = APIRouter(prefix="/ingest", tags=["Ingestion"])


@router.post(
    "",
    response_model=ResponseEnvelope[ReadingDTO],
    status_code=status.HTTP_201_CREATED,
    summary="Ingest sensor reading",
    description="""
    Submit a sensor reading from an ESP32 device.
    
    **Authentication:** Requires X-API-Key header with valid device API key.
    
    **Timestamps:** Server assigns UTC timestamp. Client timestamps are ignored.
    
    **Metrics:** At least one metric (temperature, humidity, or voltage) is required.
    """,
    responses={
        201: {"description": "Reading ingested successfully"},
        400: {"description": "Invalid payload"},
        401: {"description": "Missing or invalid API key"},
        404: {"description": "Device not found"},
        422: {"description": "Validation error"},
    },
)
async def ingest_reading(
    payload: IngestPayloadDTO,
    service: IngestionServiceDep,
    api_key: ApiKeyDep,
) -> ResponseEnvelope[ReadingDTO]:
    """
    Ingest a sensor reading from an ESP32 device.
    
    Flow:
    1. Validate API key
    2. Validate payload structure
    3. Validate device exists and is active
    4. Assign server-side UTC timestamp
    5. Persist reading
    6. Broadcast to WebSocket subscribers
    """
    try:
        reading = await service.ingest(
            device_id=payload.device_id,
            metrics_data=payload.metrics.model_dump(exclude_none=True),
            api_key=api_key,
        )

        reading_dict = reading.to_dict()

        return ResponseEnvelope(
            success=True,
            data=ReadingDTO(
                id=reading_dict["id"],
                device_id=reading_dict["device_id"],
                metrics=reading_dict["metrics"],
                timestamp=reading_dict["timestamp"],
            ),
        )

    except AuthenticationError as e:
        logger.warning("Authentication failed", device_id=payload.device_id)
        return ResponseEnvelope(
            success=False,
            error=e.message,
            code=e.code,
            timestamp=datetime.utcnow(),
        )

    except DeviceNotFoundError as e:
        logger.warning("Device not found", device_id=payload.device_id)
        return ResponseEnvelope(
            success=False,
            error=e.message,
            code=e.code,
            timestamp=datetime.utcnow(),
        )

    except DeviceInactiveError as e:
        logger.warning("Device inactive", device_id=payload.device_id)
        return ResponseEnvelope(
            success=False,
            error=e.message,
            code=e.code,
            timestamp=datetime.utcnow(),
        )

    except InvalidPayloadError as e:
        logger.warning("Invalid payload", device_id=payload.device_id, error=e.message)
        return ResponseEnvelope(
            success=False,
            error=e.message,
            code=e.code,
            timestamp=datetime.utcnow(),
        )
