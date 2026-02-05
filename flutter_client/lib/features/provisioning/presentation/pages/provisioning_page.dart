/// Provisioning progress page.
///
/// Shows real-time provisioning status with step-by-step feedback.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/progress_step.dart';
import '../providers/provisioning_providers.dart';

/// Provisioning page
class ProvisioningPage extends ConsumerStatefulWidget {
  const ProvisioningPage({
    super.key,
    required this.deviceId,
    required this.ssid,
    required this.password,
  });

  final String deviceId;
  final String ssid;
  final String password;

  @override
  ConsumerState<ProvisioningPage> createState() => _ProvisioningPageState();
}

class _ProvisioningPageState extends ConsumerState<ProvisioningPage> {
  @override
  void initState() {
    super.initState();
    // Start provisioning when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(provisioningProvider.notifier).startProvisioning(
            deviceId: widget.deviceId,
            ssid: widget.ssid,
            password: widget.password,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provisioningState = ref.watch(provisioningProvider);
    final theme = Theme.of(context);

    return PopScope(
      canPop: provisioningState.isComplete || provisioningState.hasFailed,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showCancelDialog();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Setting Up Device'),
          automaticallyImplyLeading: false,
          actions: [
            if (!provisioningState.isComplete && !provisioningState.hasFailed)
              TextButton(
                onPressed: _showCancelDialog,
                child: const Text('Cancel'),
              ),
          ],
        ),
        body: Column(
          children: [
            // Progress header
            _ProgressHeader(state: provisioningState),

            // Steps list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                children: [
                  const SizedBox(height: AppSpacing.md),
                  _buildStepsList(provisioningState),
                  const SizedBox(height: AppSpacing.xl),

                  // Error message if failed
                  if (provisioningState.hasFailed &&
                      provisioningState.errorMessage != null)
                    _ErrorCard(message: provisioningState.errorMessage!),
                ],
              ),
            ),

            // Bottom action bar
            _BottomActionBar(
              state: provisioningState,
              onRetry: () => ref.read(provisioningProvider.notifier).retry(),
              onDone: () => _navigateToDashboard(),
              onCancel: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsList(ProvisioningState state) {
    final steps = [
      (
        label: 'Connecting to device',
        status: _getStepStatus(ProvisioningStep.connecting, state),
        description: state.currentStep == ProvisioningStep.connecting
            ? 'Establishing secure connection...'
            : null,
      ),
      (
        label: 'Sending Wi-Fi credentials',
        status: _getStepStatus(ProvisioningStep.sendingCredentials, state),
        description: state.currentStep == ProvisioningStep.sendingCredentials
            ? 'Transmitting network configuration...'
            : null,
      ),
      (
        label: 'Configuring device',
        status: _getStepStatus(ProvisioningStep.configuringDevice, state),
        description: state.currentStep == ProvisioningStep.configuringDevice
            ? 'Device is connecting to Wi-Fi...'
            : null,
      ),
      (
        label: 'Registering with server',
        status: _getStepStatus(ProvisioningStep.registeringWithServer, state),
        description: state.currentStep == ProvisioningStep.registeringWithServer
            ? 'Registering device on backend...'
            : null,
      ),
      (
        label: 'Verifying connection',
        status: _getStepStatus(ProvisioningStep.verifying, state),
        description: state.currentStep == ProvisioningStep.verifying
            ? 'Confirming successful setup...'
            : null,
      ),
    ];

    return ProgressStepList(steps: steps);
  }

  StepStatus _getStepStatus(ProvisioningStep step, ProvisioningState state) {
    final stepIndex = ProvisioningStep.values.indexOf(step);
    final currentIndex = ProvisioningStep.values.indexOf(state.currentStep);

    if (state.failedStep == step) {
      return StepStatus.failed;
    }

    if (stepIndex < currentIndex) {
      return StepStatus.completed;
    }

    if (stepIndex == currentIndex && !state.isComplete && !state.hasFailed) {
      return StepStatus.inProgress;
    }

    if (state.isComplete && stepIndex <= currentIndex) {
      return StepStatus.completed;
    }

    return StepStatus.pending;
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Setup?'),
        content: const Text(
          'The device setup is not complete. If you cancel now, you will need to start over.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue Setup'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _navigateToDashboard() {
    // Pop all provisioning screens and go to device dashboard
    Navigator.of(context).popUntil((route) => route.isFirst);
    Navigator.of(context).pushNamed(
      '/dashboard',
      arguments: widget.deviceId,
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.state});

  final ProvisioningState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color backgroundColor;
    IconData icon;
    String title;
    String subtitle;

    if (state.isComplete) {
      backgroundColor = AppColors.success;
      icon = Icons.check_circle;
      title = 'Setup Complete!';
      subtitle = 'Your device is ready to use';
    } else if (state.hasFailed) {
      backgroundColor = AppColors.error;
      icon = Icons.error;
      title = 'Setup Failed';
      subtitle = 'There was a problem configuring your device';
    } else {
      backgroundColor = theme.colorScheme.primary;
      icon = Icons.settings_rounded;
      title = 'Setting Up...';
      subtitle = 'Please don\'t close this screen';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: backgroundColor.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: backgroundColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: state.isComplete || state.hasFailed
                ? Icon(icon, size: 36, color: backgroundColor)
                : SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: backgroundColor,
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: backgroundColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Error Details',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.state,
    required this.onRetry,
    required this.onDone,
    required this.onCancel,
  });

  final ProvisioningState state;
  final VoidCallback onRetry;
  final VoidCallback onDone;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!state.isComplete && !state.hasFailed) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.screenPadding,
        right: AppSpacing.screenPadding,
        top: AppSpacing.md,
        bottom: AppSpacing.md + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          if (state.hasFailed) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: onCancel,
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ),
          ] else ...[
            Expanded(
              child: FilledButton(
                onPressed: onDone,
                child: const Text('View Dashboard'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
