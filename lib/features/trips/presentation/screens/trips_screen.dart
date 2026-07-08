import 'package:flutter/material.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/design_tokens.dart';
import '../../../../core/utils/status_labels.dart';
import '../../../home/domain/entities/home_dashboard.dart';
import '../../application/controllers/trips_controller.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({
    required this.controller,
    super.key,
  });

  final TripsController controller;

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Viajes'),
        actions: [
          IconButton(
            tooltip: 'Rastrear por código',
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.publicTracking),
            icon: const Icon(Icons.qr_code_2_outlined),
          ),
          IconButton(
            tooltip: 'Actualizar',
            onPressed: widget.controller.isLoading ? null : widget.controller.load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.tripForm),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo viaje'),
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final controller = widget.controller;

          if (controller.isLoading && controller.visibleTrips.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: controller.load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                96,
              ),
              children: [
                _DateFilterBar(controller: controller),
                const SizedBox(height: AppSpacing.md),
                _StatusChips(controller: controller),
                const SizedBox(height: AppSpacing.lg),
                if (controller.errorMessage != null) ...[
                  Card(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text(controller.errorMessage!),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (controller.visibleTrips.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: Center(
                      child: Text(
                        'No hay viajes que coincidan con los filtros actuales.',
                        style: TextStyle(color: AppColors.inkMuted),
                      ),
                    ),
                  )
                else
                  ...controller.visibleTrips.map(
                    (trip) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _TripCard(
                        trip: trip,
                        onTap: () => Navigator.of(context).pushNamed(
                          AppRoutes.tripDetail,
                          arguments: trip.id,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DateFilterBar extends StatelessWidget {
  const _DateFilterBar({required this.controller});

  final TripsController controller;

  @override
  Widget build(BuildContext context) {
    final from = controller.dateFrom;
    final to = controller.dateTo;
    final label = from == null && to == null
        ? 'Todas las fechas'
        : '${_format(from)} → ${_format(to)}';

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pickRange(context),
            icon: const Icon(Icons.date_range_outlined),
            label: Text(label),
          ),
        ),
        if (from != null || to != null) ...[
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            tooltip: 'Limpiar fechas',
            onPressed: controller.clearDateRange,
            icon: const Icon(Icons.clear_rounded),
          ),
        ],
      ],
    );
  }

  Future<void> _pickRange(BuildContext context) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDateRange: controller.dateFrom != null && controller.dateTo != null
          ? DateTimeRange(start: controller.dateFrom!, end: controller.dateTo!)
          : null,
    );

    if (range != null) {
      controller.setDateRange(from: range.start, to: range.end);
    }
  }

  String _format(DateTime? value) {
    if (value == null) {
      return '…';
    }

    return '${value.year}-${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }
}

class _StatusChips extends StatelessWidget {
  const _StatusChips({required this.controller});

  final TripsController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: TripStatusFilter.values.map((filter) {
          final selected = controller.statusFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: FilterChip(
              label: Text(filter.label),
              selected: selected,
              onSelected: (_) {
                controller.changeStatusFilter(filter);
                controller.load();
              },
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.trip,
    required this.onTap,
  });

  final HomeTrip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: const Icon(Icons.local_shipping_outlined, color: AppColors.primary),
        ),
        title: Text('Viaje #${trip.id}'),
        subtitle: Text(
          [
            StatusLabels.tripStatus(trip.status),
            if (trip.originPointName != null) trip.originPointName!,
            if (trip.createdAt != null) _formatDate(trip.createdAt!),
          ].join(' · '),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }
}
