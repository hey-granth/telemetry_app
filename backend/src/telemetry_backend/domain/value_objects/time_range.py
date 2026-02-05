"""
Time range value object.

Represents a validated time range for querying historical data.
"""

import re
from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Self


@dataclass(frozen=True, slots=True)
class TimeRange:
    """
    Time range value object for historical queries.

    Ensures start is before end and provides parsing utilities
    for common time range formats.

    Attributes:
        start: Start of the time range (inclusive, UTC).
        end: End of the time range (inclusive, UTC).
    """

    start: datetime
    end: datetime

    def __post_init__(self) -> None:
        """Validate that start is before end."""
        if self.start >= self.end:
            raise ValueError(f"Start time must be before end time: {self.start} >= {self.end}")

    @classmethod
    def last(cls, duration_str: str, now: datetime | None = None) -> Self:
        """
        Create a time range for the last N hours/days/minutes.

        Args:
            duration_str: Duration string like "24h", "7d", "30m".
            now: Reference timestamp (defaults to current UTC time).

        Returns:
            TimeRange from (now - duration) to now.

        Raises:
            ValueError: If duration string format is invalid.
        """
        now = now or datetime.utcnow()

        # Parse duration string
        pattern = r"^(\d+)([hdmw])$"
        match = re.match(pattern, duration_str.lower())

        if not match:
            raise ValueError(
                f"Invalid duration format: '{duration_str}'. "
                "Expected format: <number><unit> where unit is h(ours), d(ays), m(inutes), or w(eeks). "
                "Examples: '24h', '7d', '30m', '2w'"
            )

        value = int(match.group(1))
        unit = match.group(2)

        if value <= 0:
            raise ValueError(f"Duration must be positive: {value}")

        # Calculate delta based on unit
        if unit == "m":
            delta = timedelta(minutes=value)
        elif unit == "h":
            delta = timedelta(hours=value)
        elif unit == "d":
            delta = timedelta(days=value)
        elif unit == "w":
            delta = timedelta(weeks=value)
        else:
            raise ValueError(f"Unknown time unit: {unit}")

        return cls(start=now - delta, end=now)

    @classmethod
    def between(cls, start: datetime, end: datetime) -> Self:
        """
        Create a time range between two timestamps.

        Args:
            start: Start timestamp (UTC).
            end: End timestamp (UTC).

        Returns:
            TimeRange instance.

        Raises:
            ValueError: If start is not before end.
        """
        return cls(start=start, end=end)

    @property
    def duration(self) -> timedelta:
        """Get the duration of this time range."""
        return self.end - self.start

    @property
    def duration_seconds(self) -> float:
        """Get duration in seconds."""
        return self.duration.total_seconds()

    def __str__(self) -> str:
        return f"TimeRange({self.start.isoformat()} to {self.end.isoformat()})"
