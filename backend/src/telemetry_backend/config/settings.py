"""
Application settings management.

All configuration is loaded from environment variables with sensible defaults.
Secrets are never stored in code.
"""

from functools import lru_cache
from typing import Literal

from pydantic import Field, PostgresDsn, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """
    Application settings loaded from environment variables.

    Uses pydantic-settings for type-safe configuration management.
    All sensitive values must be provided via environment variables.
    """

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # Application
    app_name: str = Field(default="telemetry-backend", description="Application name")
    app_env: Literal["development", "staging", "production"] = Field(
        default="development", description="Application environment"
    )
    debug: bool = Field(default=False, description="Debug mode flag")

    # Server
    host: str = Field(default="0.0.0.0", description="Server host")
    port: int = Field(default=8000, ge=1, le=65535, description="Server port")

    # Database
    database_url: PostgresDsn = Field(
        ..., description="PostgreSQL connection URL with asyncpg driver"
    )
    db_pool_size: int = Field(default=5, ge=1, le=100, description="Database pool size")
    db_max_overflow: int = Field(default=10, ge=0, le=100, description="Max pool overflow")
    db_pool_timeout: int = Field(default=30, ge=1, description="Pool timeout in seconds")

    # Security
    api_secret_key: str = Field(..., min_length=16, description="API secret key")
    device_api_keys: str = Field(
        default="", description="Comma-separated list of valid device API keys"
    )

    # Logging
    log_level: Literal["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"] = Field(
        default="INFO", description="Logging level"
    )
    log_format: Literal["json", "console"] = Field(default="json", description="Log output format")

    # WebSocket
    ws_heartbeat_interval: int = Field(
        default=30, ge=5, le=300, description="WebSocket heartbeat interval in seconds"
    )
    ws_max_connections: int = Field(default=1000, ge=1, description="Maximum WebSocket connections")

    # Aggregation
    aggregation_cache_ttl: int = Field(
        default=60, ge=1, description="Aggregation cache TTL in seconds"
    )
    history_default_limit: int = Field(
        default=1000, ge=1, le=10000, description="Default history query limit"
    )

    @field_validator("device_api_keys", mode="before")
    @classmethod
    def parse_device_keys(cls, v: str) -> str:
        """Validate device API keys format."""
        return v.strip() if v else ""

    @property
    def device_api_keys_set(self) -> set[str]:
        """Parse device API keys into a set for O(1) lookup."""
        if not self.device_api_keys:
            return set()
        return {key.strip() for key in self.device_api_keys.split(",") if key.strip()}

    @property
    def is_production(self) -> bool:
        """Check if running in production environment."""
        return self.app_env == "production"

    @property
    def database_url_str(self) -> str:
        """Get database URL as string."""
        return str(self.database_url)


@lru_cache
def get_settings() -> Settings:
    """
    Get cached application settings.

    Uses lru_cache to ensure settings are loaded only once.
    """
    return Settings()
