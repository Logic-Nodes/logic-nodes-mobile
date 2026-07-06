import 'package:flutter/material.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/design_tokens.dart';
import '../../../../core/utils/omnitrack_logo.dart';
import '../../application/controllers/analytics_controller.dart';
import '../../domain/entities/analytics_trip.dart';
import '../widgets/analytics_charts.dart';
import '../widgets/analytics_kpi_grid.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({
    required this.controller,
    super.key,
  });

  final AnalyticsController controller;

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const OmnitrackLogo(
              foregroundColor: AppColors.ink,
              iconSize: 18,
              textSize: 20,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Analytics',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.inkMuted,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
                widget.controller.isLoading ? null : widget.controller.loadDashboard,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final controller = widget.controller;
          final dashboard = controller.dashboard;

          if (dashboard == null) {
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return _AnalyticsErrorState(
              message: controller.errorMessage ??
                  'No analytics data is available for this account yet.',
              onRetry: controller.loadDashboard,
            );
          }

          return RefreshIndicator(
            onRefresh: controller.loadDashboard,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xl,
              ),
              children: [
                Text(
                  'Panel de control',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Vista general conectada a /trips, /alerts, /telemetry y /analytics del backend.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                AnalyticsKpiGrid(
                  totalTrips: dashboard.totalTrips,
                  activeTrips: dashboard.activeTrips,
                  totalAlerts: dashboard.totalAlerts,
                  pendingAlerts: dashboard.pendingAlerts,
                ),
                const SizedBox(height: AppSpacing.lg),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sensor activity overview',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Row(
                          children: [
                            _LegendDot(color: AppColors.primary, label: 'Temperature'),
                            const SizedBox(width: AppSpacing.md),
                            _LegendDot(color: AppColors.warning, label: 'Movement'),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AnalyticsSegmentedControl<AnalyticsPeriod>(
                          values: AnalyticsPeriod.values,
                          selected: controller.period,
                          labelBuilder: (value) => value.label,
                          onChanged: controller.changePeriod,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AnalyticsSegmentedControl<AnalyticsAlertTypeFilter>(
                          values: AnalyticsAlertTypeFilter.values,
                          selected: controller.alertTypeFilter,
                          labelBuilder: (value) => value.label,
                          onChanged: controller.changeAlertTypeFilter,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        IncidentsAreaChart(
                          data: controller.chartData,
                          alertTypeFilter: controller.alertTypeFilter,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (dashboard.liveTelemetry.isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Temperatura en tiempo real',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xxs,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Backend /telemetry',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              for (final reading in dashboard.liveTelemetry)
                                _LiveTelemetryCard(reading: reading),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estado de flota',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _FleetStatusRow(
                          label: 'En servicio',
                          value: '${dashboard.fleetStatus.inService}',
                          color: AppColors.success,
                        ),
                        const Divider(height: AppSpacing.lg),
                        _FleetStatusRow(
                          label: 'Mantenimiento',
                          value: '${dashboard.fleetStatus.maintenance}',
                          color: AppColors.warning,
                        ),
                        const Divider(height: AppSpacing.lg),
                        _FleetStatusRow(
                          label: 'Fuera de servicio',
                          value: '${dashboard.fleetStatus.outOfService}',
                          color: AppColors.danger,
                        ),
                        const Divider(height: AppSpacing.lg),
                        _FleetStatusRow(
                          label: 'Dispositivos online',
                          value: '${dashboard.onlineDevices}/${dashboard.totalDevices}',
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Actividad reciente',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pushNamed(
                        AppRoutes.analyticsTrips,
                      ),
                      child: const Text('Ver todas'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final trip in dashboard.trips.take(5)) ...[
                  _RecentTripTile(
                    trip: trip,
                    onTap: () => _openTripDetail(context, trip.id),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                if (controller.isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.sm),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openTripDetail(BuildContext context, String tripId) {
    Navigator.of(context).pushNamed(
      AppRoutes.analyticsTripDetail,
      arguments: tripId,
    );
  }
}

class AnalyticsTripsScreen extends StatefulWidget {
  const AnalyticsTripsScreen({
    required this.controller,
    super.key,
  });

  final AnalyticsController controller;

  @override
  State<AnalyticsTripsScreen> createState() => _AnalyticsTripsScreenState();
}

class _AnalyticsTripsScreenState extends State<AnalyticsTripsScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.controller.dashboard == null) {
      widget.controller.loadDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trips analytics'),
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final controller = widget.controller;
          final trips = controller.dashboard?.trips ?? const [];

          if (controller.isLoading && trips.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (trips.isEmpty) {
            return Center(
              child: Text(
                controller.errorMessage ??
                    'No trips returned by analytics API.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.inkMuted),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: trips.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final trip = trips[index];
              return _RecentTripTile(
                trip: trip,
                onTap: () => Navigator.of(context).pushNamed(
                  AppRoutes.analyticsTripDetail,
                  arguments: trip.id,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _RecentTripTile extends StatelessWidget {
  const _RecentTripTile({
    required this.trip,
    required this.onTap,
  });

  final AnalyticsTrip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.vehiclePlate,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${trip.origin} → ${trip.destination}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _TripStatusChip(status: trip.status),
              const SizedBox(width: AppSpacing.xs),
              const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripStatusChip extends StatelessWidget {
  const _TripStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toUpperCase();
    final color = switch (normalized) {
      'COMPLETED' => AppColors.success,
      'IN_PROGRESS' => AppColors.primary,
      'CANCELLED' => AppColors.danger,
      _ => AppColors.inkMuted,
    };

    final label = switch (normalized) {
      'COMPLETED' => 'Completado',
      'IN_PROGRESS' => 'En curso',
      'CREATED' => 'Creado',
      'CANCELLED' => 'Cancelado',
      _ => status,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 8,
          width: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.inkMuted,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _LiveTelemetryCard extends StatelessWidget {
  const _LiveTelemetryCard({required this.reading});

  final LiveTelemetryReading reading;

  @override
  Widget build(BuildContext context) {
    final temperature = reading.temperature;
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reading.vehiclePlate,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.inkMuted,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                temperature == null ? '--' : '${temperature.toStringAsFixed(1)}°C',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Trip ${reading.tripId}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FleetStatusRow extends StatelessWidget {
  const _FleetStatusRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 10,
          width: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _AnalyticsErrorState extends StatelessWidget {
  const _AnalyticsErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.analytics_outlined, size: 48, color: AppColors.inkMuted),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
