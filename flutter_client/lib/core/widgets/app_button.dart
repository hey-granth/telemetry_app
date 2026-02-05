import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Primary action button with consistent styling.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isEnabled = true,
    this.variant = ButtonVariant.filled,
    this.size = ButtonSize.medium,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isEnabled;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isEnabled && !isLoading ? onPressed : null;
    final buttonChild = _buildChild(context);

    Widget button = switch (variant) {
      ButtonVariant.filled => FilledButton(
          onPressed: effectiveOnPressed,
          style: _getButtonStyle(context),
          child: buttonChild,
        ),
      ButtonVariant.outlined => OutlinedButton(
          onPressed: effectiveOnPressed,
          style: _getButtonStyle(context),
          child: buttonChild,
        ),
      ButtonVariant.text => TextButton(
          onPressed: effectiveOnPressed,
          style: _getButtonStyle(context),
          child: buttonChild,
        ),
      ButtonVariant.tonal => FilledButton.tonal(
          onPressed: effectiveOnPressed,
          style: _getButtonStyle(context),
          child: buttonChild,
        ),
    };

    if (expand) {
      button = SizedBox(width: double.infinity, child: button);
    }

    return button;
  }

  Widget _buildChild(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: _getLoaderSize(),
        height: _getLoaderSize(),
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: variant == ButtonVariant.filled
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.primary,
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _getIconSize()),
          const SizedBox(width: AppSpacing.sm),
          Text(label),
        ],
      );
    }

    return Text(label);
  }

  ButtonStyle? _getButtonStyle(BuildContext context) {
    final minHeight = switch (size) {
      ButtonSize.small => 36.0,
      ButtonSize.medium => 48.0,
      ButtonSize.large => 56.0,
    };

    final horizontalPadding = switch (size) {
      ButtonSize.small => AppSpacing.md,
      ButtonSize.medium => AppSpacing.lg,
      ButtonSize.large => AppSpacing.xl,
    };

    return ButtonStyle(
      minimumSize: WidgetStateProperty.all(Size(64, minHeight)),
      padding: WidgetStateProperty.all(
        EdgeInsets.symmetric(horizontal: horizontalPadding),
      ),
    );
  }

  double _getIconSize() {
    return switch (size) {
      ButtonSize.small => 18,
      ButtonSize.medium => 20,
      ButtonSize.large => 24,
    };
  }

  double _getLoaderSize() {
    return switch (size) {
      ButtonSize.small => 16,
      ButtonSize.medium => 20,
      ButtonSize.large => 24,
    };
  }
}

enum ButtonVariant {
  filled,
  outlined,
  text,
  tonal,
}

enum ButtonSize {
  small,
  medium,
  large,
}
