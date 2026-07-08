import 'package:flutter/material.dart';

import '../../../../core/utils/design_tokens.dart';

class AnalyticsSegmentedControl<T> extends StatelessWidget {
  const AnalyticsSegmentedControl({
    required this.values,
    required this.selected,
    required this.labelBuilder,
    required this.onChanged,
    super.key,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (int index = 0; index < values.length; index++) ...[
            Expanded(
              child: _SegmentButton(
                label: labelBuilder(values[index]),
                isSelected: values[index] == selected,
                onTap: () => onChanged(values[index]),
                isFirst: index == 0,
                isLast: index == values.length - 1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isFirst,
    required this.isLast,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.horizontal(
        left: isFirst ? const Radius.circular(AppRadius.sm - 1) : Radius.zero,
        right: isLast ? const Radius.circular(AppRadius.sm - 1) : Radius.zero,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.horizontal(
          left: isFirst ? const Radius.circular(AppRadius.sm - 1) : Radius.zero,
          right: isLast ? const Radius.circular(AppRadius.sm - 1) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: 10,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: isSelected ? Colors.white : AppColors.inkMuted,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}

class AnalyticsKpiCard extends StatelessWidget {
  const AnalyticsKpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border(
            left: BorderSide(color: accent, width: 4),
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.inkMuted,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                  ),
                ],
              ),
            ),
            Icon(icon, color: accent, size: 28),
          ],
        ),
      ),
    );
  }
}

class AnalyticsKpiGrid extends StatelessWidget {
  const AnalyticsKpiGrid({
    required this.totalTrips,
    required this.activeTrips,
    required this.totalAlerts,
    required this.pendingAlerts,
    super.key,
  });

  final int totalTrips;
  final int activeTrips;
  final int totalAlerts;
  final int pendingAlerts;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 560 ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: crossAxisCount == 4 ? 1.55 : 1.35,
          children: [
            AnalyticsKpiCard(
              label: 'Total rutas',
              value: '$totalTrips',
              icon: Icons.local_shipping_outlined,
              accent: AppColors.primary,
            ),
            AnalyticsKpiCard(
              label: 'Rutas activas',
              value: '$activeTrips',
              icon: Icons.radar_outlined,
              accent: AppColors.accent,
            ),
            AnalyticsKpiCard(
              label: 'Total alertas',
              value: '$totalAlerts',
              icon: Icons.notifications_outlined,
              accent: AppColors.warning,
            ),
            AnalyticsKpiCard(
              label: 'Pendientes',
              value: '$pendingAlerts',
              icon: Icons.warning_amber_rounded,
              accent: AppColors.danger,
            ),
          ],
        );
      },
    );
  }
}
