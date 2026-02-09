# Telemetry Backend

Production-grade IoT telemetry data platform for sensor data ingestion, persistence, aggregation, and realtime streaming.

## Quick Start

### Prerequisites

- Python 3.11+
- SQLite (for local dev) or PostgreSQL (for production)

### Setup

1. **Clone and navigate to backend**
   ```bash
   cd backend
   ```

2. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   # or using uv
   uv sync
   ```

3. **Configure environment**
   ```bash
   cp .env.example .env
   # Edit .env with your settings
   ```

4. **Initialize database schema** ⚠️ **CRITICAL STEP**
   ```bash
   # Apply migrations to create tables
   alembic upgrade head
   
   # Verify tables exist
   sqlite3 dev.db ".tables"
   # Expected: alembic_version  devices  readings
   ```

5. **Start development server**
   ```bash
   uvicorn app.main:app --reload
   ```

6. **Access API docs**
   - Swagger UI: http://localhost:8000/docs
   - ReDoc: http://localhost:8000/redoc

---

## ⚠️ Common Issue: "no such table: devices"

**If you see this error**, it means migrations haven't been run.

**Solution:**
```bash
cd backend
alembic upgrade head
```

See [MIGRATIONS.md](./MIGRATIONS.md) for full details.

---

## Project Structure

```
backend/
├── app/
│   ├── db/                  # Database layer
│   │   ├── base.py         # Declarative Base
│   │   ├── models.py       # SQLAlchemy ORM models
│   │   └── session.py      # Connection management
│   ├── api/                # API routes
│   ├── domain/             # Domain entities & value objects
│   ├── services/           # Business logic
│   ├── repositories/       # Data access layer
│   └── config/             # Configuration
├── alembic/                # Database migrations
│   ├── versions/           # Migration scripts
│   └── env.py             # Alembic config
├── tests/                  # Test suite
└── alembic.ini            # Alembic configuration
```

---

## Features

- **Device Management**: Register and manage IoT devices with API key authentication
- **Data Ingestion**: High-throughput sensor data ingestion from ESP32/IoT devices
- **Time-Series Storage**: Efficient storage of immutable sensor readings
- **Aggregation**: Compute statistics (min, max, avg) over time ranges
- **Realtime Streaming**: WebSocket subscriptions for live data updates
- **Production-Ready**: Structured logging, connection pooling, async I/O

---

## API Endpoints

### Health

- `GET /api/v1/health` - Health check

### Devices

- `POST /api/v1/devices` - Register new device (admin)
- `GET /api/v1/devices` - List all devices (admin)
- `GET /api/v1/devices/{device_id}` - Get device details

### Ingestion

- `POST /api/v1/ingest` - Submit sensor reading (device auth)
- `POST /api/v1/ingest/batch` - Submit multiple readings (device auth)

### Query

- `GET /api/v1/devices/{device_id}/history` - Query historical data
- `GET /api/v1/devices/{device_id}/aggregate` - Get aggregated statistics

### Realtime

- `WS /api/v1/realtime/subscribe/{device_id}` - Subscribe to device updates

---

## Authentication

### Admin Endpoints

Require `X-API-Key` header with admin secret:

```bash
curl -H "X-API-Key: your-admin-secret" \
  http://localhost:8000/api/v1/devices
```

### Device Endpoints

Require `X-API-Key` header with device-specific key:

```bash
curl -H "X-API-Key: device-api-key" \
  -H "Content-Type: application/json" \
  -d '{"temperature": 22.5, "humidity": 65.0}' \
  http://localhost:8000/api/v1/ingest
```

---

## Database Migrations

**All schema changes are managed through Alembic.**

### Initial Setup

```bash
alembic upgrade head
```

### Making Changes

1. Modify models in `app/db/models.py`
2. Generate migration: `alembic revision --autogenerate -m "description"`
3. Review generated migration in `alembic/versions/`
4. Apply migration: `alembic upgrade head`

See [MIGRATIONS.md](./MIGRATIONS.md) for complete guide.

---

## Configuration

Environment variables (set in `.env`):

```bash
# Database
DATABASE_URL=sqlite+aiosqlite:///./dev.db

# Security
API_SECRET_KEY=your-secret-key-min-16-chars
DEVICE_API_KEYS=key1,key2,key3

# Server
HOST=0.0.0.0
PORT=8000
DEBUG=true

# Logging
LOG_LEVEL=info
LOG_FORMAT=console  # or json
```

---

## Development

### Run Tests

```bash
pytest
```

### Code Quality

```bash
# Linting
ruff check .

# Type checking
mypy app/

# Format code
ruff format .
```

### Watch Mode

```bash
uvicorn app.main:app --reload --log-level debug
```

---

## Deployment

### Production Checklist

1. **Set environment variables**
   ```bash
   DATABASE_URL=postgresql+asyncpg://user:pass@host/db
   API_SECRET_KEY=<strong-random-key>
   APP_ENV=production
   DEBUG=false
   LOG_FORMAT=json
   ```

2. **Run migrations** ⚠️ **BEFORE starting app**
   ```bash
   alembic upgrade head
   ```

3. **Start application**
   ```bash
   uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4
   ```

### Docker (Optional)

```bash
docker-compose up -d
```

---

## Architecture

### Layer Separation

- **API Layer** (`app/api/`) - HTTP endpoints, validation
- **Service Layer** (`app/services/`) - Business logic
- **Repository Layer** (`app/repositories/`) - Data access
- **Domain Layer** (`app/domain/`) - Core entities (framework-agnostic)
- **Infrastructure** (`app/db/`, `app/config/`) - External concerns

### Database Schema

**devices** - Registered IoT devices
```
id          UUID PRIMARY KEY
device_id   VARCHAR(64) UNIQUE
name        VARCHAR(255)
api_key_hash VARCHAR(128)
is_active   BOOLEAN
created_at  TIMESTAMP
last_seen_at TIMESTAMP
```

**readings** - Immutable sensor readings (append-only)
```
id          UUID PRIMARY KEY
device_id   VARCHAR(64) FOREIGN KEY
timestamp   TIMESTAMP (server-assigned)
temperature FLOAT
humidity    FLOAT
voltage     FLOAT
```

---

## Troubleshooting

### "no such table: devices"

Run migrations:
```bash
alembic upgrade head
```

### "Database not initialized"

The app failed to connect to the database. Check `DATABASE_URL` in `.env`.

### "Invalid API key"

Check that `X-API-Key` header matches:
- `API_SECRET_KEY` for admin endpoints
- One of `DEVICE_API_KEYS` for device endpoints

### Fresh start

```bash
rm dev.db
alembic upgrade head
uvicorn app.main:app --reload
```

---

## Contributing

1. Create feature branch
2. Make changes
3. Add tests
4. Run tests and linting
5. Create migration if schema changed
6. Submit PR

---

## License

MIT

