import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Status badge for displaying device/connection states.
///
/// Compact visual indicator with semantic colors.
enum StatusType {
  online,
  offline,
  connecting,
  provisioning,
  newDevice,
  paired,
  error,
  warning,
  success,
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.type,
    this.label,
    this.showDot = true,
    this.compact = false,
  });

  final StatusType type;
  final String? label;
  final bool showDot;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (color, defaultLabel) = _getStatusConfig(type);
    final displayLabel = label ?? defaultLabel;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: compact ? AppSpacing.xxs : AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            _AnimatedDot(color: color, animate: type == StatusType.connecting),
            SizedBox(width: compact ? AppSpacing.xs : AppSpacing.sm),
          ],
          Text(
            displayLabel,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  (Color, String) _getStatusConfig(StatusType type) {
    return switch (type) {
      StatusType.online => (AppColors.online, 'Online'),
      StatusType.offline => (AppColors.offline, 'Offline'),
      StatusType.connecting => (AppColors.connecting, 'Connecting'),
      StatusType.provisioning => (AppColors.provisioning, 'Provisioning'),
      StatusType.newDevice => (AppColors.info, 'New'),
      StatusType.paired => (AppColors.success, 'Paired'),
      StatusType.error => (AppColors.error, 'Error'),
      StatusType.warning => (AppColors.warning, 'Warning'),
      StatusType.success => (AppColors.success, 'Success'),
    };
  }
}

class _AnimatedDot extends StatefulWidget {
  const _AnimatedDot({
    required this.color,
    required this.animate,
  });

  final Color color;
  final bool animate;

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_AnimatedDot oldWidget) {
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
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(
              widget.animate ? _animation.value : 1.0,
            ),
          ),
        );
      },
    );
  }
}
