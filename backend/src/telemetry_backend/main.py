"""
Telemetry Backend API - Main Application

Production-grade IoT data platform for sensor data ingestion,
persistence, aggregation, and realtime streaming.
"""

from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from telemetry_backend.api.devices import router as devices_router
from telemetry_backend.api.health import router as health_router
from telemetry_backend.api.ingest import router as ingest_router
from telemetry_backend.api.realtime import router as realtime_router
from telemetry_backend.config.logging import get_logger, setup_logging
from telemetry_backend.config.settings import get_settings
from telemetry_backend.infrastructure.database import close_database, init_database

# Initialize settings and logging
settings = get_settings()
setup_logging(settings)
logger = get_logger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    """
    Application lifespan manager.

    Handles startup and shutdown events:
    - Startup: Initialize database connection pool
    - Shutdown: Close database connections gracefully
    """
    # Startup
    logger.info(
        "Starting Telemetry Backend",
        app_name=settings.app_name,
        environment=settings.app_env,
    )

    try:
        await init_database(settings)
        logger.info("Application startup complete")
        yield
    finally:
        # Shutdown
        logger.info("Shutting down Telemetry Backend")
        await close_database()
        logger.info("Application shutdown complete")


# Create FastAPI application
app = FastAPI(
    title="Telemetry API",
    description="""
    Production-grade IoT data platform for sensor data ingestion,
    persistence, aggregation, and realtime streaming.
    
    ## Features
    
    - **Device Management**: Register and manage IoT devices
    - **Data Ingestion**: Receive sensor readings from ESP32 devices
    - **Aggregation**: Compute statistics (min, max, avg) over time ranges
    - **Realtime Streaming**: WebSocket subscriptions for live data
    
    ## Authentication
    
    - Device endpoints require `X-API-Key` header with device API key
    - Admin endpoints require `X-API-Key` header with admin secret key
    
    ## Timestamps
    
    All timestamps are server-assigned UTC. Client timestamps are ignored.
    """,
    version="1.0.0",
    docs_url="/docs" if not settings.is_production else None,
    redoc_url="/redoc" if not settings.is_production else None,
    lifespan=lifespan,
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"] if not settings.is_production else [],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Exception handlers
@app.exception_handler(RequestValidationError)
async def validation_exception_handler(
    request: Request,
    exc: RequestValidationError,
) -> JSONResponse:
    """Handle Pydantic validation errors with consistent format."""
    errors = []
    for error in exc.errors():
        loc = ".".join(str(x) for x in error["loc"][1:])  # Skip 'body' prefix
        errors.append(
            {
                "field": loc,
                "message": error["msg"],
                "type": error["type"],
            }
        )

    logger.warning(
        "Validation error",
        path=str(request.url.path),
        errors=errors,
    )

    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "success": False,
            "error": "Validation failed",
            "code": "VALIDATION_ERROR",
            "details": errors,
        },
    )


@app.exception_handler(Exception)
async def general_exception_handler(
    request: Request,
    exc: Exception,
) -> JSONResponse:
    """Handle unexpected exceptions."""
    logger.exception(
        "Unhandled exception",
        path=str(request.url.path),
        error=str(exc),
    )

    # Don't expose internal errors in production
    if settings.is_production:
        message = "Internal server error"
    else:
        message = str(exc)

    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "success": False,
            "error": message,
            "code": "INTERNAL_ERROR",
        },
    )


# Mount routers
app.include_router(health_router, prefix="/api/v1")
app.include_router(devices_router, prefix="/api/v1")
app.include_router(ingest_router, prefix="/api/v1")
app.include_router(realtime_router, prefix="/api/v1")


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "app.main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug,
        log_level=settings.log_level.lower(),
    )
