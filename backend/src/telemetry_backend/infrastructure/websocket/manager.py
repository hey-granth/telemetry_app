"""
WebSocket connection manager.

Handles WebSocket connections, subscriptions, and fan-out broadcasting.
"""

import asyncio
from typing import Any

from fastapi import WebSocket
from starlette.websockets import WebSocketState

from telemetry_backend.config.logging import get_logger

logger = get_logger(__name__)


class WebSocketManager:
    """
    Manager for WebSocket connections and message broadcasting.

    Handles:
    - Connection lifecycle (connect/disconnect)
    - Device-specific subscriptions
    - Efficient fan-out broadcasting
    - Graceful error handling
    """

    def __init__(self) -> None:
        """Initialize WebSocket manager."""
        # Map of device_id -> set of WebSocket connections
        self._device_subscribers: dict[str, set[WebSocket]] = {}
        # Map of WebSocket -> set of subscribed device_ids
        self._connection_subscriptions: dict[WebSocket, set[str]] = {}
        # Lock for thread-safe operations
        self._lock = asyncio.Lock()

    @property
    def connection_count(self) -> int:
        """Get total number of active connections."""
        return len(self._connection_subscriptions)

    @property
    def subscription_count(self) -> int:
        """Get total number of device subscriptions."""
        return sum(len(subs) for subs in self._device_subscribers.values())

    async def connect(self, websocket: WebSocket) -> None:
        """
        Accept a new WebSocket connection.

        Args:
            websocket: WebSocket connection to accept.
        """
        await websocket.accept()

        async with self._lock:
            self._connection_subscriptions[websocket] = set()

        logger.info(
            "WebSocket connected",
            connections=self.connection_count,
        )

    async def disconnect(self, websocket: WebSocket) -> None:
        """
        Handle WebSocket disconnection.

        Cleans up all subscriptions for this connection.

        Args:
            websocket: WebSocket connection that disconnected.
        """
        async with self._lock:
            # Get all subscribed device IDs
            subscribed_devices = self._connection_subscriptions.pop(websocket, set())

            # Remove from each device's subscriber set
            for device_id in subscribed_devices:
                if device_id in self._device_subscribers:
                    self._device_subscribers[device_id].discard(websocket)
                    # Clean up empty sets
                    if not self._device_subscribers[device_id]:
                        del self._device_subscribers[device_id]

        logger.info(
            "WebSocket disconnected",
            connections=self.connection_count,
            unsubscribed_devices=len(subscribed_devices),
        )

    async def subscribe(self, websocket: WebSocket, device_id: str) -> None:
        """
        Subscribe a connection to a device's updates.

        Args:
            websocket: WebSocket connection.
            device_id: Device to subscribe to.
        """
        async with self._lock:
            # Add to device subscribers
            if device_id not in self._device_subscribers:
                self._device_subscribers[device_id] = set()
            self._device_subscribers[device_id].add(websocket)

            # Track subscription for this connection
            if websocket in self._connection_subscriptions:
                self._connection_subscriptions[websocket].add(device_id)

        logger.debug(
            "WebSocket subscribed to device",
            device_id=device_id,
            subscriber_count=len(self._device_subscribers.get(device_id, set())),
        )

    async def unsubscribe(self, websocket: WebSocket, device_id: str) -> None:
        """
        Unsubscribe a connection from a device's updates.

        Args:
            websocket: WebSocket connection.
            device_id: Device to unsubscribe from.
        """
        async with self._lock:
            if device_id in self._device_subscribers:
                self._device_subscribers[device_id].discard(websocket)
                if not self._device_subscribers[device_id]:
                    del self._device_subscribers[device_id]

            if websocket in self._connection_subscriptions:
                self._connection_subscriptions[websocket].discard(device_id)

        logger.debug("WebSocket unsubscribed from device", device_id=device_id)

    async def broadcast_to_device(self, device_id: str, message: dict[str, Any]) -> None:
        """
        Broadcast a message to all subscribers of a device.

        Args:
            device_id: Device to broadcast for.
            message: Message payload to send.
        """
        async with self._lock:
            subscribers = self._device_subscribers.get(device_id, set()).copy()

        if not subscribers:
            return

        # Send to all subscribers concurrently
        disconnected: list[WebSocket] = []

        async def send_to_subscriber(ws: WebSocket) -> None:
            try:
                if ws.client_state == WebSocketState.CONNECTED:
                    await ws.send_json(
                        {
                            "type": "reading",
                            "device_id": device_id,
                            "data": message,
                        }
                    )
            except Exception as e:
                logger.warning(
                    "Failed to send to WebSocket subscriber",
                    error=str(e),
                    device_id=device_id,
                )
                disconnected.append(ws)

        await asyncio.gather(*[send_to_subscriber(ws) for ws in subscribers])

        # Clean up disconnected clients
        for ws in disconnected:
            await self.disconnect(ws)

        logger.debug(
            "Broadcast to device subscribers",
            device_id=device_id,
            subscriber_count=len(subscribers),
            failed=len(disconnected),
        )

    async def send_error(self, websocket: WebSocket, error: str, code: str) -> None:
        """
        Send an error message to a WebSocket connection.

        Args:
            websocket: WebSocket connection.
            error: Error message.
            code: Error code.
        """
        try:
            if websocket.client_state == WebSocketState.CONNECTED:
                await websocket.send_json(
                    {
                        "type": "error",
                        "error": error,
                        "code": code,
                    }
                )
        except Exception as e:
            logger.warning("Failed to send error to WebSocket", error=str(e))

    async def send_ack(self, websocket: WebSocket, message: str) -> None:
        """
        Send an acknowledgment message.

        Args:
            websocket: WebSocket connection.
            message: Acknowledgment message.
        """
        try:
            if websocket.client_state == WebSocketState.CONNECTED:
                await websocket.send_json(
                    {
                        "type": "ack",
                        "message": message,
                    }
                )
        except Exception as e:
            logger.warning("Failed to send ack to WebSocket", error=str(e))
