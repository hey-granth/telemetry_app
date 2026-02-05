# ESP32 Integration Protocol

This document describes the HTTP and WebSocket protocols for ESP32 devices to communicate with the telemetry backend.

## Overview

ESP32 devices communicate with the backend using:
1. **HTTP POST** for sending sensor readings
2. **WebSocket** for receiving real-time configuration updates (optional)

## Authentication

All requests must include an API key in the request header:

```
X-API-Key: <device-api-key>
```

API keys are provisioned per-device during registration.

## Endpoints

### Base URL
```
Production: https://api.your-domain.com
Development: http://localhost:8000
```

### Ingest Sensor Reading

**Endpoint:** `POST /api/v1/ingest`

**Headers:**
```
Content-Type: application/json
X-API-Key: <device-api-key>
```

**Request Body:**
```json
{
  "device_id": "esp32-001",
  "temperature": 25.5,
  "humidity": 60.0,
  "voltage": 3.3,
  "timestamp": "2024-01-15T10:30:00Z"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `device_id` | string | Yes | Unique device identifier (max 64 chars) |
| `temperature` | float | Yes | Temperature in Celsius (-100 to 150) |
| `humidity` | float | Yes | Relative humidity percentage (0 to 100) |
| `voltage` | float | Yes | Supply voltage in Volts (0 to 50) |
| `timestamp` | string | No | ISO 8601 UTC timestamp. Server assigns if omitted |

**Response (201 Created):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "device_id": "esp32-001",
  "timestamp": "2024-01-15T10:30:00Z",
  "accepted": true
}
```

**Error Response (4xx/5xx):**
```json
{
  "error": "validation_error",
  "message": "temperature must be between -100 and 150",
  "code": "INVALID_TEMPERATURE"
}
```

### Health Check

**Endpoint:** `GET /health`

Use this endpoint to verify backend connectivity.

**Response (200 OK):**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

## WebSocket Connection (Optional)

Connect to receive real-time updates and configuration changes.

**Endpoint:** `ws://localhost:8000/stream/{device_id}`

**Query Parameters:**
- `token`: Device authentication token

**Example:**
```
ws://localhost:8000/stream/esp32-001?token=<api-key>
```

### Message Types

**Incoming (Server → Device):**
```json
{
  "type": "config_update",
  "payload": {
    "sample_interval_ms": 5000,
    "report_interval_ms": 30000
  }
}
```

```json
{
  "type": "command",
  "payload": {
    "action": "restart",
    "delay_ms": 1000
  }
}
```

## Arduino/ESP32 Example

```cpp
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

const char* WIFI_SSID = "your-ssid";
const char* WIFI_PASS = "your-password";
const char* API_URL = "http://192.168.1.100:8000/api/v1/ingest";
const char* API_KEY = "your-device-api-key";
const char* DEVICE_ID = "esp32-001";

void sendReading(float temperature, float humidity, float voltage) {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi not connected");
    return;
  }

  HTTPClient http;
  http.begin(API_URL);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("X-API-Key", API_KEY);

  StaticJsonDocument<256> doc;
  doc["device_id"] = DEVICE_ID;
  doc["temperature"] = temperature;
  doc["humidity"] = humidity;
  doc["voltage"] = voltage;

  String payload;
  serializeJson(doc, payload);

  int httpCode = http.POST(payload);

  if (httpCode == 201) {
    Serial.println("Reading sent successfully");
    String response = http.getString();
    Serial.println(response);
  } else {
    Serial.printf("Error: HTTP %d\n", httpCode);
    Serial.println(http.getString());
  }

  http.end();
}

void setup() {
  Serial.begin(115200);
  
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi connected");
}

void loop() {
  // Read sensors (replace with actual sensor readings)
  float temperature = 25.5;
  float humidity = 60.0;
  float voltage = 3.3;

  sendReading(temperature, humidity, voltage);

  delay(30000); // Send every 30 seconds
}
```

## Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `INVALID_API_KEY` | 401 | API key is missing or invalid |
| `UNKNOWN_DEVICE` | 404 | Device ID not registered |
| `INVALID_PAYLOAD` | 422 | Request body validation failed |
| `INVALID_TEMPERATURE` | 422 | Temperature out of valid range |
| `INVALID_HUMIDITY` | 422 | Humidity out of valid range |
| `INVALID_VOLTAGE` | 422 | Voltage out of valid range |
| `RATE_LIMITED` | 429 | Too many requests |
| `SERVER_ERROR` | 500 | Internal server error |

## Best Practices

1. **Retry Logic**: Implement exponential backoff for failed requests
2. **Buffering**: Store readings locally if network is unavailable
3. **Timestamps**: Let server assign timestamps unless device has accurate RTC
4. **Connection Pooling**: Reuse HTTP connections when possible
5. **TLS**: Use HTTPS in production for secure communication
6. **Rate Limiting**: Don't send more than 1 reading per second per device

## Device Registration

Devices must be registered before sending data. Contact the platform administrator to:
1. Register your device ID
2. Obtain an API key
3. Configure device metadata (name, location, etc.)

Future versions will support self-registration via a provisioning endpoint.
