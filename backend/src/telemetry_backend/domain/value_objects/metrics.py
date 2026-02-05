"""
Sensor metrics value object.

Encapsulates sensor measurements with explicit units and validation.
Immutable to ensure data integrity.
"""

from dataclasses import dataclass
from typing import Self


@dataclass(frozen=True, slots=True)
class SensorMetrics:
    """
    Sensor metrics value object.
    
    Contains validated sensor readings with explicit units:
    - temperature: Degrees Celsius (°C)
    - humidity: Relative humidity percentage (%)
    - voltage: Volts (V)
    
    All fields are optional to support partial readings from devices
    that may not have all sensors.
    
    Attributes:
        temperature: Temperature in degrees Celsius. Valid range: -40 to 85°C.
        humidity: Relative humidity percentage. Valid range: 0 to 100%.
        voltage: Battery/power voltage in volts. Valid range: 0 to 24V.
    """

    temperature: float | None = None
    humidity: float | None = None
    voltage: float | None = None

    # Physical constraints for sensor validation
    TEMP_MIN: float = -40.0
    TEMP_MAX: float = 85.0
    HUMIDITY_MIN: float = 0.0
    HUMIDITY_MAX: float = 100.0
    VOLTAGE_MIN: float = 0.0
    VOLTAGE_MAX: float = 24.0

    def __post_init__(self) -> None:
        """Validate metric values are within physical constraints."""
        if self.temperature is not None:
            if not self.TEMP_MIN <= self.temperature <= self.TEMP_MAX:
                raise ValueError(
                    f"Temperature must be between {self.TEMP_MIN} and {self.TEMP_MAX}°C, "
                    f"got {self.temperature}"
                )

        if self.humidity is not None:
            if not self.HUMIDITY_MIN <= self.humidity <= self.HUMIDITY_MAX:
                raise ValueError(
                    f"Humidity must be between {self.HUMIDITY_MIN} and {self.HUMIDITY_MAX}%, "
                    f"got {self.humidity}"
                )

        if self.voltage is not None:
            if not self.VOLTAGE_MIN <= self.voltage <= self.VOLTAGE_MAX:
                raise ValueError(
                    f"Voltage must be between {self.VOLTAGE_MIN} and {self.VOLTAGE_MAX}V, "
                    f"got {self.voltage}"
                )

    @classmethod
    def from_dict(cls, data: dict) -> Self:
        """
        Create metrics from dictionary.
        
        Args:
            data: Dictionary with optional temperature, humidity, voltage keys.
            
        Returns:
            New SensorMetrics instance.
            
        Raises:
            ValueError: If any metric value is out of valid range.
        """
        return cls(
            temperature=data.get("temperature"),
            humidity=data.get("humidity"),
            voltage=data.get("voltage"),
        )

    def to_dict(self) -> dict:
        """
        Convert to dictionary, excluding None values.
        
        Returns:
            Dictionary with only non-None metric values.
        """
        result = {}
        if self.temperature is not None:
            result["temperature"] = self.temperature
        if self.humidity is not None:
            result["humidity"] = self.humidity
        if self.voltage is not None:
            result["voltage"] = self.voltage
        return result

    @property
    def has_any_metric(self) -> bool:
        """Check if at least one metric is present."""
        return any([
            self.temperature is not None,
            self.humidity is not None,
            self.voltage is not None,
        ])

    def __str__(self) -> str:
        parts = []
        if self.temperature is not None:
            parts.append(f"temp={self.temperature}°C")
        if self.humidity is not None:
            parts.append(f"humidity={self.humidity}%")
        if self.voltage is not None:
            parts.append(f"voltage={self.voltage}V")
        return f"Metrics({', '.join(parts) or 'empty'})"
