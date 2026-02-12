# ESP32 BLE Provisioning - Quick Reference

## 🚀 Quick Start

### 1. Add Device Flow
```
Main App → Devices Page → [+] FAB → Onboarding → Device Discovery
```

### 2. Provider Access
```dart
// Get provisioning state
final state = ref.watch(esp32ProvisioningProvider);

// Trigger actions
final notifier = ref.read(esp32ProvisioningProvider.notifier);
await notifier.startDeviceScan();
await notifier.connectToDevice(device);
await notifier.establishSecureSession(proofOfPossession: 'abcd1234');
await notifier.scanWiFiNetworks();
await notifier.provisionWiFi(credentials);
```

### 3. State Phases
```dart
enum ProvisioningPhase {
  idle,                    // Ready for action
  scanningDevices,         // BLE scan active
  connecting,              // Connecting to device
  establishingSession,     // Security handshake
  scanningWiFi,           // Querying networks
  sendingCredentials,     // Sending SSID/password
  applyingConfig,         // Device configuring
  verifying,              // Checking status
  success,                // ✅ Complete
  failure,                // ❌ Error
}
```

## 🔍 Debug Checklist

### UI Not Updating?
```dart
// Check state is changing
print(state.phase); // Should transition through phases
print(state.discoveredDevices.length); // Should increase during scan
```

### No Devices Found?
```bash
# Check logs for:
🔍 Starting BLE scan
✅ Device discovered: ...

# Verify:
- Bluetooth enabled
- Location permission granted (Android)
- ESP32 powered on and advertising
- Within BLE range (~10m)
```

### Connection Fails?
```bash
# Check logs for:
🔌 Connecting to device: ...
❌ Connection error: ...

# Verify:
- Device not already connected
- Correct service UUID
- GATT services available
```

### Secure Session Fails?
```bash
# Check logs for:
🔐 Establishing secure session
❌ Secure session failed: ...

# Verify:
- Correct PoP entered
- ESP32 has matching PoP configured
- SRP implementation matches ESP-IDF
```

## 📝 Common Patterns

### Listen to State Changes
```dart
ref.listen(esp32ProvisioningProvider, (previous, next) {
  if (next.phase == ProvisioningPhase.success) {
    // Handle success
  }
  if (next.hasError) {
    // Show error: next.error!.userMessage
  }
});
```

### Complete Flow
```dart
// Scan
await notifier.startDeviceScan(timeout: Duration(seconds: 15));

// Select first device
final device = state.discoveredDevices.first;

// Connect
await notifier.connectToDevice(device);
if (state.hasError) return;

// Secure session
await notifier.establishSecureSession(proofOfPossession: 'yourPop');
if (state.hasError) return;

// Scan WiFi
await notifier.scanWiFiNetworks();
if (state.hasError) return;

// Provision
final creds = WiFiCredentials(ssid: 'MyNetwork', password: 'password123');
await notifier.provisionWiFi(creds);

// Check result
if (state.phase == ProvisioningPhase.success) {
  print('✅ Success!');
}
```

### Error Handling
```dart
try {
  await notifier.provisionWiFi(credentials);
} catch (e) {
  // Error already in state
  final error = state.error;
  if (error != null) {
    print('Error: ${error.userMessage}');
    print('Recoverable: ${error.isRecoverable}');
  }
}
```

## 🔧 Configuration

### Change Timeouts
```dart
// In provisioning_config.dart
static const ProvisioningConfig myConfig = ProvisioningConfig(
  connectionTimeout: Duration(seconds: 45), // BLE connection
  operationTimeout: Duration(seconds: 15),  // Individual operations
  scanTimeout: Duration(seconds: 20),       // WiFi scan
  maxRetries: 5,                            // Status polls
  // ...
);

// Use custom config
final configProvider = Provider<ProvisioningConfig>((ref) => myConfig);
```

### Change Service UUID
```dart
// If your ESP32 uses different UUID
bleServiceUuid: '12345678-1234-1234-1234-123456789abc',
```

## 🧪 Testing Without ESP32

### Mock Repository
```dart
class MockProvisioningRepository implements ProvisioningRepository {
  @override
  Stream<ProvisioningDevice> scanForDevices({Duration? timeout}) async* {
    await Future.delayed(Duration(seconds: 2));
    yield ProvisioningDevice(
      id: 'mock_device',
      name: 'Mock ESP32',
      rssi: -45,
      transportType: TransportType.ble,
    );
  }
  
  // ... implement other methods
}

// Override in tests
final mockRepoProvider = Provider<ProvisioningRepository>((ref) {
  return MockProvisioningRepository();
});
```

## 📊 Log Analysis

### Successful Flow
```
🔍 Starting device scan
✅ Device discovered: ESP32_001 (AA:BB:CC:DD:EE:FF) - RSSI: -45dBm
🔌 Connecting to device: ESP32_001
✅ Connected successfully to ESP32_001
🔐 Establishing secure session with PoP
✅ Secure session established
📡 Scanning Wi-Fi networks
✅ Found 5 Wi-Fi networks
  - HomeNetwork (RSSI: -35dBm, auth: wpa2Psk)
  - OfficeWiFi (RSSI: -52dBm, auth: wpa2Psk)
📶 Provisioning Wi-Fi: HomeNetwork
📶 Sending credentials...
✓ Verifying provisioning...
✅ Provisioning completed successfully
```

### Failed Connection
```
🔍 Starting device scan
✅ Device discovered: ESP32_001 (AA:BB:CC:DD:EE:FF) - RSSI: -45dBm
🔌 Connecting to device: ESP32_001
❌ Connection failed: Provisioning service not found
```

### Wrong PoP
```
🔐 Establishing secure session with PoP
❌ Secure session failed: Server proof verification failed
```

## 🎨 UI Indicators

### Show Phase to User
```dart
String getPhaseMessage(ProvisioningPhase phase) {
  switch (phase) {
    case ProvisioningPhase.idle:
      return 'Ready';
    case ProvisioningPhase.scanningDevices:
      return 'Scanning for devices...';
    case ProvisioningPhase.connecting:
      return 'Connecting to device...';
    case ProvisioningPhase.establishingSession:
      return 'Securing connection...';
    case ProvisioningPhase.scanningWiFi:
      return 'Scanning Wi-Fi networks...';
    case ProvisioningPhase.sendingCredentials:
      return 'Sending credentials...';
    case ProvisioningPhase.applyingConfig:
      return 'Configuring device...';
    case ProvisioningPhase.verifying:
      return 'Verifying connection...';
    case ProvisioningPhase.success:
      return 'Provisioning complete!';
    case ProvisioningPhase.failure:
      return 'Provisioning failed';
  }
}
```

### Progress Indicator
```dart
double getProgress(ProvisioningPhase phase) {
  switch (phase) {
    case ProvisioningPhase.idle: return 0.0;
    case ProvisioningPhase.scanningDevices: return 0.1;
    case ProvisioningPhase.connecting: return 0.2;
    case ProvisioningPhase.establishingSession: return 0.4;
    case ProvisioningPhase.scanningWiFi: return 0.6;
    case ProvisioningPhase.sendingCredentials: return 0.7;
    case ProvisioningPhase.applyingConfig: return 0.8;
    case ProvisioningPhase.verifying: return 0.9;
    case ProvisioningPhase.success: return 1.0;
    case ProvisioningPhase.failure: return 1.0;
  }
}
```

## 🔗 Key Files

| Component | File |
|-----------|------|
| State Management | `presentation/state/provisioning_state.dart` |
| BLE Transport | `data/transports/ble_transport.dart` |
| Protocol | `data/protocol/provisioning_protocol.dart` |
| Repository | `data/repositories/provisioning_repository_impl.dart` |
| Config | `core/config/provisioning_config.dart` |
| Errors | `core/errors/provisioning_errors.dart` |
| SRP Crypto | `core/crypto/srp_client.dart` |
| AES Crypto | `core/crypto/aes_encryption.dart` |

## 📖 Full Documentation

See `PROVISIONING.md` for complete implementation details.

