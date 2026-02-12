# Telemetry App - IoT Data Platform

A production-grade IoT data platform with three decoupled components: FastAPI backend, Flutter client, and ESP32 device integration.

## Architecture Overview

```
┌─────────────┐     HTTP/WS      ┌─────────────────┐     PostgreSQL    ┌────────────┐
│   ESP32     │ ───────────────▶ │  FastAPI        │ ◀───────────────▶ │ PostgreSQL │
│  Devices    │                  │  Backend        │                   │  Database  │
└─────────────┘                  └────────┬────────┘                   └────────────┘
                                          │
                                    HTTP/WS
                                          │
                                 ┌────────▼────────┐
                                 │    Flutter      │
                                 │    Client       │
                                 └─────────────────┘
```

## Components

### Backend (FastAPI + PostgreSQL/SQLite)

- **Framework**: FastAPI with async SQLAlchemy 2.x
- **Database**: SQLite (development) / PostgreSQL (production) with Alembic migrations
- **Architecture**: Clean Architecture with layered separation
- **Features**:
  - REST API for device management and data queries
  - WebSocket real-time streaming
  - Async database operations with connection pooling
  - Pydantic v2 validation
  - Structured logging (JSON/console)
  - Migration-based schema management

### Flutter Client

- **Framework**: Flutter 3.2+
- **State Management**: Riverpod
- **Architecture**: Clean Architecture with feature-based organization
- **Features**:
  - Device monitoring dashboard
  - Real-time sensor data visualization
  - Historical data charts
  - WebSocket live streaming
  - **ESP32 BLE Provisioning** (Security 2 with SRP6a)
- **See**: [Flutter Client README](flutter_client/README.md)
- **ESP32 Provisioning**: [Provisioning Guide](flutter_client/PROVISIONING.md)

### ESP32 Devices

- **Protocol**: HTTP POST for data ingestion
- **Authentication**: API key-based
- **Provisioning**: BLE with Security 2 (SRP6a)
- **See**: 
  - [ESP32 Protocol Documentation](docs/ESP32_PROTOCOL.md)
  - [ESP32 Firmware Guide](docs/ESP32_FIRMWARE.md)
  - [BLE Provisioning Guide](flutter_client/PROVISIONING.md)

## Quick Start

### Prerequisites

- Docker & Docker Compose
- Python 3.12+ (for local development)
- Flutter SDK 3.2+ (for client development)

### Using Docker (Recommended)

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd telemetry_app
   ```

2. Copy environment configuration:
   ```bash
   cp .env.example .env
   # Edit .env with your settings
   ```

3. Start all services:
   ```bash
   docker-compose up -d
   ```

4. **⚠️ CRITICAL: Run database migrations** (creates tables):
   ```bash
   docker-compose exec backend alembic upgrade head
   ```
   
   > **Note**: Skipping this step will cause "no such table" errors!

5. Access the API:
   - API: http://localhost:8000
   - API Docs: http://localhost:8000/docs
   - Health: http://localhost:8000/api/v1/health

### Local Development

#### Backend

```bash
cd backend

# Create virtual environment
python -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Set up environment
cp .env.example .env
# Edit .env with your database settings
# For local dev: DATABASE_URL=sqlite+aiosqlite:///./dev.db
# For production: DATABASE_URL=postgresql+asyncpg://user:pass@host/db

# ⚠️ CRITICAL: Run migrations to create database tables
alembic upgrade head

# Verify tables exist
sqlite3 dev.db ".tables"  # For SQLite
# Expected output: alembic_version  devices  readings

# Start development server
uvicorn app.main:app --reload
# API available at: http://localhost:8000/docs
```

> **Troubleshooting**: If you see "no such table: devices" error, run `alembic upgrade head`
> 
> See [backend/README.md](backend/README.md) for detailed setup guide  
> See [backend/MIGRATIONS.md](backend/MIGRATIONS.md) for migration workflow

#### Flutter Client

```bash
cd flutter_client

# Get dependencies
flutter pub get

# Run the app
flutter run -d chrome  # Web
flutter run -d macos   # macOS
flutter run            # Default device
```

## Project Structure

```
telemetry_app/
├── backend/
│   ├── app/
│   │   ├── api/              # REST endpoints & dependencies
│   │   ├── config/           # Settings & logging
│   │   ├── db/               # Database layer (NEW)
│   │   │   ├── base.py       # Declarative Base
│   │   │   ├── models.py     # ORM models
│   │   │   └── session.py    # Connection management
│   │   ├── domain/           # Entities, value objects
│   │   ├── infrastructure/   # WebSocket & external services
│   │   ├── repositories/     # Data access layer
│   │   └── services/         # Business logic
│   ├── alembic/              # Database migrations
│   │   ├── versions/         # Migration scripts
│   │   └── env.py            # Alembic configuration
│   ├── tests/                # Unit & integration tests
│   ├── README.md             # Backend quick start
│   ├── MIGRATIONS.md         # Migration workflow guide
│   ├── init-db.sh            # Database initialization script
│   ├── Dockerfile
│   └── requirements.txt
├── flutter_client/
│   ├── lib/
│   │   ├── core/             # Shared utilities
│   │   └── features/         # Feature modules
│   │       ├── dashboard/
│   │       ├── devices/
│   │       └── live_stream/
│   ├── test/
│   └── pubspec.yaml
├── docs/
│   └── ESP32_PROTOCOL.md     # ESP32 integration guide
├── docker-compose.yml
└── README.md
```

## API Endpoints

All endpoints are prefixed with `/api/v1`

### Health
- `GET /api/v1/health` - System health check (returns status, timestamp, websocket connections)

### Ingest (Device Authentication Required)
- `POST /api/v1/ingest` - Submit sensor reading
- `POST /api/v1/ingest/batch` - Submit multiple readings

### Devices (Admin Authentication Required)
- `POST /api/v1/devices` - Register new device
- `GET /api/v1/devices` - List all active devices
- `GET /api/v1/devices/{device_id}` - Get device details
- `GET /api/v1/devices/{device_id}/history` - Query historical readings
- `GET /api/v1/devices/{device_id}/aggregate` - Get aggregated statistics (min/max/avg)

### Real-time (WebSocket)
- `WS /api/v1/realtime/subscribe/{device_id}` - Subscribe to live device updates

### Authentication
- Admin endpoints require: `X-API-Key: <admin-secret>`
- Device endpoints require: `X-API-Key: <device-key>`

See [API Documentation](http://localhost:8000/docs) when running locally.

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DATABASE_URL` | *required* | Database connection string<br/>SQLite: `sqlite+aiosqlite:///./dev.db`<br/>PostgreSQL: `postgresql+asyncpg://user:pass@host/db` |
| `APP_ENV` | `development` | Environment (development/staging/production) |
| `API_SECRET_KEY` | *required* | Admin API secret key (min 16 chars) |
| `DEVICE_API_KEYS` | `` | Comma-separated device API keys |
| `LOG_LEVEL` | `info` | Logging level (DEBUG/INFO/WARNING/ERROR/CRITICAL) |
| `LOG_FORMAT` | `json` | Log format (json/console) |
| `DEBUG` | `false` | Enable debug mode (SQL logging) |
| `HOST` | `0.0.0.0` | Server bind host |
| `PORT` | `8000` | Server port |
| `DB_POOL_SIZE` | `5` | Database connection pool size |
| `WS_HEARTBEAT_INTERVAL` | `30` | WebSocket heartbeat interval (seconds) |

See backend `.env.example` for complete configuration template.

### Flutter Configuration

Edit `lib/core/config/app_config.dart` to set:
- API base URL
- WebSocket URL
- Default settings

## Testing

### Backend Tests

```bash
cd backend
pytest
pytest --cov=app  # With coverage
```

### Flutter Tests

```bash
cd flutter_client
flutter test
flutter test --coverage
```

## Deployment

### Production Checklist

**⚠️ Critical Steps:**
- [ ] **Run database migrations BEFORE starting app**: `alembic upgrade head`
- [ ] Set strong `API_SECRET_KEY` (min 32 characters, use `secrets.token_urlsafe(32)`)
- [ ] Configure `DATABASE_URL` for production PostgreSQL
- [ ] Generate unique `DEVICE_API_KEYS` for each device
- [ ] Set `APP_ENV=production`
- [ ] Set `DEBUG=false`
- [ ] Set `LOG_FORMAT=json`
- [ ] Configure connection pool settings (`DB_POOL_SIZE`, `DB_MAX_OVERFLOW`)
- [ ] Enable HTTPS/TLS
- [ ] Set up monitoring and alerting
- [ ] Configure automated backups for PostgreSQL
- [ ] Test migration rollback procedure

### Docker Production

```bash
# Build images
docker-compose -f docker-compose.yml build

# Start database first
docker-compose up -d postgres

# Run migrations (CRITICAL!)
docker-compose run backend alembic upgrade head

# Start all services
docker-compose up -d
```

### Migration Workflow

**For schema changes:**
```bash
# 1. Modify models in app/db/models.py
# 2. Generate migration
alembic revision --autogenerate -m "description"
# 3. Review migration in alembic/versions/
# 4. Test locally
alembic upgrade head
# 5. Commit migration files to git
# 6. Deploy: run migrations before starting app
```

See [backend/MIGRATIONS.md](backend/MIGRATIONS.md) for detailed migration guide.

## Common Issues

### ❌ "no such table: devices"

**Cause**: Database migrations haven't been run.

**Solution**:
```bash
cd backend
alembic upgrade head
```

### ❌ "Database not initialized"

**Cause**: App can't connect to database.

**Solution**: Check `DATABASE_URL` in `.env` file is correct.

### ❌ "Invalid API key"

**Cause**: Missing or incorrect `X-API-Key` header.

**Solution**: 
- Admin endpoints: Use value from `API_SECRET_KEY`
- Device endpoints: Use one of `DEVICE_API_KEYS`

### ❌ Fresh Start Needed

```bash
cd backend
rm dev.db  # Remove old database
alembic upgrade head  # Recreate tables
uvicorn app.main:app --reload
```

See component-specific READMEs for more troubleshooting:
- [Backend README](backend/README.md)
- [Backend Migrations Guide](backend/MIGRATIONS.md)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add/update tests
5. If schema changed: Generate migration with `alembic revision --autogenerate`
6. Run tests: `pytest` (backend) or `flutter test` (client)
7. Update documentation
8. Submit a pull request

## License

MIT License - see LICENSE file for details
