import 'package:flutter/material.dart';

import '../../../../core/utils/design_tokens.dart';
import '../../../../core/utils/omnitrack_logo.dart';
import '../../application/controllers/alerts_controller.dart';
import '../../domain/entities/alert.dart';
import '../widgets/alert_status_pill.dart';
import 'alert_details_screen.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({
    required this.controller,
    super.key,
  });

  final AlertsController controller;

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const OmnitrackLogo(
              foregroundColor: AppColors.ink,
              iconSize: 18,
              textSize: 20,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Alerts',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.inkMuted,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: widget.controller.load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final controller = widget.controller;
          final alerts = controller.visibleAlerts;

          return RefreshIndicator(
            onRefresh: controller.load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xl,
              ),
              children: [
                Row(
                  children: [
                    _CountChip(
                      label: '${controller.openCount} ALERT'
                          '${controller.openCount == 1 ? '' : 'S'}',
                      accent: AppColors.danger,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _CountChip(
                      label: '${controller.resolvedCount} resolved',
                      accent: AppColors.success,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _StatusFilterField(
                        value: controller.statusFilter,
                        onChanged: controller.changeFilter,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _searchController,
                  onChanged: controller.search,
                  decoration: const InputDecoration(
                    hintText: 'Search alerts',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (controller.isLoading && alerts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (controller.errorMessage != null && alerts.isEmpty)
                  _AlertsMessage(
                    icon: Icons.cloud_off_rounded,
                    message: controller.errorMessage!,
                  )
                else if (alerts.isEmpty)
                  const _AlertsMessage(
                    icon: Icons.inbox_outlined,
                    message: 'No alerts match the current filters.',
                  )
                else
                  for (final alert in alerts) ...[
                    _AlertTile(
                      alert: alert,
                      isResolving: controller.isResolving(alert.id),
                      onResolve: () => _resolve(alert.id),
                      onOpen: () => _openDetails(alert.id),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _resolve(String id) async {
    final success = await widget.controller.resolve(id);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Alert marked as resolved.'
              : widget.controller.errorMessage ?? 'Unable to resolve the alert.',
        ),
      ),
    );
  }

  void _openDetails(String id) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AlertDetailsScreen(
          controller: widget.controller,
          alertId: id,
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.label,
    required this.accent,
  });

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: accent,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _StatusFilterField extends StatelessWidget {
  const _StatusFilterField({
    required this.value,
    required this.onChanged,
  });

  final AlertStatusFilter value;
  final ValueChanged<AlertStatusFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Status',
        prefixIcon: Icon(Icons.filter_list_rounded),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AlertStatusFilter>(
          value: value,
          isExpanded: true,
          onChanged: (next) {
            if (next != null) {
              onChanged(next);
            }
          },
          items: [
            for (final filter in AlertStatusFilter.values)
              DropdownMenuItem<AlertStatusFilter>(
                value: filter,
                child: Text(filter.label),
              ),
          ],
        ),
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({
    required this.alert,
    required this.isResolving,
    required this.onResolve,
    required this.onOpen,
  });

  final Alert alert;
  final bool isResolving;
  final VoidCallback onResolve;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${alert.typeLabel} alert',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          alert.deliveryOrderId == null
                              ? 'Alert #${alert.id} - no linked order'
                              : 'Alert #${alert.id} - order #${alert.deliveryOrderId}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AlertStatusPill(status: alert.status),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  if (alert.status.isResolved)
                    Row(
                      children: [
                        const Icon(
                          Icons.task_alt_rounded,
                          size: 18,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Resolved',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ],
                    )
                  else
                    TextButton.icon(
                      onPressed: isResolving ? null : onResolve,
                      icon: isResolving
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2.2),
                            )
                          : const Icon(Icons.check_circle_outline_rounded),
                      label: const Text('Mark as resolved'),
                    ),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.inkMuted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertsMessage extends StatelessWidget {
  const _AlertsMessage({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Icon(icon, size: 42, color: AppColors.inkMuted),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
