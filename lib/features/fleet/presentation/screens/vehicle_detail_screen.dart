import 'package:flutter/material.dart';

import '../../../../core/utils/design_tokens.dart';
import '../../application/controllers/fleet_controller.dart';
import '../../domain/entities/fleet_device.dart';
import 'vehicle_form_screen.dart';

class VehicleDetailScreen extends StatefulWidget {
  const VehicleDetailScreen({
    required this.controller,
    required this.vehicleId,
    super.key,
  });

  final FleetController controller;
  final String vehicleId;

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.loadVehicleDetail(widget.vehicleId);
      widget.controller.loadDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del vehículo'),
        actions: [
          IconButton(
            tooltip: 'Editar',
            onPressed: _openEdit,
            icon: const Icon(Icons.edit_rounded),
          ),
          IconButton(
            tooltip: 'Eliminar',
            onPressed: _confirmDelete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          if (widget.controller.isLoadingVehicleDetail &&
              widget.controller.selectedVehicle?.id != widget.vehicleId) {
            return const Center(child: CircularProgressIndicator());
          }

          final vehicle = widget.controller.vehicleById(widget.vehicleId);
          final isBusy = widget.controller.isVehicleBusy(widget.vehicleId);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              height: 52,
                              width: 52,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                              ),
                              child: const Icon(
                                Icons.local_shipping_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                vehicle.plate,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _InfoRow(label: 'Tipo', value: vehicle.typeLabel),
                        _InfoRow(label: 'Estado', value: vehicle.statusLabel),
                        _InfoRow(
                          label: 'Odómetro',
                          value: vehicle.odometerKm == null
                              ? '—'
                              : '${vehicle.odometerKm} km',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Dispositivos asignados',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (vehicle.deviceImeis.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Text('Sin dispositivos asignados.'),
                    ),
                  )
                else
                  for (final imei in vehicle.deviceImeis)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.sensors_rounded),
                        title: Text(imei),
                        trailing: isBusy
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : IconButton(
                                tooltip: 'Desasignar',
                                onPressed: () => _unassign(imei),
                                icon: const Icon(Icons.link_off_rounded),
                              ),
                      ),
                    ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: isBusy ? null : _assignDevice,
                  icon: const Icon(Icons.link_rounded),
                  label: const Text('Asignar dispositivo'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openEdit() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VehicleFormScreen(
          controller: widget.controller,
          vehicleId: widget.vehicleId,
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar vehículo'),
        content: const Text(
          '¿Seguro que deseas eliminar este vehículo? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final success = await widget.controller.deleteVehicle(widget.vehicleId);
    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).pop();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.controller.errorMessage ?? 'No se pudo eliminar el vehículo.',
        ),
      ),
    );
  }

  Future<void> _assignDevice() async {
    final devices = widget.controller.unassignedDevices;
    if (devices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay dispositivos disponibles para asignar.'),
        ),
      );
      return;
    }

    final selected = await showModalBottomSheet<FleetDevice>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'Seleccionar dispositivo',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final device in devices)
                ListTile(
                  leading: Icon(
                    device.online ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                    color: device.online ? AppColors.success : AppColors.inkMuted,
                  ),
                  title: Text(device.imei),
                  subtitle: Text(device.firmware ?? 'Sin firmware'),
                  onTap: () => Navigator.of(context).pop(device),
                ),
            ],
          ),
        );
      },
    );

    if (selected == null || !mounted) {
      return;
    }

    final updated = await widget.controller.assignDevice(
      vehicleId: widget.vehicleId,
      imei: selected.imei,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          updated != null
              ? 'Dispositivo asignado correctamente.'
              : widget.controller.errorMessage ??
                  'No se pudo asignar el dispositivo.',
        ),
      ),
    );
  }

  Future<void> _unassign(String imei) async {
    final updated = await widget.controller.unassignDevice(
      vehicleId: widget.vehicleId,
      imei: imei,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          updated != null
              ? 'Dispositivo desasignado.'
              : widget.controller.errorMessage ??
                  'No se pudo desasignar el dispositivo.',
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.inkMuted,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
