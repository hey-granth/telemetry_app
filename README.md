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

### Backend (FastAPI + PostgreSQL)

- **Framework**: FastAPI with async SQLAlchemy
- **Database**: PostgreSQL with Alembic migrations
- **Architecture**: Clean Architecture with layered separation
- **Features**:
  - REST API for device management and data queries
  - WebSocket real-time streaming
  - Async database operations
  - Pydantic v2 validation
  - Structured logging

### Flutter Client

- **Framework**: Flutter 3.2+
- **State Management**: Riverpod
- **Architecture**: Clean Architecture with feature-based organization
- **Features**:
  - Device monitoring dashboard
  - Real-time sensor data visualization
  - Historical data charts
  - WebSocket live streaming

### ESP32 Devices

- **Protocol**: HTTP POST for data ingestion
- **Authentication**: API key-based
- **See**: [ESP32 Protocol Documentation](docs/ESP32_PROTOCOL.md)

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

4. Run database migrations:
   ```bash
   docker-compose exec backend alembic upgrade head
   ```

5. Access the API:
   - API: http://localhost:8000
   - API Docs: http://localhost:8000/docs
   - Health: http://localhost:8000/health

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
# Edit .env with your local PostgreSQL settings

# Run migrations
alembic upgrade head

# Start development server
uvicorn app.main:app --reload
```

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
│   │   ├── api/              # REST endpoints
│   │   ├── config/           # Configuration
│   │   ├── domain/           # Entities, value objects
│   │   ├── infrastructure/   # Database, WebSocket
│   │   ├── repositories/     # Data access
│   │   └── services/         # Business logic
│   ├── alembic/              # Database migrations
│   ├── tests/                # Unit & integration tests
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
│   └── ESP32_PROTOCOL.md
├── docker-compose.yml
└── README.md
```

## API Endpoints

### Health
- `GET /health` - System health check

### Ingest
- `POST /api/v1/ingest` - Submit sensor reading

### Devices
- `GET /api/v1/devices` - List all devices
- `GET /api/v1/devices/{id}` - Get device details
- `GET /api/v1/devices/{id}/stats` - Get device statistics
- `GET /api/v1/devices/{id}/history` - Get reading history

### Real-time
- `WS /stream/{device_id}` - WebSocket connection for live data

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DATABASE_URL` | - | PostgreSQL connection string |
| `APP_ENV` | `development` | Environment (development/production) |
| `SECRET_KEY` | - | Application secret key |
| `LOG_LEVEL` | `info` | Logging level |
| `CORS_ORIGINS` | `*` | Allowed CORS origins |

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

- [ ] Set strong `SECRET_KEY`
- [ ] Configure `DATABASE_URL` for production PostgreSQL
- [ ] Set `APP_ENV=production`
- [ ] Configure proper `CORS_ORIGINS`
- [ ] Enable HTTPS/TLS
- [ ] Set up monitoring and alerting
- [ ] Configure backup strategy for PostgreSQL

### Docker Production

```bash
docker-compose -f docker-compose.yml up -d --build
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests
5. Submit a pull request

## License

MIT License - see LICENSE file for details
