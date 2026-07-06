import 'package:flutter/material.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/design_tokens.dart';
import '../../application/controllers/trips_controller.dart';

class TripFormScreen extends StatefulWidget {
  const TripFormScreen({
    required this.controller,
    super.key,
  });

  final TripsController controller;

  @override
  State<TripFormScreen> createState() => _TripFormScreenState();
}

class _TripFormScreenState extends State<TripFormScreen> {
  String? _vehicleId;
  String? _deviceId;
  String? _originPointId;

  @override
  void initState() {
    super.initState();
    widget.controller.loadFormData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create trip'),
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final controller = widget.controller;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(
                'Plan a new route',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Merchant and driver IDs are taken from your session.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkMuted,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              DropdownButtonFormField<String>(
                value: _vehicleId,
                decoration: const InputDecoration(
                  labelText: 'Vehicle',
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
                onChanged: (value) => setState(() => _vehicleId = value),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                value: _deviceId,
                decoration: const InputDecoration(
                  labelText: 'Device',
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
                onChanged: (value) => setState(() => _deviceId = value),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                value: _originPointId,
                decoration: const InputDecoration(
                  labelText: 'Origin point',
                  border: OutlineInputBorder(),
                ),
                items: controller.originPoints
                    .map(
                      (point) => DropdownMenuItem(
                        value: point.id,
                        child: Text(
                          point.address == null
                              ? point.name
                              : '${point.name} — ${point.address}',
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) => setState(() => _originPointId = value),
              ),
              if (controller.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  controller.errorMessage!,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: controller.isSubmitting ? null : () => _submit(context),
                icon: controller.isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded),
                label: const Text('Create trip'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    final trip = await widget.controller.createTrip(
      vehicleId: _vehicleId,
      deviceId: _deviceId,
      originPointId: _originPointId,
    );

    if (!context.mounted) {
      return;
    }

    if (trip == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.controller.errorMessage ?? 'Unable to create the trip.',
          ),
        ),
      );
      return;
    }

    Navigator.of(context).pushReplacementNamed(
      AppRoutes.tripDetail,
      arguments: trip.id,
    );
  }
}
