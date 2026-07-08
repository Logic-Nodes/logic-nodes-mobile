import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/design_tokens.dart';
import '../../../../core/utils/status_labels.dart';
import '../../application/controllers/trips_controller.dart';
import '../../data/models/trip_models.dart';
import '../widgets/trip_tracking_timeline.dart';

class PublicTrackingScreen extends StatefulWidget {
  const PublicTrackingScreen({
    required this.controller,
    this.initialCode,
    super.key,
  });

  final TripsController controller;
  final String? initialCode;

  @override
  State<PublicTrackingScreen> createState() => _PublicTrackingScreenState();
}

class _PublicTrackingScreenState extends State<PublicTrackingScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    widget.controller.clearPublicTracking();
    if (widget.initialCode != null && widget.initialCode!.isNotEmpty) {
      _codeController.text = widget.initialCode!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _lookup());
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rastrear envío'),
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final controller = widget.controller;
          final tracking = controller.publicTracking;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(
                'Ingresa tu código de seguimiento',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Consulta el estado en vivo de un envío de cadena de frío sin iniciar sesión.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkMuted,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Form(
                key: _formKey,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          labelText: 'Código de seguimiento',
                          hintText: 'DEMO7K9M2',
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El código de seguimiento es obligatorio.';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _lookup(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: FilledButton(
                        onPressed:
                            controller.isLookingUpTracking ? null : _lookup,
                        child: controller.isLookingUpTracking
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Rastrear'),
                      ),
                    ),
                  ],
                ),
              ),
              if (controller.errorMessage != null && tracking == null) ...[
                const SizedBox(height: AppSpacing.md),
                Card(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(controller.errorMessage!),
                  ),
                ),
              ],
              if (tracking != null) ...[
                const SizedBox(height: AppSpacing.xl),
                _TrackingResultCard(tracking: tracking),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _lookup() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    await widget.controller.lookupPublicTracking(_codeController.text);
  }
}

class _TrackingResultCard extends StatelessWidget {
  const _TrackingResultCard({
    required this.tracking,
  });

  final PublicTripTracking tracking;

  @override
  Widget build(BuildContext context) {
    final statusLabel = StatusLabels.publicTripStatus(tracking.status);
    final statusColor = _statusColor(tracking.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusLabel,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (tracking.origin != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Origen: ${tracking.origin}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                _TrackingCodeRow(code: tracking.trackingCode),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Progreso de entrega',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        TripTrackingTimeline(tracking: tracking),
        if (tracking.lastTelemetry != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Última telemetría',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (tracking.lastTelemetry?.temperature != null)
                    Text(
                      'Temperatura: ${tracking.lastTelemetry!.temperature} °C',
                    ),
                  if (tracking.lastTelemetry?.humidity != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text('Humedad: ${tracking.lastTelemetry!.humidity}%'),
                  ],
                  if (tracking.lastTelemetry?.recordedAt != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Registrado ${_formatDate(tracking.lastTelemetry!.recordedAt)}',
                      style: const TextStyle(color: AppColors.inkMuted),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '—';
    }

    final local = value.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  Color _statusColor(String status) {
    return switch (status) {
      'COMPLETED' => AppColors.success,
      'IN_PROGRESS' => AppColors.primary,
      'CANCELLED' => AppColors.danger,
      _ => AppColors.ink,
    };
  }
}

class _TrackingCodeRow extends StatelessWidget {
  const _TrackingCodeRow({
    required this.code,
  });

  final String code;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Número de seguimiento',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.inkMuted,
                        ),
                  ),
                  Text(
                    code,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Copiar código',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Código de seguimiento copiado.')),
                );
              },
              icon: const Icon(Icons.copy_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
