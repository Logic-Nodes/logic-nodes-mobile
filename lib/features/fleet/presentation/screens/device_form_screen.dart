import 'package:flutter/material.dart';

import '../../../../core/utils/design_tokens.dart';
import '../../application/controllers/fleet_controller.dart';

class DeviceFormScreen extends StatefulWidget {
  const DeviceFormScreen({
    required this.controller,
    this.deviceId,
    super.key,
  });

  final FleetController controller;
  final String? deviceId;

  bool get isEditing => deviceId != null && deviceId!.isNotEmpty;

  @override
  State<DeviceFormScreen> createState() => _DeviceFormScreenState();
}

class _DeviceFormScreenState extends State<DeviceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _imeiController;
  late final TextEditingController _firmwareController;
  late bool _online;

  @override
  void initState() {
    super.initState();
    final device = widget.isEditing
        ? widget.controller.deviceById(widget.deviceId!)
        : null;

    _imeiController = TextEditingController(text: device?.imei ?? '');
    _firmwareController = TextEditingController(text: device?.firmware ?? '');
    _online = device?.online ?? false;

    if (widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.controller.loadDeviceDetail(widget.deviceId!);
      });
    }
  }

  @override
  void dispose() {
    _imeiController.dispose();
    _firmwareController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar dispositivo' : 'Nuevo dispositivo'),
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          if (widget.isEditing &&
              widget.controller.isLoadingDeviceDetail &&
              widget.controller.selectedDevice?.id != widget.deviceId) {
            return const Center(child: CircularProgressIndicator());
          }

          final device = widget.isEditing
              ? widget.controller.deviceById(widget.deviceId!)
              : null;

          if (device != null && _imeiController.text.isEmpty) {
            _imeiController.text = device.imei;
            _firmwareController.text = device.firmware ?? '';
            _online = device.online;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _imeiController,
                    decoration: const InputDecoration(
                      labelText: 'IMEI',
                      prefixIcon: Icon(Icons.perm_device_information_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa el IMEI del dispositivo.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _firmwareController,
                    decoration: const InputDecoration(
                      labelText: 'Firmware',
                      prefixIcon: Icon(Icons.memory_rounded),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('En línea'),
                    subtitle: const Text('Indica si el dispositivo está conectado.'),
                    value: _online,
                    onChanged: (value) => setState(() => _online = value),
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
                    label: Text(
                      widget.isEditing ? 'Guardar cambios' : 'Crear dispositivo',
                    ),
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

    final firmware = _firmwareController.text.trim();
    final result = widget.isEditing
        ? await widget.controller.updateDevice(
            deviceId: widget.deviceId!,
            imei: _imeiController.text.trim(),
            firmware: firmware.isEmpty ? null : firmware,
            online: _online,
          )
        : await widget.controller.createDevice(
            imei: _imeiController.text.trim(),
            firmware: firmware.isEmpty ? null : firmware,
            online: _online,
          );

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
          widget.controller.errorMessage ?? 'No se pudo guardar el dispositivo.',
        ),
      ),
    );
  }
}
