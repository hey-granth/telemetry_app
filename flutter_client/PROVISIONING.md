# ESP32 BLE Provisioning - Implementation Guide

## Overview

This Flutter app implements **ESP32 BLE provisioning** using the ESP-IDF provisioning protocol with Security 2 (SRP6a).

## Architecture

```
┌──────────────────────────┐
│   UI Layer               │
│  (Screens/Widgets)       │
└────────────┬─────────────┘
             │
┌────────────▼─────────────┐
│  State Management        │
│  (Riverpod Providers)    │
└────────────┬─────────────┘
             │
┌────────────▼─────────────┐
│  Use Cases               │
│  (Business Logic)        │
└────────────┬─────────────┘
             │
┌────────────▼─────────────┐
│  Repository              │
│  (Data Access)           │
└─────┬──────────────┬─────┘
      │              │
┌─────▼──────┐  ┌────▼──────┐
│ Protocol   │  │ Transport │
│ (Security2)│  │  (BLE)    │
└────────────┘  └───────────┘
```

## State Machine

```
idle
  ↓
scanningDevices → [device_discovered]
  ↓
connecting → [device_connected]
  ↓
establishingSession → [session_established]
  ↓
scanningWiFi → [wifi_list_received]
  ↓
sendingCredentials
  ↓
applyingConfig
  ↓
verifying
  ↓
success | failure
```

## User Flow

1. **Onboarding** (`/onboarding`)
   - Checks BLE & Location permissions
   - Redirects to Device Discovery

2. **Device Discovery** (`DeviceDiscoveryScreen`)
   - Scans for ESP32 devices advertising provisioning service
   - Filters by service UUID: `0000ffff-0000-1000-8000-00805f9b34fb`
   - Displays discovered devices with signal strength
   - User taps device → prompts for Proof-of-Possession (PoP)

3. **Connection & Security**
   - Connects to selected BLE device
   - Discovers GATT services and characteristics
   - Establishes Security 2 session using SRP6a
   - Derives session key for encryption

4. **Wi-Fi Selection** (`WiFiSelectionScreen`)
   - Scans for Wi-Fi networks via ESP32
   - Displays SSID, signal strength, security type
   - User selects network and enters password

5. **Provisioning** (`ProvisioningProgressScreen`)
   - Sends encrypted credentials to ESP32
   - Applies configuration
   - Polls for connection status
   - Shows success/failure

## Key Components

### BLE Transport (`BleTransport`)

- **Service UUID**: `0000ffff-0000-1000-8000-00805f9b34fb`
- **Session Characteristic**: `0000ff51-0000-1000-8000-00805f9b34fb` (notify)
- **Config Characteristic**: `0000ff52-0000-1000-8000-00805f9b34fb` (write)

Responsibilities:
- Connect to BLE device
- Subscribe to notifications
- Send/receive data
- Handle disconnection

### Provisioning Protocol (`ProvisioningProtocol`)

Implements ESP-IDF provisioning protocol:

1. **Session Establishment** (Security 2)
   - SRP6a key exchange
   - Derive session key
   - Verify server proof

2. **Wi-Fi Scan**
   - Request network scan
   - Parse encrypted results

3. **Credential Submission**
   - Encrypt SSID and password
   - Send to device
   - Apply configuration

4. **Status Polling**
   - Query provisioning status
   - Detect success/failure

### Security Implementation

**SRP6a** (`SrpClient`)
- 3072-bit prime group (RFC 5054)
- Username: `espressif`
- Password: Proof-of-Possession from QR code or user input

**AES-256-CTR** (`AesEncryption`)
- Encrypts all provisioning data after session establishment
- Random IV per message
- Session key derived from SRP

### State Management (`ProvisioningNotifier`)

Uses Riverpod `StateNotifier` to manage:
- Current provisioning phase
- Discovered devices
- Available Wi-Fi networks
- Progress tracking
- Error handling

## Configuration

### BLE Service Discovery

Edit `lib/core/config/provisioning_config.dart`:

```dart
static const ProvisioningConfig defaultConfig = ProvisioningConfig(
  bleServiceUuid: '0000ffff-0000-1000-8000-00805f9b34fb',
  sessionCharUuid: '0000ff51-0000-1000-8000-00805f9b34fb',
  configCharUuid: '0000ff52-0000-1000-8000-00805f9b34fb',
  // ... endpoints and timeouts
);
```

### Permissions

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Required for ESP32 device provisioning</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Required for BLE device scanning</string>
```

## Testing

### Manual Test

Use the test helper:

```dart
import 'package:telemetry_client/examples/provisioning_flow_test.dart';

// In a widget with WidgetRef:
final test = ProvisioningFlowTest(ref: ref);
await test.runTest();
```

### Debug Logging

All provisioning operations log with emoji prefixes:
- 🔍 Scanning
- 🔌 Connection
- 🔐 Security
- 📡 Wi-Fi operations
- ✅ Success
- ❌ Errors

Check console for detailed flow trace.

## Troubleshooting

### No devices found

**Check:**
- ESP32 is powered on
- Device is in provisioning mode (not already provisioned)
- Bluetooth is enabled on phone
- Location permission granted (Android)
- Within BLE range (~10 meters)
- ESP32 is advertising correct service UUID

**Debug:**
```dart
ref.read(esp32ProvisioningProvider.notifier).startDeviceScan(
  timeout: Duration(seconds: 30)
);
```

Check logs for:
- `🔍 Starting BLE scan`
- `✅ Device discovered: ...`

### Connection fails

**Check:**
- Device not already connected to another phone
- BLE connection timeout (default 30s)
- GATT services exist

**Debug:**
Enable verbose logging in `ProvisioningRepositoryImpl`.

### Secure session fails

**Check:**
- Correct Proof-of-Possession entered
- ESP32 has matching PoP configured
- SRP implementation matches ESP-IDF

**Common issue:** Wrong PoP → authentication fails

### Wi-Fi scan returns nothing

**Check:**
- Secure session established successfully
- ESP32 Wi-Fi radio active
- Device within range of Wi-Fi networks

### Provisioning fails

**Check:**
- Correct Wi-Fi password
- Network supports ESP32 (2.4GHz, not 5GHz)
- Security type matches (WPA2/WPA3)
- DHCP available

## Protocol Messages

### Session Request
```
[endpoint_length][prov-session][payload_length][client_public_key][client_proof]
```

### Wi-Fi Scan Request
```
[endpoint_length][prov-scan][payload_length][0x00]
```

### Wi-Fi Config Request
```
[endpoint_length][prov-config][payload_length][encrypted_payload]
  ├── [ssid_length][ssid]
  └── [password_length][password]
```

### Apply Config
```
[endpoint_length][prov-apply][payload_length][0x01]
```

All payloads after session establishment are AES-256-CTR encrypted.

## ESP32 Firmware Requirements

Your ESP32 must:
- Advertise BLE service UUID: `0000ffff-0000-1000-8000-00805f9b34fb`
- Implement ESP-IDF provisioning manager
- Support Security 2 (SRP6a)
- Expose session and config characteristics
- Handle encrypted Wi-Fi credentials

See ESP-IDF provisioning examples:
https://github.com/espressif/esp-idf/tree/master/examples/provisioning

## Future Enhancements

- [ ] QR code scanning for PoP
- [ ] SoftAP transport (alternative to BLE)
- [ ] Custom data endpoint usage
- [ ] Persistent device storage
- [ ] Multi-device provisioning
- [ ] Background provisioning service
- [ ] Provision retry logic
- [ ] Network signal strength monitoring

## Resources

- [ESP-IDF Provisioning](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/provisioning/provisioning.html)
- [SRP Protocol](https://tools.ietf.org/html/rfc5054)
- [flutter_blue_plus](https://pub.dev/packages/flutter_blue_plus)

