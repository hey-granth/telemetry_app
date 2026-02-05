"""Initial migration - create devices and readings tables

Revision ID: 001_initial
Revises: 
Create Date: 2024-01-15
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = "001_initial"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Create devices table
    op.create_table(
        "devices",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            nullable=False,
            comment="Unique device identifier (UUID)",
        ),
        sa.Column(
            "device_id",
            sa.String(64),
            nullable=False,
            comment="Human-readable device identifier",
        ),
        sa.Column(
            "name",
            sa.String(255),
            nullable=True,
            comment="Friendly device name",
        ),
        sa.Column(
            "api_key_hash",
            sa.String(128),
            nullable=False,
            comment="Hashed API key for authentication",
        ),
        sa.Column(
            "is_active",
            sa.Boolean(),
            nullable=False,
            default=True,
            comment="Whether device is currently active",
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            comment="Device registration timestamp (UTC)",
        ),
        sa.Column(
            "last_seen_at",
            sa.DateTime(timezone=True),
            nullable=True,
            comment="Timestamp of last reading received (UTC)",
        ),
        sa.PrimaryKeyConstraint("id"),
        comment="Registered IoT devices",
    )

    # Create indexes for devices
    op.create_index("ix_devices_device_id", "devices", ["device_id"], unique=True)

    # Create readings table
    op.create_table(
        "readings",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            nullable=False,
            comment="Unique reading identifier (UUID)",
        ),
        sa.Column(
            "device_id",
            sa.String(64),
            nullable=False,
            comment="Device that produced this reading",
        ),
        sa.Column(
            "timestamp",
            sa.DateTime(timezone=True),
            nullable=False,
            comment="Server-assigned timestamp (UTC)",
        ),
        sa.Column(
            "temperature",
            sa.Float(),
            nullable=True,
            comment="Temperature in degrees Celsius",
        ),
        sa.Column(
            "humidity",
            sa.Float(),
            nullable=True,
            comment="Relative humidity percentage",
        ),
        sa.Column(
            "voltage",
            sa.Float(),
            nullable=True,
            comment="Power/battery voltage in volts",
        ),
        sa.ForeignKeyConstraint(
            ["device_id"],
            ["devices.device_id"],
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id"),
        comment="Immutable sensor readings time-series",
    )

    # Create indexes for readings
    op.create_index(
        "ix_readings_device_timestamp",
        "readings",
        ["device_id", "timestamp"],
    )
    op.create_index(
        "ix_readings_timestamp",
        "readings",
        ["timestamp"],
    )


def downgrade() -> None:
    op.drop_index("ix_readings_timestamp", table_name="readings")
    op.drop_index("ix_readings_device_timestamp", table_name="readings")
    op.drop_table("readings")
    op.drop_index("ix_devices_device_id", table_name="devices")
    op.drop_table("devices")
