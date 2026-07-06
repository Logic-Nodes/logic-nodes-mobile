import 'package:flutter/material.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/design_tokens.dart';
import '../../../../core/utils/omnitrack_logo.dart';
import '../../application/controllers/fleet_controller.dart';
import '../../domain/entities/fleet_device.dart';
import 'device_detail_screen.dart';
import 'device_form_screen.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({
    required this.controller,
    super.key,
  });

  final FleetController controller;

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.loadDevices();
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
              'Dispositivos',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.inkMuted,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Vehículos',
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.fleetVehicles),
            icon: const Icon(Icons.local_shipping_rounded),
          ),
          IconButton(
            tooltip: 'Actualizar',
            onPressed: widget.controller.loadDevices,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo dispositivo'),
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final controller = widget.controller;
          final devices = controller.devices;

          return RefreshIndicator(
            onRefresh: controller.loadDevices,
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
                      label: '${devices.length} dispositivo'
                          '${devices.length == 1 ? '' : 's'}',
                      accent: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _CountChip(
                      label: '${controller.onlineDeviceCount} en línea',
                      accent: AppColors.success,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (controller.isLoadingDevices && devices.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (controller.errorMessage != null && devices.isEmpty)
                  _FleetMessage(
                    icon: Icons.cloud_off_rounded,
                    message: controller.errorMessage!,
                  )
                else if (devices.isEmpty)
                  const _FleetMessage(
                    icon: Icons.sensors_outlined,
                    message: 'No hay dispositivos registrados.',
                  )
                else
                  for (final device in devices) ...[
                    _DeviceTile(
                      device: device,
                      onTap: () => _openDetail(device.id),
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
        builder: (_) => DeviceFormScreen(controller: widget.controller),
      ),
    );
  }

  void _openDetail(String deviceId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DeviceDetailScreen(
          controller: widget.controller,
          deviceId: deviceId,
        ),
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({
    required this.device,
    required this.onTap,
  });

  final FleetDevice device;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onlineColor = device.online ? AppColors.success : AppColors.inkMuted;

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
                  color: onlineColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  device.online ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                  color: onlineColor,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.imei,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      device.online ? 'En línea' : 'Fuera de línea',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: onlineColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (device.vehiclePlate != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Vehículo: ${device.vehiclePlate}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.inkMuted,
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
