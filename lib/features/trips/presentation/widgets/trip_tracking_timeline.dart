import 'package:flutter/material.dart';

import '../../../../core/utils/design_tokens.dart';
import '../../data/models/trip_models.dart';

class TripTrackingTimeline extends StatelessWidget {
  const TripTrackingTimeline({
    required this.tracking,
    super.key,
  });

  final PublicTripTracking tracking;

  @override
  Widget build(BuildContext context) {
    final events = _buildEvents();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            for (var index = 0; index < events.length; index++)
              _TimelineEntry(
                title: events[index].title,
                subtitle: events[index].subtitle,
                isActive: events[index].isActive,
                isLast: index == events.length - 1,
              ),
          ],
        ),
      ),
    );
  }

  List<_TimelineEvent> _buildEvents() {
    final events = <_TimelineEvent>[
      _TimelineEvent(
        title: 'Envío creado',
        subtitle: tracking.origin ?? 'Origen pendiente',
        isActive: tracking.status == 'PLANNED',
      ),
      _TimelineEvent(
        title: 'En tránsito',
        subtitle: tracking.startedAt != null
            ? _formatDate(tracking.startedAt)
            : 'Esperando salida',
        isActive: tracking.status == 'IN_PROGRESS',
      ),
      _TimelineEvent(
        title: 'Entregado',
        subtitle: tracking.completedAt != null
            ? _formatDate(tracking.completedAt)
            : 'Pendiente de completar',
        isActive: tracking.status == 'COMPLETED',
      ),
    ];

    if (tracking.status == 'CANCELLED') {
      events.add(
        const _TimelineEvent(
          title: 'Cancelado',
          subtitle: 'El viaje fue cancelado',
          isActive: true,
        ),
      );
    }

    return events;
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '—';
    }

    final local = value.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}

class _TimelineEvent {
  const _TimelineEvent({
    required this.title,
    required this.subtitle,
    required this.isActive,
  });

  final String title;
  final String subtitle;
  final bool isActive;
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.isLast,
  });

  final String title;
  final String subtitle;
  final bool isActive;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final dotColor = isActive ? AppColors.primary : AppColors.border;
    final lineColor = isActive ? AppColors.primary : AppColors.border;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: lineColor,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isActive ? AppColors.ink : AppColors.inkMuted,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isActive ? AppColors.inkMuted : AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
