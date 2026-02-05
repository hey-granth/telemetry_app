/// WiFi credentials input page.
///
/// Collects network credentials for device provisioning.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/wifi_providers.dart';

/// WiFi credentials page
class WifiCredentialsPage extends ConsumerStatefulWidget {
  const WifiCredentialsPage({
    super.key,
    required this.deviceId,
    required this.deviceName,
  });

  final String deviceId;
  final String deviceName;

  @override
  ConsumerState<WifiCredentialsPage> createState() => _WifiCredentialsPageState();
}

class _WifiCredentialsPageState extends ConsumerState<WifiCredentialsPage> {
  final _formKey = GlobalKey<FormState>();
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isManualEntry = false;
  String? _selectedNetwork;

  @override
  void initState() {
    super.initState();
    // Fetch available networks
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(wifiNetworksProvider.notifier).scan();
    });
  }

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final networksState = ref.watch(wifiNetworksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wi-Fi Setup'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            // Device info header
            _DeviceInfoHeader(
              deviceId: widget.deviceId,
              deviceName: widget.deviceName,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Network selection or manual entry
            if (!_isManualEntry) ...[
              _SectionTitle(title: 'Select Network'),
              const SizedBox(height: AppSpacing.sm),
              _NetworkList(
                networks: networksState.networks,
                isLoading: networksState.isScanning,
                selectedSsid: _selectedNetwork,
                onSelect: (network) {
                  setState(() {
                    _selectedNetwork = network.ssid;
                    _ssidController.text = network.ssid;
                  });
                },
                onRefresh: () => ref.read(wifiNetworksProvider.notifier).scan(),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _isManualEntry = true),
                  child: const Text('Enter network manually'),
                ),
              ),
            ] else ...[
              _SectionTitle(title: 'Network Name'),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _ssidController,
                decoration: const InputDecoration(
                  hintText: 'Enter Wi-Fi network name (SSID)',
                  prefixIcon: Icon(Icons.wifi),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Network name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _isManualEntry = false),
                  child: const Text('Choose from available networks'),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),

            // Password input
            _SectionTitle(title: 'Password'),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: 'Enter Wi-Fi password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                if (value.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _PasswordStrengthHint(password: _passwordController.text),

            const SizedBox(height: AppSpacing.lg),

            // Security notice
            _SecurityNotice(),
          ],
        ),
      ),
      bottomNavigationBar: _BottomBar(
        isEnabled: _canProceed(),
        onContinue: _handleContinue,
      ),
    );
  }

  bool _canProceed() {
    final ssid = _isManualEntry ? _ssidController.text : _selectedNetwork;
    return ssid != null && ssid.isNotEmpty && _passwordController.text.length >= 8;
  }

  void _handleContinue() {
    if (!_formKey.currentState!.validate()) return;

    final ssid = _isManualEntry ? _ssidController.text : _selectedNetwork!;

    Navigator.of(context).pushNamed(
      '/provisioning',
      arguments: ProvisioningArgs(
        deviceId: widget.deviceId,
        ssid: ssid,
        password: _passwordController.text,
      ),
    );
  }
}

class _DeviceInfoHeader extends StatelessWidget {
  const _DeviceInfoHeader({
    required this.deviceId,
    required this.deviceName,
  });

  final String deviceId;
  final String deviceName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(
              Icons.memory_rounded,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deviceName,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  deviceId,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: 24,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _NetworkList extends StatelessWidget {
  const _NetworkList({
    required this.networks,
    required this.isLoading,
    required this.selectedSsid,
    required this.onSelect,
    required this.onRefresh,
  });

  final List<WifiNetwork> networks;
  final bool isLoading;
  final String? selectedSsid;
  final void Function(WifiNetwork) onSelect;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading && networks.isEmpty) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              SizedBox(height: AppSpacing.sm),
              Text('Scanning for networks...'),
            ],
          ),
        ),
      );
    }

    if (networks.isEmpty) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wifi_off,
                size: 32,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'No networks found',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: onRefresh,
                child: const Text('Scan Again'),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: networks.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: theme.colorScheme.outlineVariant,
        ),
        itemBuilder: (context, index) {
          final network = networks[index];
          final isSelected = network.ssid == selectedSsid;

          return ListTile(
            leading: _WifiSignalIcon(strength: network.signalStrength),
            title: Text(network.ssid),
            subtitle: network.isSecure
                ? Row(
                    children: [
                      Icon(
                        Icons.lock,
                        size: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Secured',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  )
                : null,
            trailing: isSelected
                ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                : null,
            selected: isSelected,
            onTap: () => onSelect(network),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: index == 0
                    ? const Radius.circular(AppSpacing.radiusMd)
                    : Radius.zero,
                bottom: index == networks.length - 1
                    ? const Radius.circular(AppSpacing.radiusMd)
                    : Radius.zero,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WifiSignalIcon extends StatelessWidget {
  const _WifiSignalIcon({required this.strength});

  final int strength;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    if (strength >= 75) {
      icon = Icons.wifi;
    } else if (strength >= 50) {
      icon = Icons.wifi_2_bar;
    } else {
      icon = Icons.wifi_1_bar;
    }

    return Icon(
      icon,
      color: strength >= 50 ? AppColors.success : AppColors.warning,
    );
  }
}

class _PasswordStrengthHint extends StatelessWidget {
  const _PasswordStrengthHint({required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (password.isEmpty) {
      return const SizedBox.shrink();
    }

    String hint;
    Color color;

    if (password.length < 8) {
      hint = 'Password too short';
      color = AppColors.error;
    } else if (password.length < 12) {
      hint = 'Password strength: Fair';
      color = AppColors.warning;
    } else {
      hint = 'Password strength: Good';
      color = AppColors.success;
    }

    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            hint,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _SecurityNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Your credentials are sent directly to the device over a secure local connection and are not stored on our servers.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.isEnabled,
    required this.onContinue,
  });

  final bool isEnabled;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
      child: FilledButton(
        onPressed: isEnabled ? onContinue : null,
        child: const Text('Continue'),
      ),
    );
  }
}

