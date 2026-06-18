import 'package:flutter/material.dart';

import '../../../../core/utils/design_tokens.dart';
import '../../application/controllers/alerts_controller.dart';
import '../widgets/alert_status_pill.dart';

class AlertDetailsScreen extends StatelessWidget {
  const AlertDetailsScreen({
    required this.controller,
    required this.alertId,
    super.key,
  });

  final AlertsController controller;
  final String alertId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alert details'),
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final alert = controller.allAlertById(alertId);
          final isResolving = controller.isResolving(alert.id);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                                color: AppColors.warning.withValues(alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                              ),
                              child: const Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.warning,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                '${alert.typeLabel} alert',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            AlertStatusPill(status: alert.status),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _DetailRow(label: 'Alert ID', value: '#${alert.id}'),
                        const Divider(height: AppSpacing.lg),
                        _DetailRow(label: 'Type', value: alert.typeLabel),
                        const Divider(height: AppSpacing.lg),
                        _DetailRow(
                          label: 'Status',
                          value: alert.status.label,
                        ),
                        const Divider(height: AppSpacing.lg),
                        _DetailRow(
                          label: 'Delivery order',
                          value: alert.deliveryOrderId == null
                              ? 'Not linked'
                              : '#${alert.deliveryOrderId}',
                        ),
                        const Divider(height: AppSpacing.lg),
                        _DetailRow(
                          label: 'Created',
                          value: _formatDate(alert.createdAt),
                        ),
                        const Divider(height: AppSpacing.lg),
                        _DetailRow(
                          label: 'Last update',
                          value: _formatDate(alert.lastActivityAt),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (alert.status.isResolved)
                  const _ResolvedBanner()
                else
                  FilledButton.icon(
                    onPressed: isResolving
                        ? null
                        : () => _resolve(context, alert.id),
                    icon: isResolving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('Mark as resolved'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _resolve(BuildContext context, String id) async {
    final success = await controller.resolve(id);
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Alert marked as resolved.'
              : controller.errorMessage ?? 'Unable to resolve the alert.',
        ),
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return 'Unknown';
    }

    final local = value.toLocal();
    final hours = local.hour.toString().padLeft(2, '0');
    final minutes = local.minute.toString().padLeft(2, '0');
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} $hours:$minutes';
  }
}

class _ResolvedBanner extends StatelessWidget {
  const _ResolvedBanner();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.success.withValues(alpha: 0.10),
      child: const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(Icons.task_alt_rounded, color: AppColors.success),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'This alert is already resolved in the backend.',
                style: TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.inkMuted,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}
