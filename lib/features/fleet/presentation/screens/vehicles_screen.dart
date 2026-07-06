import 'package:flutter/material.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/design_tokens.dart';
import '../../../../core/utils/omnitrack_logo.dart';
import '../../application/controllers/fleet_controller.dart';
import '../../domain/entities/fleet_vehicle.dart';
import 'vehicle_detail_screen.dart';
import 'vehicle_form_screen.dart';

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({
    required this.controller,
    super.key,
  });

  final FleetController controller;

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.loadVehicles();
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
              'Vehículos',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.inkMuted,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Dispositivos',
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.fleetDevices),
            icon: const Icon(Icons.sensors_rounded),
          ),
          IconButton(
            tooltip: 'Actualizar',
            onPressed: widget.controller.loadVehicles,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo vehículo'),
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final controller = widget.controller;
          final vehicles = controller.vehicles;

          return RefreshIndicator(
            onRefresh: controller.loadVehicles,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xxl,
              ),
              children: [
                Row(
                  children: [
                    _CountChip(
                      label: '${vehicles.length} vehículo'
                          '${vehicles.length == 1 ? '' : 's'}',
                      accent: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _CountChip(
                      label: '${controller.inServiceVehicleCount} en servicio',
                      accent: AppColors.success,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (controller.isLoadingVehicles && vehicles.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (controller.errorMessage != null && vehicles.isEmpty)
                  _FleetMessage(
                    icon: Icons.cloud_off_rounded,
                    message: controller.errorMessage!,
                  )
                else if (vehicles.isEmpty)
                  const _FleetMessage(
                    icon: Icons.local_shipping_outlined,
                    message: 'No hay vehículos registrados.',
                  )
                else
                  for (final vehicle in vehicles) ...[
                    _VehicleTile(
                      vehicle: vehicle,
                      onTap: () => _openDetail(vehicle.id),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _openCreate() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VehicleFormScreen(controller: widget.controller),
      ),
    );
  }

  void _openDetail(String vehicleId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VehicleDetailScreen(
          controller: widget.controller,
          vehicleId: vehicleId,
        ),
      ),
    );
  }
}

class _VehicleTile extends StatelessWidget {
  const _VehicleTile({
    required this.vehicle,
    required this.onTap,
  });

  final FleetVehicle vehicle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.plate,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${vehicle.typeLabel} · ${vehicle.statusLabel}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.inkMuted,
                          ),
                    ),
                    if (vehicle.odometerKm != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        '${vehicle.odometerKm} km',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (vehicle.hasAssignedDevices)
                    Text(
                      '${vehicle.deviceImeis.length} disp.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.inkMuted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.label,
    required this.accent,
  });

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: accent,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _FleetMessage extends StatelessWidget {
  const _FleetMessage({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Icon(icon, size: 42, color: AppColors.inkMuted),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
