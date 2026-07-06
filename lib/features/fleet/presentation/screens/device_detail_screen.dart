import 'package:flutter/material.dart';

import '../../../../core/utils/design_tokens.dart';
import '../../application/controllers/fleet_controller.dart';
import 'device_form_screen.dart';

class DeviceDetailScreen extends StatefulWidget {
  const DeviceDetailScreen({
    required this.controller,
    required this.deviceId,
    super.key,
  });

  final FleetController controller;
  final String deviceId;

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  final _firmwareController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.loadDeviceDetail(widget.deviceId);
    });
  }

  @override
  void dispose() {
    _firmwareController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del dispositivo'),
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
          if (widget.controller.isLoadingDeviceDetail &&
              widget.controller.selectedDevice?.id != widget.deviceId) {
            return const Center(child: CircularProgressIndicator());
          }

          final device = widget.controller.deviceById(widget.deviceId);
          final isBusy = widget.controller.isDeviceBusy(widget.deviceId);

          if (_firmwareController.text.isEmpty && device.firmware != null) {
            _firmwareController.text = device.firmware!;
          }

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
                                color: (device.online
                                        ? AppColors.success
                                        : AppColors.inkMuted)
                                    .withValues(alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Icon(
                                device.online
                                    ? Icons.wifi_rounded
                                    : Icons.wifi_off_rounded,
                                color: device.online
                                    ? AppColors.success
                                    : AppColors.inkMuted,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                device.imei,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _InfoRow(
                          label: 'Estado',
                          value: device.online ? 'En línea' : 'Fuera de línea',
                        ),
                        _InfoRow(
                          label: 'Firmware',
                          value: device.firmware ?? '—',
                        ),
                        _InfoRow(
                          label: 'Vehículo',
                          value: device.vehiclePlate ?? 'Sin asignar',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Conexión en línea'),
                  subtitle: const Text('Actualiza el estado de conexión del dispositivo.'),
                  value: device.online,
                  onChanged: isBusy
                      ? null
                      : (value) => _toggleOnline(value),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Actualizar firmware',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _firmwareController,
                  decoration: const InputDecoration(
                    labelText: 'Versión de firmware',
                    prefixIcon: Icon(Icons.memory_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: isBusy ? null : _updateFirmware,
                  icon: isBusy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.system_update_rounded),
                  label: const Text('Actualizar firmware'),
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
        builder: (_) => DeviceFormScreen(
          controller: widget.controller,
          deviceId: widget.deviceId,
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar dispositivo'),
        content: const Text(
          '¿Seguro que deseas eliminar este dispositivo? Esta acción no se puede deshacer.',
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

    final success = await widget.controller.deleteDevice(widget.deviceId);
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
          widget.controller.errorMessage ?? 'No se pudo eliminar el dispositivo.',
        ),
      ),
    );
  }

  Future<void> _toggleOnline(bool online) async {
    final updated = await widget.controller.toggleDeviceOnline(
      deviceId: widget.deviceId,
      online: online,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          updated != null
              ? 'Estado de conexión actualizado.'
              : widget.controller.errorMessage ??
                  'No se pudo actualizar el estado.',
        ),
      ),
    );
  }

  Future<void> _updateFirmware() async {
    final firmware = _firmwareController.text.trim();
    if (firmware.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa una versión de firmware.')),
      );
      return;
    }

    final updated = await widget.controller.updateDeviceFirmware(
      deviceId: widget.deviceId,
      firmware: firmware,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          updated != null
              ? 'Firmware actualizado correctamente.'
              : widget.controller.errorMessage ??
                  'No se pudo actualizar el firmware.',
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
