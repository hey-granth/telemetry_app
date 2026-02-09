# Database Migrations Guide

## Overview

This project uses **Alembic** as the single source of truth for database schema management. All schema changes are managed through migrations.

---

## Architecture

```
backend/
├── app/
│   └── db/
│       ├── base.py          # Declarative Base (all models inherit from this)
│       ├── models.py         # SQLAlchemy ORM models
│       ├── session.py        # Database connection & session management
│       └── __init__.py
├── alembic/
│   ├── env.py               # Alembic environment config
│   └── versions/            # Migration scripts
└── alembic.ini              # Alembic configuration
```

### Key Principles

1. **Models define intent** - SQLAlchemy models in `app/db/models.py`
2. **Migrations define reality** - Alembic migrations create actual schema
3. **Runtime assumes reality exists** - Application expects tables to exist

---

## Initial Setup

### 1. Database exists but tables don't

This was the original problem. Fix:

```bash
cd backend

# Generate initial migration from models
alembic revision --autogenerate -m "initial schema"

# Apply migration to create tables
alembic upgrade head
```

### 2. Verify tables exist

```bash
# For SQLite
sqlite3 dev.db ".tables"

# Check migration status
alembic current
```

---

## Ongoing Development

### Making Schema Changes

1. **Modify models** in `app/db/models.py`

```python
# Example: Add a new column
class DeviceModel(Base):
    __tablename__ = "devices"
    
    # ...existing columns...
    
    # New column
    location: Mapped[str | None] = mapped_column(
        String(255),
        nullable=True,
        comment="Device location",
    )
```

2. **Generate migration** (Alembic detects changes automatically)

```bash
alembic revision --autogenerate -m "add device location"
```

3. **Review the generated migration** in `alembic/versions/`

```python
# Example generated migration
def upgrade() -> None:
    op.add_column('devices', sa.Column('location', sa.String(255), nullable=True))

def downgrade() -> None:
    op.drop_column('devices', 'location')
```

4. **Apply migration**

```bash
alembic upgrade head
```

### Verify Schema is in Sync

```bash
# Check for any unapplied migrations
alembic check
```

---

## Common Commands

```bash
# Show current migration version
alembic current

# Show migration history
alembic history --verbose

# Upgrade to latest
alembic upgrade head

# Upgrade to specific version
alembic upgrade <revision_id>

# Downgrade one migration
alembic downgrade -1

# Downgrade to specific version
alembic downgrade <revision_id>

# Generate new migration
alembic revision --autogenerate -m "description"

# Create empty migration (for manual changes)
alembic revision -m "manual change"
```

---

## Production Deployment

### Deployment Checklist

1. **Generate and test migration locally**
   ```bash
   alembic revision --autogenerate -m "description"
   alembic upgrade head
   # Test the application
   ```

2. **Commit migration files** to version control
   ```bash
   git add alembic/versions/*.py
   git commit -m "Add migration: description"
   ```

3. **Deploy to production**
   ```bash
   # On production server, before starting app
   alembic upgrade head
   
   # Then start application
   uvicorn app.main:app
   ```

### Critical Rules

- ✅ **ALWAYS** run `alembic upgrade head` before starting the application
- ✅ **ALWAYS** test migrations locally first
- ✅ **ALWAYS** commit migration files to git
- ❌ **NEVER** use `Base.metadata.create_all()` in production
- ❌ **NEVER** manually create tables
- ❌ **NEVER** modify applied migrations (create new ones instead)

---

## Local Development Bootstrap

For clean development setup:

```bash
cd backend

# Install dependencies
pip install -r requirements.txt

# Apply all migrations
alembic upgrade head

# Start development server
uvicorn app.main:app --reload
```

### Fresh Database Setup

```bash
# Remove existing database
rm dev.db

# Apply migrations to create schema
alembic upgrade head

# Verify
sqlite3 dev.db ".tables"
# Expected output: alembic_version  devices  readings
```

---

## Troubleshooting

### "No such table: devices"

**Cause**: Migrations not applied

**Solution**:
```bash
alembic upgrade head
```

### "Can't locate revision"

**Cause**: alembic_version table out of sync

**Solution**:
```bash
# Check current state
alembic current

# Force stamp to a specific version (careful!)
alembic stamp head
```

### "Target database is not up to date"

**Cause**: Schema drift between models and database

**Solution**:
```bash
# Check what's different
alembic check

# Generate migration to fix drift
alembic revision --autogenerate -m "sync schema"
alembic upgrade head
```

### Alembic can't detect models

**Cause**: Models not imported in `app/db/base.py`

**Solution**: Ensure `app/db/base.py` imports all models:
```python
from app.db.base import Base
# Models are imported inside base.py via __import_models()
```

---

## Testing

### Run migrations in tests

```python
# tests/conftest.py
import pytest
from alembic import command
from alembic.config import Config

@pytest.fixture
async def test_db():
    # Create test database
    alembic_cfg = Config("alembic.ini")
    alembic_cfg.set_main_option("sqlalchemy.url", "sqlite+aiosqlite:///:memory:")
    
    # Run migrations
    command.upgrade(alembic_cfg, "head")
    
    yield
    
    # Cleanup
    command.downgrade(alembic_cfg, "base")
```

---

## Database-Specific Notes

### SQLite (Development)

- Uses `NUMERIC` type for UUIDs (stored as strings)
- No connection pooling
- Single file database: `dev.db`

### PostgreSQL (Production)

- Native `UUID` type support
- Connection pooling enabled
- Settings: `DB_POOL_SIZE`, `DB_MAX_OVERFLOW`, `DB_POOL_TIMEOUT`

---

## Model Registration

All models must:

1. **Inherit from Base**
   ```python
   from app.db.base import Base
   
   class MyModel(Base):
       __tablename__ = "my_table"
       # ...
   ```

2. **Be imported in `app/db/models.py`** (they already are in this file)

3. **Base.metadata will automatically include them** for Alembic detection

The import chain:
```
alembic/env.py → app.db.base.Base → app.db.models (via __import_models)
```

---

## FAQ

**Q: Can I use `Base.metadata.create_all()` during development?**

A: Not recommended. Always use migrations. If absolutely needed for rapid prototyping:

```python
# ONLY for local dev, NEVER in production
if settings.app_env == "development":
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
```

**Q: How do I handle data migrations?**

A: Create a migration with custom SQL:

```bash
alembic revision -m "migrate_device_data"
```

```python
def upgrade():
    # Run custom SQL
    op.execute("UPDATE devices SET location = 'unknown' WHERE location IS NULL")

def downgrade():
    pass
```

**Q: Should I commit `dev.db` to git?**

A: No. Add to `.gitignore`:
```
*.db
*.db-journal
```

**Q: How do I reset everything?**

```bash
rm dev.db
alembic upgrade head
```

---

## Summary

✅ **Correct workflow:**
1. Modify models
2. Generate migration: `alembic revision --autogenerate -m "description"`
3. Review generated migration
4. Apply migration: `alembic upgrade head`
5. Test application
6. Commit migration files

❌ **Forbidden:**
- Manually creating tables
- Running app without applying migrations
- Using `create_all()` in production
- Ignoring Alembic

---

**Remember**: If the backend fails with "no such table", you forgot to run migrations!

