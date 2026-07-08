import 'package:flutter/material.dart';

import '../../../../core/utils/design_tokens.dart';
import '../../../../core/utils/omnitrack_logo.dart';
import '../../application/controllers/billing_controller.dart';
import '../../domain/entities/subscription.dart';
import 'link_payment_method_screen.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({
    required this.controller,
    super.key,
  });

  final BillingController controller;

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.load();
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
              'Administra tu plan y pagos',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.inkMuted,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: widget.controller.load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final controller = widget.controller;
          final subscription = controller.subscription;

          if (subscription == null) {
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return _BillingError(
              message: controller.errorMessage ??
                  'Aún no hay datos de suscripción disponibles.',
              onRetry: controller.load,
            );
          }

          return RefreshIndicator(
            onRefresh: controller.load,
            child: Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.xl,
                  ),
                  children: [
                    _SubscriptionCard(subscription: subscription),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _openLinkPayment,
                            child: Text(
                              subscription.hasPaymentMethod
                                  ? 'Cambiar tarjeta'
                                  : 'Agregar tarjeta',
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: subscription.isCanceled
                                ? null
                                : _confirmCancel,
                            child: const Text('Cancelar tu plan'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FilledButton(
                      onPressed: _openPlanPicker,
                      child: const Text('Mejorar tu plan'),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'HISTORIAL DE PAGOS',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _PaymentHistory(payments: controller.payments),
                  ],
                ),
                if (controller.isMutating)
                  const Align(
                    alignment: Alignment.topCenter,
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openLinkPayment() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LinkPaymentMethodScreen(controller: widget.controller),
      ),
    );
  }

  Future<void> _confirmCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar suscripción'),
        content: const Text(
          'Tu plan se marcará como cancelado. Podrás volver a suscribirte más adelante.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Mantener plan'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancelar plan'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    final ok = await widget.controller.cancelSubscription();
    _notify(ok ? 'Suscripción cancelada.' : null);
  }

  Future<void> _openPlanPicker() async {
    final controller = widget.controller;
    final current = controller.subscription;

    final selectedPlanId = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(
                'Elige un plan',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final plan in controller.plans)
                Card(
                  child: ListTile(
                    selected: current?.plan.id == plan.id,
                    title: Text('${plan.name} - ${plan.priceLabel}'),
                    subtitle: Text('${plan.limits}\n${plan.description}'),
                    isThreeLine: true,
                    trailing: current?.plan.id == plan.id
                        ? const Icon(Icons.check_circle_rounded,
                            color: AppColors.success)
                        : const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(sheetContext).pop(plan.id),
                  ),
                ),
            ],
          ),
        );
      },
    );

    if (selectedPlanId == null || selectedPlanId == current?.plan.id) {
      return;
    }

    final ok = await controller.changePlan(selectedPlanId);
    _notify(ok ? 'Plan actualizado.' : null);
  }

  void _notify(String? successMessage) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          successMessage ??
              widget.controller.errorMessage ??
              'La operación falló.',
        ),
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({required this.subscription});

  final Subscription subscription;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Suscripción',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _KeyValueRow(label: 'Plan actual', value: subscription.plan.name),
            const SizedBox(height: AppSpacing.sm),
            _KeyValueRow(label: 'Monto', value: subscription.plan.priceLabel),
            const SizedBox(height: AppSpacing.sm),
            _KeyValueRow(label: 'Límites', value: subscription.plan.limits),
            const SizedBox(height: AppSpacing.sm),
            _KeyValueRow(
              label: 'Estado',
              value: subscription.status,
              valueColor: subscription.isCanceled
                  ? AppColors.danger
                  : AppColors.success,
            ),
            const SizedBox(height: AppSpacing.sm),
            _KeyValueRow(label: 'Renovación', value: subscription.renewal),
            const SizedBox(height: AppSpacing.sm),
            _KeyValueRow(
              label: 'Método de pago',
              value: subscription.hasPaymentMethod
                  ? subscription.paymentMethod
                  : '--------',
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.inkMuted,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: valueColor ?? AppColors.ink,
                ),
          ),
        ),
      ],
    );
  }
}

class _PaymentHistory extends StatelessWidget {
  const _PaymentHistory({required this.payments});

  final List<Payment> payments;

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            'Aún no hay pagos registrados.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Row(
              children: [
                _HeaderCell('FECHA', flex: 3),
                _HeaderCell('MONTO', flex: 2),
                _HeaderCell('ESTADO', flex: 2),
                _HeaderCell('ID TXN', flex: 3),
              ],
            ),
          ),
          const Divider(height: 1),
          for (final payment in payments)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  _BodyCell(payment.paymentDate, flex: 3),
                  _BodyCell(payment.amountLabel, flex: 2),
                  _BodyCell(payment.status, flex: 2, color: AppColors.success),
                  _BodyCell(payment.transactionId, flex: 3),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label, {required this.flex});

  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.inkMuted,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  const _BodyCell(this.value, {required this.flex, this.color});

  final String value;
  final int flex;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        value,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color ?? AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _BillingError extends StatelessWidget {
  const _BillingError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 42,
              color: AppColors.warning,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
