# ESP32 Hardware Testing Checklist

Use this checklist when testing with a real ESP32 device.

## 📋 Pre-Testing Setup

### ESP32 Firmware Requirements
- [ ] ESP-IDF provisioning manager configured
- [ ] BLE advertising enabled
- [ ] Service UUID: `0000ffff-0000-1000-8000-00805f9b34fb`
- [ ] Session characteristic: `0000ff51-0000-1000-8000-00805f9b34fb`
- [ ] Config characteristic: `0000ff52-0000-1000-8000-00805f9b34fb`
- [ ] Security 2 (SRP6a) enabled
- [ ] Proof-of-Possession (PoP) set
- [ ] Device name visible (e.g., "PROV_ESP32" or "ESP32_XXX")

### Mobile Device Setup
- [ ] Bluetooth enabled
- [ ] Location services enabled (Android)
- [ ] App installed: `flutter run`
- [ ] Permissions granted:
  - [ ] Bluetooth Scan
  - [ ] Bluetooth Connect
  - [ ] Location (Android)

### Environment
- [ ] ESP32 powered on
- [ ] Within 10 meters range
- [ ] No BLE interference
- [ ] Wi-Fi network available for provisioning

## 🧪 Testing Procedure

### Phase 1: Device Discovery
- [ ] Launch app
- [ ] Navigate: Devices → [+] FAB → Add Device
- [ ] Permission dialog appears → Grant permissions
- [ ] **CHECKPOINT**: Device discovery screen loads
- [ ] **CHECKPOINT**: "Scanning for ESP32 devices..." message visible
- [ ] **VERIFY LOGS**:
  ```
  🔍 Starting device scan
  🔍 Calling scanForDevicesUseCase...
  ```
- [ ] Wait 5-15 seconds
- [ ] **CHECKPOINT**: ESP32 device appears in list
- [ ] **VERIFY LOGS**:
  ```
  ✅ Device discovered: ESP32_XXX (MAC) - RSSI: -XXdBm
  ```
- [ ] Signal strength indicator shows (green/orange/red)
- [ ] Device name matches ESP32

**If no device found**:
- Check ESP32 is advertising
- Verify service UUID matches
- Check BLE is enabled
- Try refresh button

### Phase 2: Connection
- [ ] Tap discovered device
- [ ] PoP dialog appears
- [ ] Enter Proof-of-Possession (from ESP32 config or QR)
- [ ] Tap "Connect"
- [ ] **CHECKPOINT**: "Connecting..." dialog appears
- [ ] **VERIFY LOGS**:
  ```
  🔌 Connecting to device: ESP32_XXX
  🔌 Calling connectToDeviceUseCase...
  ```
- [ ] Connection succeeds
- [ ] **VERIFY LOGS**:
  ```
  ✅ Connected successfully to ESP32_XXX
  ```

**If connection fails**:
- Check ESP32 is still powered on
- Verify GATT services exist
- Check no other device is connected
- Try power cycling ESP32

### Phase 3: Secure Session
- [ ] Automatic after connection
- [ ] **VERIFY LOGS**:
  ```
  🔐 Establishing secure session with PoP
  🔐 Calling establishSecureSessionUseCase...
  ```
- [ ] Session establishes
- [ ] **VERIFY LOGS**:
  ```
  ✅ Secure session established
  ```
- [ ] **CHECKPOINT**: Navigates to Wi-Fi selection screen

**If session fails**:
- Verify PoP is correct
- Check ESP32 SRP configuration
- Check ESP32 logs for authentication errors

### Phase 4: Wi-Fi Scanning
- [ ] Wi-Fi selection screen loads
- [ ] **CHECKPOINT**: "Scanning networks..." message
- [ ] **VERIFY LOGS**:
  ```
  📡 Scanning Wi-Fi networks
  📡 Calling scanWiFiNetworksUseCase...
  ```
- [ ] Networks populate in list
- [ ] **VERIFY LOGS**:
  ```
  ✅ Found X Wi-Fi networks
    - NetworkName (RSSIdBm, authMode)
  ```
- [ ] **CHECKPOINT**: Network list shows:
  - SSID names
  - Signal strength bars
  - Security badges (WPA2/WPA3/Open)
  - Channel numbers

**If no networks found**:
- Check ESP32 Wi-Fi radio is active
- Verify ESP32 is in range of Wi-Fi
- Check ESP32 logs

### Phase 5: Credential Submission
- [ ] Select target Wi-Fi network
- [ ] Password field appears (if secured)
- [ ] Enter Wi-Fi password
- [ ] Tap "Connect" or "Provision"
- [ ] **CHECKPOINT**: Provisioning progress screen appears
- [ ] **VERIFY LOGS**:
  ```
  📶 Provisioning Wi-Fi: NetworkName
  📶 Sending credentials...
  ```
- [ ] Progress indicators update:
  - [ ] Sending credentials (70%)
  - [ ] Configuring device (80%)
  - [ ] Verifying (90%)
- [ ] **VERIFY LOGS**:
  ```
  ✓ Verifying provisioning...
  ```

**If submission fails**:
- Check Wi-Fi password is correct
- Verify network supports ESP32 (2.4GHz)
- Check ESP32 logs for connection errors

### Phase 6: Verification
- [ ] Status polling begins
- [ ] ESP32 connects to Wi-Fi
- [ ] **CHECK ESP32**: Should connect to network
- [ ] **VERIFY LOGS**:
  ```
  ✅ Provisioning completed successfully
  ```
- [ ] **CHECKPOINT**: Success screen shows
- [ ] Success message displayed
- [ ] Option to add another device or return

**If verification fails**:
- Check ESP32 logs for Wi-Fi connection status
- Verify DHCP is available
- Check network authentication

### Phase 7: Post-Provisioning
- [ ] BLE connection closes cleanly
- [ ] ESP32 remains on Wi-Fi
- [ ] Can test HTTP connectivity to backend
- [ ] Device appears in Devices list (if registered)

## 📊 Success Metrics

### Complete Success ✅
- Device discovered in <15 seconds
- Connection established in <5 seconds
- Secure session in <3 seconds
- Wi-Fi scan completes in <10 seconds
- Provisioning completes in <20 seconds
- **Total time**: <1 minute

### Partial Success ⚠️
- Device discovered but connection slow
- Multiple connection attempts needed
- Wi-Fi scan timeout
- Provisioning requires retry

### Failure ❌
- Device not discovered
- Connection refused
- Authentication failed
- Wi-Fi connection failed

## 🐛 Common Issues

### Issue: Device not found
**Symptoms**: Empty list after scan  
**Logs**: No "Device discovered" messages  
**Fix**:
1. Check ESP32 is advertising
2. Verify service UUID
3. Check Bluetooth is on
4. Grant location permission (Android)

### Issue: Connection timeout
**Symptoms**: "Connecting..." dialog never closes  
**Logs**: No "Connected successfully" message  
**Fix**:
1. Power cycle ESP32
2. Move closer to device
3. Disconnect other BLE devices
4. Check GATT services available

### Issue: Wrong PoP
**Symptoms**: Secure session fails  
**Logs**: "Server proof verification failed"  
**Fix**:
1. Verify PoP from ESP32 config
2. Check case sensitivity
3. Scan QR code if available
4. Check ESP32 security settings

### Issue: No networks found
**Symptoms**: Empty network list  
**Logs**: "Found 0 networks"  
**Fix**:
1. Check ESP32 Wi-Fi radio
2. Verify ESP32 is in range
3. Check ESP32 scan implementation
4. Review ESP32 logs

### Issue: Wi-Fi connection fails
**Symptoms**: "Provisioning failed" message  
**Logs**: Status check returns failure  
**Fix**:
1. Verify password is correct
2. Check network is 2.4GHz (not 5GHz)
3. Verify WPA2/WPA3 compatibility
4. Check DHCP is available
5. Review ESP32 Wi-Fi logs

## 📝 Log Analysis

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
📶 Provisioning Wi-Fi: HomeNetwork
✅ Provisioning completed successfully
```

### Failed Connection
```
🔍 Starting device scan
✅ Device discovered: ESP32_001
🔌 Connecting to device: ESP32_001
❌ Connection failed: Provisioning service not found
```

### Failed Authentication
```
🔐 Establishing secure session with PoP
❌ Secure session failed: Server proof verification failed
```

### Failed Provisioning
```
📶 Provisioning Wi-Fi: HomeNetwork
❌ Provisioning failed: Wi-Fi authentication failed
```

## 🎯 Expected Results

### Device Discovery
- [ ] At least 1 ESP32 found
- [ ] Correct device name
- [ ] Reasonable RSSI (-90 to -30 dBm)
- [ ] BLE icon/indicator

### Connection
- [ ] Connection < 5 seconds
- [ ] GATT services discovered
- [ ] Characteristics validated
- [ ] Notifications working

### Security
- [ ] SRP handshake completes
- [ ] Session key derived
- [ ] Server proof verified
- [ ] Encryption active

### Wi-Fi
- [ ] Networks found
- [ ] Correct SSIDs
- [ ] Signal strengths accurate
- [ ] Security types correct

### Provisioning
- [ ] Credentials encrypted
- [ ] ESP32 receives data
- [ ] ESP32 connects to Wi-Fi
- [ ] Status confirmed

## ✅ Final Validation

After successful provisioning:

- [ ] ESP32 connected to Wi-Fi
- [ ] ESP32 has IP address
- [ ] Can ping ESP32 (if on same network)
- [ ] ESP32 can reach backend API
- [ ] ESP32 sending telemetry data
- [ ] Device appears in app devices list

## 📞 Support

If issues persist:
1. Check `PROVISIONING.md` for troubleshooting
2. Review ESP32 logs for errors
3. Verify ESP-IDF provisioning example works
4. Compare UUIDs and configuration
5. Test with ESP-IDF provisioning mobile app first

---

**Date**: ________________  
**Tester**: ________________  
**ESP32 Model**: ________________  
**Firmware Version**: ________________  
**Result**: ⬜ Pass  ⬜ Partial  ⬜ Fail

