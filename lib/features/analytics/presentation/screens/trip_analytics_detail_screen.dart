import 'package:flutter/material.dart';

import '../../../../core/utils/design_tokens.dart';
import '../../application/controllers/analytics_controller.dart';
import '../widgets/analytics_charts.dart';

class TripAnalyticsDetailScreen extends StatefulWidget {
  const TripAnalyticsDetailScreen({
    required this.controller,
    required this.tripId,
    super.key,
  });

  final AnalyticsController controller;
  final String tripId;

  @override
  State<TripAnalyticsDetailScreen> createState() =>
      _TripAnalyticsDetailScreenState();
}

class _TripAnalyticsDetailScreenState extends State<TripAnalyticsDetailScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.loadTripDetail(widget.tripId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip analytics'),
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final controller = widget.controller;

          if (controller.isLoadingTrip && controller.tripDetail == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final detail = controller.tripDetail;
          final trip = detail?.trip;
          if (trip == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  controller.errorMessage ?? 'Trip not found.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.inkMuted),
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            children: [
              Text(
                'Cargo monitoring',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Datos de /trips, /monitoring/sessions/trip y /telemetry/session.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trip information',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _InfoGrid(
                        items: [
                          _InfoItem(label: 'Driver', value: trip.driverName),
                          _InfoItem(label: 'Cargo type', value: trip.cargoType),
                          _InfoItem(
                            label: 'Trip start',
                            value: _formatDate(trip.startDate),
                          ),
                          _InfoItem(
                            label: 'Route',
                            value: '${trip.origin} → ${trip.destination}',
                          ),
                          _InfoItem(
                            label: 'Distance',
                            value: '${trip.distance} km',
                          ),
                          _InfoItem(
                            label: 'Trip end',
                            value: _formatDate(trip.endDate),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Temperature vs time',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SensorLineChart(
                        data: controller.temperatureSeries,
                        color: AppColors.primary,
                        unit: '°C',
                        emptyMessage: 'No temperature data for this trip.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vibration vs time',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SensorLineChart(
                        data: controller.vibrationSeries,
                        color: AppColors.warning,
                        unit: '',
                        emptyMessage: 'No vibration data for this trip.',
                      ),
                    ],
                  ),
                ),
              ),
              if (controller.isLoadingTrip)
                const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.sm),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return value;
    }
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.items});

  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth >= 520
            ? (constraints.maxWidth - AppSpacing.md) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final item in items)
              SizedBox(
                width: itemWidth,
                child: item,
              ),
          ],
        );
      },
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
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
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}
