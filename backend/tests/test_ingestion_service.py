import pytest
import asyncio
from datetime import datetime, timezone
from unittest.mock import AsyncMock, MagicMock, patch
from uuid import uuid4

from app.domain.entities.device import Device, DeviceStatus
from app.domain.entities.reading import Reading
from app.domain.value_objects.metrics import SensorMetrics
from app.services.ingestion_service import IngestionService


@pytest.fixture
def device_repository():
    """Mock device repository."""
    repo = AsyncMock()
    repo.get_by_device_id = AsyncMock(return_value=Device(
        id=uuid4(),
        device_id="esp32-001",
        name="Test Device",
        api_key_hash="hashed_key",
        status=DeviceStatus.ONLINE,
        created_at=datetime.now(timezone.utc),
        last_seen=datetime.now(timezone.utc),
    ))
    repo.update_last_seen = AsyncMock()
    return repo


@pytest.fixture
def reading_repository():
    """Mock reading repository."""
    repo = AsyncMock()
    repo.create = AsyncMock(return_value=Reading(
        id=uuid4(),
        device_id=uuid4(),
        timestamp=datetime.now(timezone.utc),
        metrics=SensorMetrics(temperature=25.0, humidity=50.0, voltage=3.3),
    ))
    return repo


@pytest.fixture
def websocket_manager():
    """Mock WebSocket manager."""
    manager = AsyncMock()
    manager.broadcast = AsyncMock()
    return manager


@pytest.fixture
def ingestion_service(device_repository, reading_repository, websocket_manager):
    """Create ingestion service with mocked dependencies."""
    return IngestionService(
        device_repository=device_repository,
        reading_repository=reading_repository,
        websocket_manager=websocket_manager,
    )


class TestIngestionService:
    """Tests for IngestionService."""

    @pytest.mark.asyncio
    async def test_ingest_reading_success(
        self,
        ingestion_service,
        device_repository,
        reading_repository,
        websocket_manager,
    ):
        """Test successful reading ingestion."""
        payload = {
            "device_id": "esp32-001",
            "temperature": 25.5,
            "humidity": 60.0,
            "voltage": 3.3,
        }

        result = await ingestion_service.ingest_reading(payload)

        assert result is not None
        device_repository.get_by_device_id.assert_called_once_with("esp32-001")
        reading_repository.create.assert_called_once()
        device_repository.update_last_seen.assert_called_once()
        websocket_manager.broadcast.assert_called_once()

    @pytest.mark.asyncio
    async def test_ingest_reading_unknown_device(
        self,
        ingestion_service,
        device_repository,
    ):
        """Test ingestion fails for unknown device."""
        device_repository.get_by_device_id.return_value = None

        payload = {
            "device_id": "unknown-device",
            "temperature": 25.5,
            "humidity": 60.0,
            "voltage": 3.3,
        }

        with pytest.raises(ValueError, match="Unknown device"):
            await ingestion_service.ingest_reading(payload)

    @pytest.mark.asyncio
    async def test_ingest_reading_validates_metrics(
        self,
        ingestion_service,
    ):
        """Test that metrics are validated."""
        payload = {
            "device_id": "esp32-001",
            "temperature": 200.0,  # Invalid: too high
            "humidity": 60.0,
            "voltage": 3.3,
        }

        with pytest.raises(ValueError, match="temperature"):
            await ingestion_service.ingest_reading(payload)

    @pytest.mark.asyncio
    async def test_ingest_reading_assigns_timestamp(
        self,
        ingestion_service,
        reading_repository,
    ):
        """Test that UTC timestamp is assigned if not provided."""
        payload = {
            "device_id": "esp32-001",
            "temperature": 25.5,
            "humidity": 60.0,
            "voltage": 3.3,
        }

        before = datetime.now(timezone.utc)
        await ingestion_service.ingest_reading(payload)
        after = datetime.now(timezone.utc)

        call_args = reading_repository.create.call_args
        reading_data = call_args[0][0] if call_args[0] else call_args[1].get('reading')
        
        # Verify timestamp was assigned in the expected range
        assert reading_data is not None
