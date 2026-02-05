from datetime import UTC, datetime
from unittest.mock import AsyncMock, patch
from uuid import uuid4

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient

from telemetry_backend.domain.entities.device import Device, DeviceStatus
from telemetry_backend.domain.entities.reading import Reading
from telemetry_backend.domain.value_objects.metrics import SensorMetrics
from telemetry_backend.main import app


@pytest_asyncio.fixture
async def async_client():
    """Create async test client."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        yield client


class TestHealthEndpoint:
    """Tests for health check endpoint."""

    @pytest.mark.asyncio
    async def test_health_check(self, async_client):
        """Test health check returns ok status."""
        response = await async_client.get("/health")

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"


class TestIngestEndpoint:
    """Tests for data ingestion endpoint."""

    @pytest.mark.asyncio
    async def test_ingest_valid_reading(self, async_client):
        """Test ingesting valid sensor reading."""
        with patch('app.api.ingest.routes.get_ingestion_service') as mock_service:
            mock_svc = AsyncMock()
            mock_svc.ingest_reading.return_value = Reading(
                id=uuid4(),
                device_id=uuid4(),
                timestamp=datetime.now(UTC),
                metrics=SensorMetrics(temperature=25.0, humidity=50.0, voltage=3.3),
            )
            mock_service.return_value = mock_svc

            response = await async_client.post(
                "/api/v1/ingest",
                json={
                    "device_id": "esp32-001",
                    "temperature": 25.0,
                    "humidity": 50.0,
                    "voltage": 3.3,
                },
                headers={"X-API-Key": "test-api-key"},
            )

            assert response.status_code == 201

    @pytest.mark.asyncio
    async def test_ingest_missing_fields(self, async_client):
        """Test ingestion fails with missing required fields."""
        response = await async_client.post(
            "/api/v1/ingest",
            json={"device_id": "esp32-001"},
            headers={"X-API-Key": "test-api-key"},
        )

        assert response.status_code == 422

    @pytest.mark.asyncio
    async def test_ingest_invalid_temperature(self, async_client):
        """Test ingestion fails with invalid temperature."""
        response = await async_client.post(
            "/api/v1/ingest",
            json={
                "device_id": "esp32-001",
                "temperature": 200.0,  # Too high
                "humidity": 50.0,
                "voltage": 3.3,
            },
            headers={"X-API-Key": "test-api-key"},
        )

        assert response.status_code == 422


class TestDevicesEndpoint:
    """Tests for devices endpoint."""

    @pytest.mark.asyncio
    async def test_list_devices(self, async_client):
        """Test listing all devices."""
        with patch('app.api.devices.routes.get_device_service') as mock_service:
            mock_svc = AsyncMock()
            mock_svc.list_devices.return_value = [
                Device(
                    id=uuid4(),
                    device_id="esp32-001",
                    name="Test Device 1",
                    api_key_hash="hash1",
                    status=DeviceStatus.ONLINE,
                    created_at=datetime.now(UTC),
                    last_seen=datetime.now(UTC),
                ),
                Device(
                    id=uuid4(),
                    device_id="esp32-002",
                    name="Test Device 2",
                    api_key_hash="hash2",
                    status=DeviceStatus.OFFLINE,
                    created_at=datetime.now(UTC),
                    last_seen=datetime.now(UTC),
                ),
            ]
            mock_service.return_value = mock_svc

            response = await async_client.get("/api/v1/devices")

            assert response.status_code == 200
            data = response.json()
            assert len(data) == 2

    @pytest.mark.asyncio
    async def test_get_device_stats(self, async_client):
        """Test getting device statistics."""
        device_id = str(uuid4())

        with patch('app.api.devices.routes.get_device_service') as mock_service:
            mock_svc = AsyncMock()
            mock_svc.get_device_stats.return_value = {
                "device_id": "esp32-001",
                "total_readings": 1000,
                "avg_temperature": 25.0,
                "avg_humidity": 50.0,
                "avg_voltage": 3.3,
                "last_reading": datetime.now(UTC).isoformat(),
            }
            mock_service.return_value = mock_svc

            response = await async_client.get(f"/api/v1/devices/{device_id}/stats")

            assert response.status_code == 200
