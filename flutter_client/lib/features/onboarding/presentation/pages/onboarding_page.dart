/// Onboarding page for device discovery and selection.
///
/// Entry point for adding new devices via BLE scanning.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/permission_helper.dart';
import '../../../provisioning/presentation/screens/device_discovery_screen.dart';

/// Onboarding page for device discovery - redirects to ESP32 provisioning
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  bool _hasError = false;
  String? _errorMessage;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Navigate to ESP32 provisioning flow after checking permissions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToProvisioning();
    });
  }

  Future<void> _navigateToProvisioning() async {
    setState(() {
      _isProcessing = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      // Check if we need to request permissions
      if (PermissionHelper.isPermissionHandlingSupported) {
        // Show dialog and request permissions
        if (mounted) {
          final shouldRequest = await _showPermissionDialog();
          if (shouldRequest) {
            final granted = await PermissionHelper.checkAndRequestBlePermissions();

            if (!granted && mounted) {
              setState(() {
                _hasError = true;
                _errorMessage = 'Permissions are required for device discovery';
                _isProcessing = false;
              });
              return;
            }
          }
        }
      } else {
        debugPrint('Running on platform that does not require permission handling');
      }

      // Navigate to ESP32 device discovery
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const DeviceDiscoveryScreen(),
          ),
        );
      }
    } on PermissionHandlerUnavailableException catch (e) {
      // The permission_handler plugin is not registered; show explicit error with retry
      debugPrint('Permission plugin unavailable: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage =
              'Permission plugin not available. Try rebuilding the app (flutter clean && flutter pub get) and restart.';
          _isProcessing = false;
        });
      }
    } catch (e) {
      debugPrint('Unexpected error during permission flow: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Unexpected error: $e';
          _isProcessing = false;
        });
      }
    }
  }

  Future<bool> _showPermissionDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Bluetooth Permission Required'),
            content: const Text(
              'This app needs Bluetooth and Location permissions to discover and connect to ESP32 devices.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Grant Permission'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Device'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: _hasError
            ? _buildErrorContent(theme)
            : _isProcessing
                ? _buildProcessingContent(theme)
                : _buildProcessingContent(theme),
      ),
    );
  }

  Widget _buildProcessingContent(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Checking permissions...',
          style: theme.textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildErrorContent(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 64, color: Colors.red),
        const SizedBox(height: AppSpacing.lg),
        Text(
          _errorMessage ?? 'An error occurred',
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        ElevatedButton(
          onPressed: () => _navigateToProvisioning(),
          child: const Text('Retry'),
        ),
      ],
    );
  }
}

