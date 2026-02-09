"""
Realtime WebSocket API routes.

Handles WebSocket connections for live sensor data streaming.
"""

from fastapi import APIRouter, WebSocket, WebSocketDisconnect

from app.api.dependencies import get_ws_manager
from app.config.logging import get_logger

logger = get_logger(__name__)

router = APIRouter(prefix="/stream", tags=["Realtime"])


@router.websocket("/devices/{device_id}")
async def stream_device_readings(
    websocket: WebSocket,
    device_id: str,
) -> None:
    """
    WebSocket endpoint for streaming device readings.

    **Protocol:**

    1. Client connects to /stream/devices/{device_id}
    2. Server sends acknowledgment: {"type": "ack", "message": "..."}
    3. Server pushes readings: {"type": "reading", "device_id": "...", "data": {...}}
    4. Client can send: {"action": "ping"} to keep alive
    5. Server responds: {"type": "pong"}

    **Error handling:**
    - Invalid messages: {"type": "error", "error": "...", "code": "..."}
    - Connection errors cause automatic disconnect

    **Reconnection:**
    - Clients should implement exponential backoff
    - State is not preserved between connections
    """
    manager = get_ws_manager()

    # Accept connection
    await manager.connect(websocket)

    try:
        # Subscribe to device updates
        await manager.subscribe(websocket, device_id)
        await manager.send_ack(
            websocket,
            f"Subscribed to device: {device_id}",
        )

        logger.info(
            "WebSocket subscribed to device stream",
            device_id=device_id,
        )

        # Handle incoming messages
        while True:
            try:
                data = await websocket.receive_json()
                action = data.get("action")

                if action == "ping":
                    await websocket.send_json({"type": "pong"})

                elif action == "subscribe":
                    # Subscribe to additional device
                    new_device_id = data.get("device_id")
                    if new_device_id:
                        await manager.subscribe(websocket, new_device_id)
                        await manager.send_ack(
                            websocket,
                            f"Subscribed to device: {new_device_id}",
                        )

                elif action == "unsubscribe":
                    # Unsubscribe from device
                    unsub_device_id = data.get("device_id")
                    if unsub_device_id:
                        await manager.unsubscribe(websocket, unsub_device_id)
                        await manager.send_ack(
                            websocket,
                            f"Unsubscribed from device: {unsub_device_id}",
                        )

                else:
                    await manager.send_error(
                        websocket,
                        f"Unknown action: {action}",
                        "UNKNOWN_ACTION",
                    )

            except ValueError:
                await manager.send_error(
                    websocket,
                    "Invalid JSON message",
                    "INVALID_JSON",
                )

    except WebSocketDisconnect:
        logger.info("WebSocket client disconnected", device_id=device_id)

    finally:
        await manager.disconnect(websocket)


@router.websocket("/all")
async def stream_all_devices(websocket: WebSocket) -> None:
    """
    WebSocket endpoint for streaming all device readings.

    Broadcasts readings from all devices. Use for dashboard views.

    **Note:** For high-frequency data, prefer subscribing to specific devices.
    """
    manager = get_ws_manager()

    await manager.connect(websocket)

    try:
        # Special subscription key for all devices
        await manager.subscribe(websocket, "__all__")
        await manager.send_ack(websocket, "Subscribed to all devices")

        logger.info("WebSocket subscribed to all devices stream")

        while True:
            try:
                data = await websocket.receive_json()
                action = data.get("action")

                if action == "ping":
                    await websocket.send_json({"type": "pong"})
                else:
                    await manager.send_error(
                        websocket,
                        f"Unknown action: {action}",
                        "UNKNOWN_ACTION",
                    )

            except ValueError:
                await manager.send_error(
                    websocket,
                    "Invalid JSON message",
                    "INVALID_JSON",
                )

    except WebSocketDisconnect:
        logger.info("WebSocket client disconnected from all devices stream")

    finally:
        await manager.disconnect(websocket)
