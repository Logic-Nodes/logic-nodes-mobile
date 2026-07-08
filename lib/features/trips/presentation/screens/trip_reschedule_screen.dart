import 'package:flutter/material.dart';

import '../../../../core/utils/design_tokens.dart';
import '../../../../core/utils/status_labels.dart';
import '../../application/controllers/trips_controller.dart';

class TripRescheduleScreen extends StatefulWidget {
  const TripRescheduleScreen({
    required this.controller,
    required this.tripId,
    super.key,
  });

  final TripsController controller;
  final String tripId;

  @override
  State<TripRescheduleScreen> createState() => _TripRescheduleScreenState();
}

class _TripRescheduleScreenState extends State<TripRescheduleScreen> {
  String? _vehicleId;
  String? _deviceId;
  String? _originPointId;

  @override
  void initState() {
    super.initState();
    final trip = widget.controller.selectedTrip;
    if (trip != null && trip.id == widget.tripId) {
      _vehicleId = trip.vehicleId;
      _deviceId = trip.deviceId;
      _originPointId = trip.originPointId;
    }
    widget.controller.loadFormData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reprogramar viaje'),
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final controller = widget.controller;
          final trip = controller.selectedTrip;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(
                '¿Cuándo debe partir este envío?',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Actualiza origen, vehículo y dispositivo IoT antes de que inicie el viaje o mientras está en curso.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkMuted,
                    ),
              ),
              if (trip != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Viaje #${trip.id}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Estado: ${StatusLabels.tripStatus(trip.status)}',
                          style: const TextStyle(color: AppColors.inkMuted),
                        ),
                        if (trip.trackingCode != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Seguimiento: ${trip.trackingCode}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Selecciona un nuevo punto de origen',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                value: _originPointId,
                decoration: const InputDecoration(
                  labelText: 'Punto de origen',
                  border: OutlineInputBorder(),
                ),
                items: controller.originPoints
                    .map(
                      (point) => DropdownMenuItem(
                        value: point.id,
                        child: Text(
                          point.address != null
                              ? '${point.name} · ${point.address}'
                              : point.name,
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: controller.isSubmitting
                    ? null
                    : (value) => setState(() => _originPointId = value),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                value: _vehicleId,
                decoration: const InputDecoration(
                  labelText: 'Vehículo',
                  border: OutlineInputBorder(),
                ),
                items: controller.vehicles
                    .map(
                      (vehicle) => DropdownMenuItem(
                        value: vehicle.id,
                        child: Text('${vehicle.plate} (${vehicle.type})'),
                      ),
                    )
                    .toList(growable: false),
                onChanged: controller.isSubmitting
                    ? null
                    : (value) => setState(() => _vehicleId = value),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                value: _deviceId,
                decoration: const InputDecoration(
                  labelText: 'Dispositivo IoT',
                  border: OutlineInputBorder(),
                ),
                items: controller.devices
                    .map(
                      (device) => DropdownMenuItem(
                        value: device.id,
                        child: Text(
                          '${device.imei}${device.vehiclePlate != null ? ' · ${device.vehiclePlate}' : ''}',
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: controller.isSubmitting
                    ? null
                    : (value) => setState(() => _deviceId = value),
              ),
              if (controller.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  controller.errorMessage!,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: controller.isSubmitting ? null : _submit,
                child: controller.isSubmitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Reprogramar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submit() async {
    final success = await widget.controller.rescheduleTrip(
      tripId: widget.tripId,
      originPointId: _originPointId,
      deviceId: _deviceId,
      vehicleId: _vehicleId,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Viaje reprogramado correctamente.')),
      );
      Navigator.of(context).pop();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.controller.errorMessage ?? 'No se pudo reprogramar el viaje.',
        ),
      ),
    );
  }
}
