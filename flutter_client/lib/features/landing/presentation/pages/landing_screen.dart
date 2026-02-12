/// Landing screen.
///
/// First screen shown on app boot. Performs backend health check
/// without blocking UI. Allows user to continue regardless of backend status.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_shell.dart';
import '../../../../core/state/app_lifecycle.dart';
import '../../../../core/state/health_check_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Landing screen
class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen> {
  bool _hasChecked = false;

  @override
  void initState() {
    super.initState();
    // Perform non-blocking health check after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBackendHealth();
    });
  }

  Future<void> _checkBackendHealth() async {
    if (_hasChecked) return;
    _hasChecked = true;

    final healthService = ref.read(healthCheckServiceProvider);
    await healthService.checkHealth();
  }

  void _handleContinue() {
    // Mark app as ready/degraded based on backend status
    final backendStatus = ref.read(backendStatusProvider);

    if (backendStatus.isReachable) {
      ref.read(appLifecycleProvider.notifier).markReady();
    } else {
      ref.read(appLifecycleProvider.notifier).markDegraded();
    }

    // Navigate to main app
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const AppShell(),
      ),
    );
  }

  void _handleRetry() {
    setState(() {
      _hasChecked = false;
    });
    ref.read(backendStatusProvider.notifier).reset();
    _checkBackendHealth();
  }

  @override
  Widget build(BuildContext context) {
    final backendStatus = ref.watch(backendStatusProvider);
    final isChecking = !_hasChecked || backendStatus.lastChecked == null;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // App logo/branding
              _AppBranding(),

              const SizedBox(height: AppSpacing.xl),

              // Backend status indicator
              _BackendStatusIndicator(
                isChecking: isChecking,
                status: backendStatus,
              ),

              const Spacer(),

              // Action buttons
              _ActionButtons(
                isChecking: isChecking,
                status: backendStatus,
                onContinue: _handleContinue,
                onRetry: _handleRetry,
              ),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppBranding extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // App icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Icon(
            Icons.sensors,
            size: 56,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // App name
        Text(
          'Telemetry',
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),

        // Tagline
        Text(
          'IoT Device Monitoring',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _BackendStatusIndicator extends StatelessWidget {
  const _BackendStatusIndicator({
    required this.isChecking,
    required this.status,
  });

  final bool isChecking;
  final BackendStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isChecking) {
      return Column(
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Checking backend status...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    final (icon, color, label) = status.isReachable
        ? (Icons.check_circle, AppColors.success, 'Backend Online')
        : (Icons.cloud_off, AppColors.warning, 'Backend Offline');

    return Column(
      children: [
        Icon(
          icon,
          size: 48,
          color: color,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (!status.isReachable && status.errorMessage != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: theme.colorScheme.onErrorContainer,
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    status.errorMessage!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'You can continue in offline mode',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.isChecking,
    required this.status,
    required this.onContinue,
    required this.onRetry,
  });

  final bool isChecking;
  final BackendStatus status;
  final VoidCallback onContinue;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Continue button (always enabled after check)
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: !isChecking ? onContinue : null,
            child: const Text('Continue'),
          ),
        ),

        // Retry button (only show if offline)
        if (!isChecking && !status.isReachable) ...[
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onRetry,
              child: const Text('Retry Connection'),
            ),
          ),
        ],
      ],
    );
  }
}

