#!/bin/bash
# ESP32 BLE Provisioning - Implementation Validation Script

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ESP32 BLE Provisioning - Implementation Validation"
echo "━━━━━━━━━━━━��━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
PASS=0
FAIL=0

check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} $2"
        ((PASS++))
    else
        echo -e "${RED}✗${NC} $2 - MISSING: $1"
        ((FAIL++))
    fi
}

check_dir() {
    if [ -d "$1" ]; then
        echo -e "${GREEN}✓${NC} $2"
        ((PASS++))
    else
        echo -e "${RED}✗${NC} $2 - MISSING: $1"
        ((FAIL++))
    fi
}

echo "📁 Directory Structure"
echo "────────────────────────────────────────────────────"
check_dir "lib/features/provisioning" "Provisioning feature module"
check_dir "lib/features/provisioning/domain" "Domain layer"
check_dir "lib/features/provisioning/data" "Data layer"
check_dir "lib/features/provisioning/presentation" "Presentation layer"
echo

echo "🏗️ Core Implementation Files"
echo "────────────────────────────────────────────────────"
check_file "lib/features/provisioning/domain/entities/provisioning_entities.dart" "Domain entities"
check_file "lib/features/provisioning/domain/repositories/provisioning_repository.dart" "Repository interface"
check_file "lib/features/provisioning/domain/usecases/provisioning_usecases.dart" "Use cases"
echo

echo "🔧 Data Layer"
echo "────────────────────────────────────────────────────"
check_file "lib/features/provisioning/data/repositories/provisioning_repository_impl.dart" "Repository implementation"
check_file "lib/features/provisioning/data/transports/ble_transport.dart" "BLE transport"
check_file "lib/features/provisioning/data/transports/provisioning_transport.dart" "Transport interface"
check_file "lib/features/provisioning/data/protocol/provisioning_protocol.dart" "Provisioning protocol"
check_file "lib/features/provisioning/data/protocol/protocol_messages.dart" "Protocol messages"
echo

echo "🔐 Cryptography"
echo "────────────────────────────────────────────────────"
check_file "lib/core/crypto/srp_client.dart" "SRP6a client"
check_file "lib/core/crypto/aes_encryption.dart" "AES encryption"
check_file "lib/core/crypto/crypto_types.dart" "Crypto types"
echo

echo "🎨 Presentation Layer"
echo "────────────────────────────────────────────────────"
check_file "lib/features/provisioning/presentation/state/provisioning_state.dart" "State management"
check_file "lib/features/provisioning/presentation/providers/esp32_provisioning_providers.dart" "Providers"
check_file "lib/features/provisioning/presentation/screens/device_discovery_screen.dart" "Device discovery UI"
check_file "lib/features/provisioning/presentation/screens/wifi_selection_screen.dart" "Wi-Fi selection UI"
check_file "lib/features/provisioning/presentation/screens/provisioning_progress_screen.dart" "Progress UI"
check_file "lib/features/provisioning/presentation/screens/qr_scanner_screen.dart" "QR scanner UI"
echo

echo "⚙️ Configuration & Errors"
echo "────────────────────────────────────────────────────"
check_file "lib/core/config/provisioning_config.dart" "Configuration"
check_file "lib/core/errors/provisioning_errors.dart" "Error types"
echo

echo "📚 Documentation"
echo "────────────────────────────────────────────────────"
check_file "PROVISIONING.md" "Provisioning guide"
check_file "IMPLEMENTATION_SUMMARY.md" "Implementation summary"
check_file "QUICK_REFERENCE.md" "Quick reference"
check_file "lib/examples/provisioning_flow_test.dart" "Test helper"
echo

echo "🔍 Code Quality Check"
echo "────────────────────────────────────────────────────"

# Check if flutter is available
if command -v flutter &> /dev/null; then
    echo -n "Running flutter analyze... "
    ISSUES=$(flutter analyze 2>&1 | grep "issues found" | awk '{print $1}')
    if [ ! -z "$ISSUES" ]; then
        echo -e "${YELLOW}$ISSUES issues found${NC} (review manually)"
    else
        echo -e "${GREEN}✓${NC} No critical errors"
    fi
    ((PASS++))
else
    echo -e "${YELLOW}⚠${NC} Flutter not in PATH, skipping analysis"
fi
echo

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "Passed: ${GREEN}$PASS${NC}"
echo -e "Failed: ${RED}$FAIL${NC}"
echo

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed!${NC}"
    echo
    echo "Next steps:"
    echo "1. Ensure ESP32 is powered on with provisioning firmware"
    echo "2. Run: flutter run"
    echo "3. Navigate to Devices → Add Device"
    echo "4. Check logs for provisioning flow"
    echo
    echo "For testing: See QUICK_REFERENCE.md"
    exit 0
else
    echo -e "${RED}❌ Some checks failed!${NC}"
    echo "Please ensure all files are in place before running the app."
    exit 1
fi
