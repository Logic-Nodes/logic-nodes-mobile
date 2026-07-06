import 'package:flutter/material.dart';

import '../../../../core/services/trip_pdf_service.dart';
import '../../../../core/utils/design_tokens.dart';
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
        title: const Text('Trip details'),
        actions: [
          IconButton(
            tooltip: 'Export PDF',
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
                controller.errorMessage ?? 'Trip not found.',
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
                        'Trip #${trip.id}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _DetailRow(label: 'Status', value: trip.status),
                      const Divider(height: AppSpacing.lg),
                      _DetailRow(
                        label: 'Origin',
                        value: trip.originPointName ?? 'Not set',
                      ),
                      const Divider(height: AppSpacing.lg),
                      _DetailRow(
                        label: 'Address',
                        value: trip.originPointAddress ?? '—',
                      ),
                      const Divider(height: AppSpacing.lg),
                      _DetailRow(
                        label: 'Created',
                        value: _formatDate(trip.createdAt),
                      ),
                      const Divider(height: AppSpacing.lg),
                      _DetailRow(
                        label: 'Started',
                        value: _formatDate(trip.startedAt),
                      ),
                      const Divider(height: AppSpacing.lg),
                      _DetailRow(
                        label: 'Completed',
                        value: _formatDate(trip.completedAt),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (trip.status == 'PLANNED')
                FilledButton.icon(
                  onPressed: controller.isSubmitting
                      ? null
                      : () => _startTrip(context, trip.id),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start trip'),
                ),
              if (trip.status == 'IN_PROGRESS') ...[
                FilledButton.icon(
                  onPressed: controller.isSubmitting
                      ? null
                      : () => _completeTrip(context, trip.id),
                  icon: const Icon(Icons.flag_rounded),
                  label: const Text('Complete trip'),
                ),
              ],
              if (trip.status == 'PLANNED' || trip.status == 'CANCELLED') ...[
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: controller.isSubmitting
                      ? null
                      : () => _deleteTrip(context, trip.id),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Delete trip'),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Delivery orders',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              ...controller.deliveryOrders.map(_buildOrderTile),
              if (controller.deliveryOrders.isEmpty)
                const Text(
                  'No delivery orders yet.',
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
          '#${order.sequenceOrder} · ${order.status}'
          '${order.address != null ? ' · ${order.address}' : ''}',
        ),
        trailing: order.status == 'DELIVERED'
            ? const Icon(Icons.check_circle, color: AppColors.success)
            : TextButton(
                onPressed: widget.controller.isSubmitting
                    ? null
                    : () => _markDelivered(context, order.id),
                child: const Text('Deliver'),
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
        SnackBar(content: Text('Unable to export PDF: $error')),
      );
    }
  }

  Future<void> _startTrip(BuildContext context, String tripId) async {
    final success = await widget.controller.startTrip(tripId);
    if (!context.mounted) {
      return;
    }
    _showResult(context, success, 'Trip started.', 'Unable to start trip.');
  }

  Future<void> _completeTrip(BuildContext context, String tripId) async {
    final success = await widget.controller.completeTrip(tripId);
    if (!context.mounted) {
      return;
    }
    _showResult(context, success, 'Trip completed.', 'Unable to complete trip.');
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

    _showResult(context, false, '', 'Unable to delete trip.');
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
      'Delivery order created.',
      'Unable to create delivery order.',
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
      'Delivery marked as completed.',
      'Unable to mark delivery.',
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
              'Add delivery order',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Client email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: sequenceController,
              decoration: const InputDecoration(
                labelText: 'Sequence',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: isSubmitting ? null : onSubmit,
              child: const Text('Add order'),
            ),
          ],
        ),
      ),
    );
  }
}
