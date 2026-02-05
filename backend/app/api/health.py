"""
Health check and system info routes.
"""

from datetime import datetime

from fastapi import APIRouter

from app.api.dependencies import WebSocketManagerDep
from app.api.dto import ResponseEnvelope

router = APIRouter(tags=["Health"])


@router.get(
    "/health",
    response_model=ResponseEnvelope[dict],
    summary="Health check",
    description="Check if the API is running and healthy.",
)
async def health_check(
    ws_manager: WebSocketManagerDep,
) -> ResponseEnvelope[dict]:
    """Basic health check endpoint."""
    return ResponseEnvelope(
        success=True,
        data={
            "status": "healthy",
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "websocket_connections": ws_manager.connection_count,
        },
    )


@router.get(
    "/",
    response_model=ResponseEnvelope[dict],
    summary="API info",
    description="Get API version and basic information.",
    include_in_schema=False,
)
async def api_info() -> ResponseEnvelope[dict]:
    """API root with version info."""
    return ResponseEnvelope(
        success=True,
        data={
            "name": "Telemetry API",
            "version": "1.0.0",
            "docs": "/docs",
            "openapi": "/openapi.json",
        },
    )
