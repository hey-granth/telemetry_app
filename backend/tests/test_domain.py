import pytest
from datetime import datetime, timezone
from uuid import uuid4

from app.domain.entities.device import Device, DeviceStatus
from app.domain.entities.reading import Reading
from app.domain.value_objects.metrics import SensorMetrics
from app.domain.value_objects.time_range import TimeRange


class TestDevice:
    """Tests for Device entity."""

    def test_device_creation(self):
        """Test device entity creation."""
        device = Device(
            id=uuid4(),
            device_id="esp32-001",
            name="Test Device",
            api_key_hash="hashed_key",
            status=DeviceStatus.ONLINE,
            created_at=datetime.now(timezone.utc),
            last_seen=datetime.now(timezone.utc),
        )

        assert device.device_id == "esp32-001"
        assert device.name == "Test Device"
        assert device.status == DeviceStatus.ONLINE
        assert device.is_online is True

    def test_device_is_offline(self):
        """Test device offline status check."""
        device = Device(
            id=uuid4(),
            device_id="esp32-001",
            name="Test Device",
            api_key_hash="hashed_key",
            status=DeviceStatus.OFFLINE,
            created_at=datetime.now(timezone.utc),
            last_seen=datetime.now(timezone.utc),
        )

        assert device.is_online is False

    def test_device_status_values(self):
        """Test all device status values."""
        assert DeviceStatus.ONLINE.value == "online"
        assert DeviceStatus.OFFLINE.value == "offline"
        assert DeviceStatus.UNKNOWN.value == "unknown"


class TestReading:
    """Tests for Reading entity."""

    def test_reading_creation(self):
        """Test reading entity creation."""
        device_id = uuid4()
        metrics = SensorMetrics(temperature=25.0, humidity=50.0, voltage=3.3)
        
        reading = Reading(
            id=uuid4(),
            device_id=device_id,
            timestamp=datetime.now(timezone.utc),
            metrics=metrics,
        )

        assert reading.device_id == device_id
        assert reading.metrics.temperature == 25.0
        assert reading.metrics.humidity == 50.0
        assert reading.metrics.voltage == 3.3


class TestSensorMetrics:
    """Tests for SensorMetrics value object."""

    def test_valid_metrics(self):
        """Test valid sensor metrics creation."""
        metrics = SensorMetrics(temperature=25.0, humidity=50.0, voltage=3.3)

        assert metrics.temperature == 25.0
        assert metrics.humidity == 50.0
        assert metrics.voltage == 3.3

    def test_temperature_validation_min(self):
        """Test temperature minimum validation."""
        with pytest.raises(ValueError, match="temperature"):
            SensorMetrics(temperature=-101.0, humidity=50.0, voltage=3.3)

    def test_temperature_validation_max(self):
        """Test temperature maximum validation."""
        with pytest.raises(ValueError, match="temperature"):
            SensorMetrics(temperature=151.0, humidity=50.0, voltage=3.3)

    def test_humidity_validation_min(self):
        """Test humidity minimum validation."""
        with pytest.raises(ValueError, match="humidity"):
            SensorMetrics(temperature=25.0, humidity=-1.0, voltage=3.3)

    def test_humidity_validation_max(self):
        """Test humidity maximum validation."""
        with pytest.raises(ValueError, match="humidity"):
            SensorMetrics(temperature=25.0, humidity=101.0, voltage=3.3)

    def test_voltage_validation_min(self):
        """Test voltage minimum validation."""
        with pytest.raises(ValueError, match="voltage"):
            SensorMetrics(temperature=25.0, humidity=50.0, voltage=-0.1)

    def test_voltage_validation_max(self):
        """Test voltage maximum validation."""
        with pytest.raises(ValueError, match="voltage"):
            SensorMetrics(temperature=25.0, humidity=50.0, voltage=60.0)

    def test_metrics_equality(self):
        """Test metrics value equality."""
        m1 = SensorMetrics(temperature=25.0, humidity=50.0, voltage=3.3)
        m2 = SensorMetrics(temperature=25.0, humidity=50.0, voltage=3.3)
        m3 = SensorMetrics(temperature=26.0, humidity=50.0, voltage=3.3)

        assert m1 == m2
        assert m1 != m3


class TestTimeRange:
    """Tests for TimeRange value object."""

    def test_valid_time_range(self):
        """Test valid time range creation."""
        start = datetime(2024, 1, 1, tzinfo=timezone.utc)
        end = datetime(2024, 1, 2, tzinfo=timezone.utc)
        
        tr = TimeRange(start=start, end=end)

        assert tr.start == start
        assert tr.end == end
        assert tr.duration.days == 1

    def test_invalid_time_range(self):
        """Test that end cannot be before start."""
        start = datetime(2024, 1, 2, tzinfo=timezone.utc)
        end = datetime(2024, 1, 1, tzinfo=timezone.utc)

        with pytest.raises(ValueError, match="end.*before.*start"):
            TimeRange(start=start, end=end)

    def test_contains_timestamp(self):
        """Test timestamp containment check."""
        start = datetime(2024, 1, 1, tzinfo=timezone.utc)
        end = datetime(2024, 1, 3, tzinfo=timezone.utc)
        tr = TimeRange(start=start, end=end)

        within = datetime(2024, 1, 2, tzinfo=timezone.utc)
        before = datetime(2023, 12, 31, tzinfo=timezone.utc)
        after = datetime(2024, 1, 4, tzinfo=timezone.utc)

        assert tr.contains(within) is True
        assert tr.contains(before) is False
        assert tr.contains(after) is False
