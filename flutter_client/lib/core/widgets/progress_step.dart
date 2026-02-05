import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Progress step indicator for provisioning flow.
///
/// Displays step status with icon, label, and progress line.
enum StepStatus {
  pending,
  inProgress,
  completed,
  failed,
}

class ProgressStep extends StatelessWidget {
  const ProgressStep({
    super.key,
    required this.label,
    required this.status,
    this.description,
    this.isLast = false,
  });

  final String label;
  final StepStatus status;
  final String? description;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon column with connector line
        Column(
          children: [
            _StepIcon(status: status),
            if (!isLast)
              _ConnectorLine(
                isCompleted: status == StepStatus.completed,
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.md),

        // Content column
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: isLast ? 0 : AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2), // Align with icon center
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: _getLabelColor(status, theme),
                    fontWeight:
                        status == StepStatus.inProgress ? FontWeight.w600 : null,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getLabelColor(StepStatus status, ThemeData theme) {
    return switch (status) {
      StepStatus.pending => theme.colorScheme.onSurfaceVariant,
      StepStatus.inProgress => theme.colorScheme.primary,
      StepStatus.completed => theme.colorScheme.onSurface,
      StepStatus.failed => theme.colorScheme.error,
    };
  }
}

class _StepIcon extends StatelessWidget {
  const _StepIcon({required this.status});

  final StepStatus status;

  @override
  Widget build(BuildContext context) {
    final size = 28.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getBackgroundColor(status),
        border: status == StepStatus.pending
            ? Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 2,
              )
            : null,
      ),
      child: Center(
        child: _getIcon(status),
      ),
    );
  }

  Color _getBackgroundColor(StepStatus status) {
    return switch (status) {
      StepStatus.pending => Colors.transparent,
      StepStatus.inProgress => AppColors.primaryLight.withOpacity(0.2),
      StepStatus.completed => AppColors.success,
      StepStatus.failed => AppColors.error,
    };
  }

  Widget _getIcon(StepStatus status) {
    return switch (status) {
      StepStatus.pending => Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.neutral400,
          ),
        ),
      StepStatus.inProgress => const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      StepStatus.completed => const Icon(
          Icons.check_rounded,
          size: 16,
          color: Colors.white,
        ),
      StepStatus.failed => const Icon(
          Icons.close_rounded,
          size: 16,
          color: Colors.white,
        ),
    };
  }
}

class _ConnectorLine extends StatelessWidget {
  const _ConnectorLine({required this.isCompleted});

  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2,
      height: 32,
      decoration: BoxDecoration(
        color: isCompleted
            ? AppColors.success
            : Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}

/// List of progress steps
class ProgressStepList extends StatelessWidget {
  const ProgressStepList({
    super.key,
    required this.steps,
  });

  final List<({String label, StepStatus status, String? description})> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < steps.length; i++)
          ProgressStep(
            label: steps[i].label,
            status: steps[i].status,
            description: steps[i].description,
            isLast: i == steps.length - 1,
          ),
      ],
    );
  }
}
