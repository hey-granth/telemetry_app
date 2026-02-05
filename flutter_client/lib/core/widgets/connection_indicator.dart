import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Connection status indicator.
///
/// Shows WebSocket/API connection state in the UI.
enum ConnectionStatus {
  connected,
  connecting,
  disconnected,
  error,
}

class ConnectionIndicator extends StatelessWidget {
  const ConnectionIndicator({
    super.key,
    required this.status,
    this.showLabel = true,
    this.compact = false,
  });

  final ConnectionStatus status;
  final bool showLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = _getStatusConfig(status);

    if (compact) {
      return _DotIndicator(color: color, animate: status == ConnectionStatus.connecting);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DotIndicator(color: color, animate: status == ConnectionStatus.connecting),
          if (showLabel) ...[
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }

  (Color, String, IconData) _getStatusConfig(ConnectionStatus status) {
    return switch (status) {
      ConnectionStatus.connected => (AppColors.online, 'Live', Icons.wifi),
      ConnectionStatus.connecting => (AppColors.connecting, 'Connecting', Icons.sync),
      ConnectionStatus.disconnected => (AppColors.offline, 'Offline', Icons.wifi_off),
      ConnectionStatus.error => (AppColors.error, 'Error', Icons.error_outline),
    };
  }
}

class _DotIndicator extends StatefulWidget {
  const _DotIndicator({
    required this.color,
    required this.animate,
  });

  final Color color;
  final bool animate;

  @override
  State<_DotIndicator> createState() => _DotIndicatorState();
}

class _DotIndicatorState extends State<_DotIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_DotIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(
              widget.animate ? (0.4 + 0.6 * _controller.value) : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.3),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}
