import 'package:flutter/material.dart';

import '../../../../core/utils/design_tokens.dart';
import '../../application/controllers/fleet_controller.dart';
import '../../domain/entities/fleet_vehicle.dart';

class VehicleFormScreen extends StatefulWidget {
  const VehicleFormScreen({
    required this.controller,
    this.vehicleId,
    super.key,
  });

  final FleetController controller;
  final String? vehicleId;

  bool get isEditing => vehicleId != null && vehicleId!.isNotEmpty;

  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _plateController;
  late final TextEditingController _odometerController;
  late String _type;
  late String _status;

  @override
  void initState() {
    super.initState();
    final vehicle = widget.isEditing
        ? widget.controller.vehicleById(widget.vehicleId!)
        : null;

    _plateController = TextEditingController(text: vehicle?.plate ?? '');
    _odometerController = TextEditingController(
      text: vehicle?.odometerKm?.toString() ?? '',
    );
    _type = vehicle?.type ?? fleetVehicleTypes.first;
    _status = vehicle?.status ?? fleetVehicleStatuses.first;

    if (widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.controller.loadVehicleDetail(widget.vehicleId!);
      });
    }
  }

  @override
  void dispose() {
    _plateController.dispose();
    _odometerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar vehículo' : 'Nuevo vehículo'),
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          if (widget.isEditing &&
              widget.controller.isLoadingVehicleDetail &&
              widget.controller.selectedVehicle?.id != widget.vehicleId) {
            return const Center(child: CircularProgressIndicator());
          }

          final vehicle = widget.isEditing
              ? widget.controller.vehicleById(widget.vehicleId!)
              : null;

          if (vehicle != null && _plateController.text.isEmpty) {
            _plateController.text = vehicle.plate;
            _odometerController.text = vehicle.odometerKm?.toString() ?? '';
            _type = vehicle.type;
            _status = vehicle.status;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _plateController,
                    decoration: const InputDecoration(
                      labelText: 'Placa',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa la placa del vehículo.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    value: _type,
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: [
                      for (final type in fleetVehicleTypes)
                        DropdownMenuItem<String>(
                          value: type,
                          child: Text(_typeLabel(type)),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _type = value);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(
                      labelText: 'Estado',
                      prefixIcon: Icon(Icons.info_outline_rounded),
                    ),
                    items: [
                      for (final status in fleetVehicleStatuses)
                        DropdownMenuItem<String>(
                          value: status,
                          child: Text(_statusLabel(status)),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _status = value);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _odometerController,
                    decoration: const InputDecoration(
                      labelText: 'Odómetro (km)',
                      prefixIcon: Icon(Icons.speed_rounded),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    onPressed:
                        widget.controller.isSaving ? null : _submit,
                    icon: widget.controller.isSaving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(widget.isEditing ? 'Guardar cambios' : 'Crear vehículo'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final odometerRaw = _odometerController.text.trim();
    final odometerKm = odometerRaw.isEmpty ? null : num.tryParse(odometerRaw);

    final FleetVehicle? result;
    if (widget.isEditing) {
      result = await widget.controller.updateVehicle(
        vehicleId: widget.vehicleId!,
        plate: _plateController.text.trim().toUpperCase(),
        type: _type,
        status: _status,
        odometerKm: odometerKm,
      );
    } else {
      result = await widget.controller.createVehicle(
        plate: _plateController.text.trim().toUpperCase(),
        type: _type,
        status: _status,
        odometerKm: odometerKm,
      );
    }

    if (!mounted) {
      return;
    }

    if (result != null) {
      Navigator.of(context).pop(result);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.controller.errorMessage ?? 'No se pudo guardar el vehículo.',
        ),
      ),
    );
  }

  String _typeLabel(String type) {
    return FleetVehicle(
      id: '',
      plate: '',
      type: type,
      status: 'IN_SERVICE',
      deviceImeis: const [],
    ).typeLabel;
  }

  String _statusLabel(String status) {
    return FleetVehicle(
      id: '',
      plate: '',
      type: 'TRUCK',
      status: status,
      deviceImeis: const [],
    ).statusLabel;
  }
}
