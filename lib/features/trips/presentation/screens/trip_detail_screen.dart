import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/trip_pdf_service.dart';
import '../../../../core/utils/design_tokens.dart';
import '../../../../core/utils/status_labels.dart';
import '../../../home/domain/entities/home_dashboard.dart';
import '../../application/controllers/trips_controller.dart';

class TripDetailScreen extends StatefulWidget {
  const TripDetailScreen({
    required this.controller,
    required this.tripId,
    super.key,
  });

  final TripsController controller;
  final String tripId;

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _sequenceController = TextEditingController(text: '1');
  final _pdfService = TripPdfService();

  @override
  void initState() {
    super.initState();
    widget.controller.loadTripDetail(widget.tripId);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _addressController.dispose();
    _sequenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del viaje'),
        actions: [
          IconButton(
            tooltip: 'Exportar PDF',
            onPressed: _exportPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final controller = widget.controller;

          if (controller.isLoadingDetail && controller.selectedTrip == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final trip = controller.selectedTrip;
          if (trip == null) {
            return Center(
              child: Text(
                controller.errorMessage ?? 'Viaje no encontrado.',
                style: const TextStyle(color: AppColors.inkMuted),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Viaje #${trip.id}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _DetailRow(label: 'Estado', value: StatusLabels.tripStatus(trip.status)),
                      const Divider(height: AppSpacing.lg),
                      _DetailRow(
                        label: 'Origen',
                        value: trip.originPointName ?? 'No definido',
                      ),
                      const Divider(height: AppSpacing.lg),
                      _DetailRow(
                        label: 'Dirección',
                        value: trip.originPointAddress ?? '—',
                      ),
                      const Divider(height: AppSpacing.lg),
                      _DetailRow(
                        label: 'Creado',
                        value: _formatDate(trip.createdAt),
                      ),
                      const Divider(height: AppSpacing.lg),
                      _DetailRow(
                        label: 'Iniciado',
                        value: _formatDate(trip.startedAt),
                      ),
                      const Divider(height: AppSpacing.lg),
                      _DetailRow(
                        label: 'Completado',
                        value: _formatDate(trip.completedAt),
                      ),
                      if (trip.trackingCode != null) ...[
                        const Divider(height: AppSpacing.lg),
                        _DetailRow(
                          label: 'Seguimiento',
                          value: trip.trackingCode!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (trip.trackingCode != null) ...[
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: trip.trackingCode!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Código de seguimiento copiado.')),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Copiar código de seguimiento'),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed(
                    AppRoutes.publicTracking,
                    arguments: trip.trackingCode,
                  ),
                  icon: const Icon(Icons.local_shipping_outlined),
                  label: const Text('Vista previa del seguimiento público'),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              if (trip.status == 'PLANNED' || trip.status == 'IN_PROGRESS') ...[
                OutlinedButton.icon(
                  onPressed: controller.isSubmitting
                      ? null
                      : () => Navigator.of(context).pushNamed(
                            AppRoutes.tripReschedule,
                            arguments: trip.id,
                          ),
                  icon: const Icon(Icons.event_repeat_rounded),
                  label: const Text('Reprogramar viaje'),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              if (trip.status == 'PLANNED')
                FilledButton.icon(
                  onPressed: controller.isSubmitting
                      ? null
                      : () => _startTrip(context, trip.id),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Iniciar viaje'),
                ),
              if (trip.status == 'IN_PROGRESS') ...[
                FilledButton.icon(
                  onPressed: controller.isSubmitting
                      ? null
                      : () => _completeTrip(context, trip.id),
                  icon: const Icon(Icons.flag_rounded),
                  label: const Text('Completar viaje'),
                ),
              ],
              if (trip.status == 'PLANNED' || trip.status == 'CANCELLED') ...[
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: controller.isSubmitting
                      ? null
                      : () => _deleteTrip(context, trip.id),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Eliminar viaje'),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Órdenes de entrega',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              ...controller.deliveryOrders.map(_buildOrderTile),
              if (controller.deliveryOrders.isEmpty)
                const Text(
                  'Aún no hay órdenes de entrega.',
                  style: TextStyle(color: AppColors.inkMuted),
                ),
              const SizedBox(height: AppSpacing.lg),
              if (trip.status == 'IN_PROGRESS' || trip.status == 'PLANNED')
                _AddDeliveryForm(
                  emailController: _emailController,
                  addressController: _addressController,
                  sequenceController: _sequenceController,
                  isSubmitting: controller.isSubmitting,
                  onSubmit: () => _addDelivery(context, trip.id),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrderTile(HomeDeliveryOrder order) {
    return Card(
      child: ListTile(
        title: Text(order.clientEmail),
        subtitle: Text(
          '#${order.sequenceOrder} · ${StatusLabels.deliveryStatus(order.status)}'
          '${order.address != null ? ' · ${order.address}' : ''}',
        ),
        trailing: order.status == 'DELIVERED'
            ? const Icon(Icons.check_circle, color: AppColors.success)
            : TextButton(
                onPressed: widget.controller.isSubmitting
                    ? null
                    : () => _markDelivered(context, order.id),
                child: const Text('Entregar'),
              ),
      ),
    );
  }

  Future<void> _exportPdf() async {
    final trip = widget.controller.selectedTrip;
    if (trip == null) {
      return;
    }

    try {
      await _pdfService.shareTripPdf(
        trip: trip,
        deliveryOrders: widget.controller.deliveryOrders,
      );
    } on Exception catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo exportar el PDF: $error')),
      );
    }
  }

  Future<void> _startTrip(BuildContext context, String tripId) async {
    final success = await widget.controller.startTrip(tripId);
    if (!context.mounted) {
      return;
    }
    _showResult(context, success, 'Viaje iniciado.', 'No se pudo iniciar el viaje.');
  }

  Future<void> _completeTrip(BuildContext context, String tripId) async {
    final success = await widget.controller.completeTrip(tripId);
    if (!context.mounted) {
      return;
    }
    _showResult(context, success, 'Viaje completado.', 'No se pudo completar el viaje.');
  }

  Future<void> _deleteTrip(BuildContext context, String tripId) async {
    final success = await widget.controller.deleteTrip(tripId);
    if (!context.mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).pop();
      return;
    }

    _showResult(context, false, '', 'No se pudo eliminar el viaje.');
  }

  Future<void> _addDelivery(BuildContext context, String tripId) async {
    final sequence = int.tryParse(_sequenceController.text.trim()) ?? 1;
    final success = await widget.controller.createDeliveryOrder(
      tripId: tripId,
      clientEmail: _emailController.text.trim(),
      sequenceOrder: sequence,
      address: _addressController.text.trim(),
    );

    if (success) {
      _emailController.clear();
      _addressController.clear();
    }

    if (!context.mounted) {
      return;
    }

    _showResult(
      context,
      success,
      'Orden de entrega creada.',
      'No se pudo crear la orden de entrega.',
    );
  }

  Future<void> _markDelivered(BuildContext context, String orderId) async {
    final success = await widget.controller.markDelivery(orderId);
    if (!context.mounted) {
      return;
    }
    _showResult(
      context,
      success,
      'Entrega marcada como completada.',
      'No se pudo marcar la entrega.',
    );
  }

  void _showResult(
    BuildContext context,
    bool success,
    String okMessage,
    String errorMessage,
  ) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? okMessage
              : widget.controller.errorMessage ?? errorMessage,
        ),
      ),
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
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.inkMuted,
                ),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }
}

class _AddDeliveryForm extends StatelessWidget {
  const _AddDeliveryForm({
    required this.emailController,
    required this.addressController,
    required this.sequenceController,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final TextEditingController emailController;
  final TextEditingController addressController;
  final TextEditingController sequenceController;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Agregar orden de entrega',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Correo del cliente',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Dirección',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: sequenceController,
              decoration: const InputDecoration(
                labelText: 'Secuencia',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: isSubmitting ? null : onSubmit,
              child: const Text('Agregar orden'),
            ),
          ],
        ),
      ),
    );
  }
}
