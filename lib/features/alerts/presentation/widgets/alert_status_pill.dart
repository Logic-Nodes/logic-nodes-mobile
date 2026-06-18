import 'package:flutter/material.dart';

import '../../../../core/utils/design_tokens.dart';
import '../../domain/entities/alert.dart';

class AlertStatusPill extends StatelessWidget {
  const AlertStatusPill({
    required this.status,
    super.key,
  });

  final AlertStatus status;

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(status);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          status.label,
          style: TextStyle(
            color: accent,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Color _accentFor(AlertStatus status) {
    switch (status) {
      case AlertStatus.open:
        return AppColors.danger;
      case AlertStatus.acknowledged:
        return AppColors.warning;
      case AlertStatus.closed:
        return AppColors.success;
    }
  }
}
