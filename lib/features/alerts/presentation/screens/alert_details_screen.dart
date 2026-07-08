import 'package:flutter/material.dart';

import '../../../../core/utils/design_tokens.dart';
import '../../../../core/utils/status_labels.dart';
import '../../application/controllers/alerts_controller.dart';
import '../../domain/entities/alert.dart';
import '../../domain/entities/incident.dart';
import '../../domain/entities/notification.dart';
import '../widgets/alert_status_pill.dart';

class AlertDetailsScreen extends StatefulWidget {
  const AlertDetailsScreen({
    required this.controller,
    required this.alertId,
    super.key,
  });

  final AlertsController controller;
  final String alertId;

  @override
  State<AlertDetailsScreen> createState() => _AlertDetailsScreenState();
}

class _AlertDetailsScreenState extends State<AlertDetailsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.loadAlertDetail(widget.alertId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de alerta'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Detalles'),
            Tab(text: 'Incidentes'),
            Tab(text: 'Notificaciones'),
          ],
        ),
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          if (widget.controller.isLoadingDetail &&
              !widget.controller.hasLoadedDetail(widget.alertId)) {
            return const Center(child: CircularProgressIndicator());
          }

          final alert = widget.controller.alertById(widget.alertId);

          return TabBarView(
            controller: _tabController,
            children: [
              _DetailsTab(
                controller: widget.controller,
                alert: alert,
              ),
              _IncidentsTab(
                incidents: widget.controller.incidents,
              ),
              _NotificationsTab(
                notifications: widget.controller.notifications,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DetailsTab extends StatelessWidget {
  const _DetailsTab({
    required this.controller,
    required this.alert,
  });

  final AlertsController controller;
  final Alert alert;

  @override
  Widget build(BuildContext context) {
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
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.warning,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Alerta de ${alert.typeLabel}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      AlertStatusPill(status: alert.status),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _DetailRow(label: 'ID de alerta', value: '#${alert.id}'),
                  const Divider(height: AppSpacing.lg),
                  _DetailRow(label: 'Tipo', value: alert.typeLabel),
                  const Divider(height: AppSpacing.lg),
                  _DetailRow(label: 'Estado', value: alert.status.label),
                  const Divider(height: AppSpacing.lg),
                  _DetailRow(
                    label: 'Pedido de entrega',
                    value: alert.deliveryOrderId == null
                        ? 'Sin vincular'
                        : '#${alert.deliveryOrderId}',
                  ),
                  const Divider(height: AppSpacing.lg),
                  _DetailRow(
                    label: 'Creada',
                    value: _formatDate(alert.createdAt),
                  ),
                  const Divider(height: AppSpacing.lg),
                  _DetailRow(
                    label: 'Última actualización',
                    value: _formatDate(alert.lastActivityAt),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (alert.status.isResolved)
            const _ResolvedBanner()
          else ...[
            if (alert.status == AlertStatus.open)
              OutlinedButton.icon(
                onPressed: isResolving
                    ? null
                    : () => _acknowledge(context, alert.id),
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Reconocer'),
              ),
            if (alert.status == AlertStatus.open)
              const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(
              onPressed:
                  isResolving ? null : () => _resolve(context, alert.id),
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
              label: const Text('Marcar como resuelta'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _acknowledge(BuildContext context, String id) async {
    final success = await controller.acknowledge(id);
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Alerta reconocida en el backend.'
              : controller.errorMessage ?? 'No se pudo reconocer la alerta.',
        ),
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
              ? 'Alerta marcada como resuelta.'
              : controller.errorMessage ?? 'No se pudo resolver la alerta.',
        ),
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return 'Desconocido';
    }

    final local = value.toLocal();
    final hours = local.hour.toString().padLeft(2, '0');
    final minutes = local.minute.toString().padLeft(2, '0');
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} $hours:$minutes';
  }
}

class _IncidentsTab extends StatelessWidget {
  const _IncidentsTab({required this.incidents});

  final List<Incident> incidents;

  @override
  Widget build(BuildContext context) {
    if (incidents.isEmpty) {
      return const Center(
        child: Text(
          'No hay incidentes vinculados a esta alerta.',
          style: TextStyle(color: AppColors.inkMuted),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: incidents.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final incident = incidents[index];
        return Card(
          child: ListTile(
            title: Text(StatusLabels.alertType(incident.type)),
            subtitle: Text(
              [
                StatusLabels.alertStatus(incident.status),
                if (incident.description != null) incident.description!,
              ].join(' · '),
            ),
          ),
        );
      },
    );
  }
}

class _NotificationsTab extends StatelessWidget {
  const _NotificationsTab({required this.notifications});

  final List<AlertNotification> notifications;

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return const Center(
        child: Text(
          'No hay notificaciones vinculadas a esta alerta.',
          style: TextStyle(color: AppColors.inkMuted),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return Card(
          child: ListTile(
            title: Text(
              '${notification.channel} · ${StatusLabels.deliveryStatus(notification.status)}',
            ),
            subtitle: Text(
              [
                if (notification.recipient != null) notification.recipient!,
                if (notification.message != null) notification.message!,
              ].join('\n'),
            ),
          ),
        );
      },
    );
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
                'Esta alerta ya está resuelta en el backend.',
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
          width: 132,
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
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}
